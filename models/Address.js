const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Address = sequelize.define('Address', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  addressText: {
    type: DataTypes.TEXT,
    allowNull: false,
    field: 'address_text',
  },
  formattedAddress: {
    type: DataTypes.TEXT,
    allowNull: false,
    field: 'formatted_address',
  },
  latitude: {
    type: DataTypes.DECIMAL(10, 8),
    allowNull: false,
  },
  longitude: {
    type: DataTypes.DECIMAL(11, 8),
    allowNull: false,
  },
  city: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },
  district: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },
  street: {
    type: DataTypes.STRING(200),
    allowNull: true,
  },
  buildingNumber: {
    type: DataTypes.STRING(20),
    allowNull: true,
    field: 'building_number',
  },
  postalCode: {
    type: DataTypes.STRING(20),
    allowNull: true,
    field: 'postal_code',
  },
  country: {
    type: DataTypes.STRING(100),
    allowNull: true,
    defaultValue: 'Azerbaijan',
  },
  searchKeywords: {
    type: DataTypes.ARRAY(DataTypes.TEXT),
    allowNull: true,
    field: 'search_keywords',
  },
  popularityScore: {
    type: DataTypes.INTEGER,
    allowNull: true,
    defaultValue: 0,
    field: 'popularity_score',
  },
  createdAt: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
    field: 'created_at',
  },
  updatedAt: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
    field: 'updated_at',
  },
}, {
  tableName: 'addresses',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

// Static methods for address operations
Address.searchAddresses = async function(query, limit = 10) {
  try {
    const searchQuery = query.toLowerCase().trim();
    
    if (!searchQuery) {
      return [];
    }

    // Split query into individual words for better matching
    const queryWords = searchQuery.split(/\s+/).filter(word => word.length > 0);
    
    // Build the search conditions
    const searchConditions = [];
    const replacements = { limit };
    
    // Full text search on address_text and formatted_address
    searchConditions.push(`
      (to_tsvector('english', address_text) @@ plainto_tsquery('english', :searchQuery) OR
       to_tsvector('english', formatted_address) @@ plainto_tsquery('english', :searchQuery))
    `);
    replacements.searchQuery = searchQuery;
    
    // Keyword array search
    if (queryWords.length > 0) {
      searchConditions.push(`search_keywords && ARRAY[:queryWords]`);
      replacements.queryWords = queryWords;
    }
    
    // Individual word matching for better results
    queryWords.forEach((word, index) => {
      if (word.length > 2) { // Only search words longer than 2 characters
        searchConditions.push(`
          (LOWER(address_text) LIKE :word${index} OR 
           LOWER(formatted_address) LIKE :word${index} OR
           LOWER(city) LIKE :word${index} OR
           LOWER(district) LIKE :word${index} OR
           LOWER(street) LIKE :word${index})
        `);
        replacements[`word${index}`] = `%${word}%`;
      }
    });
    
    const whereClause = searchConditions.join(' OR ');
    
    const query = `
      SELECT 
        id,
        address_text,
        formatted_address,
        latitude,
        longitude,
        city,
        district,
        street,
        building_number,
        popularity_score,
        -- Calculate relevance score
        (
          CASE WHEN to_tsvector('english', address_text) @@ plainto_tsquery('english', :searchQuery) THEN 10 ELSE 0 END +
          CASE WHEN to_tsvector('english', formatted_address) @@ plainto_tsquery('english', :searchQuery) THEN 8 ELSE 0 END +
          CASE WHEN search_keywords && ARRAY[:queryWords] THEN 6 ELSE 0 END +
          CASE WHEN LOWER(address_text) LIKE :exactMatch THEN 5 ELSE 0 END +
          CASE WHEN LOWER(formatted_address) LIKE :exactMatch THEN 4 ELSE 0 END +
          popularity_score / 10
        ) as relevance_score
      FROM addresses 
      WHERE ${whereClause}
      ORDER BY relevance_score DESC, popularity_score DESC
      LIMIT :limit;
    `;
    
    replacements.exactMatch = `%${searchQuery}%`;
    
    const [results] = await sequelize.query(query, {
      replacements,
      type: sequelize.QueryTypes.SELECT,
    });
    
    return results;
  } catch (error) {
    console.error('Error searching addresses:', error);
    throw error;
  }
};

Address.addAddress = async function(addressData) {
  try {
    const {
      addressText,
      formattedAddress,
      latitude,
      longitude,
      city,
      district,
      street,
      buildingNumber,
      postalCode,
      country = 'Azerbaijan'
    } = addressData;
    
    // Generate search keywords
    const searchKeywords = Address.generateSearchKeywords(addressText, {
      city,
      district,
      street,
      buildingNumber
    });
    
    const address = await Address.create({
      addressText,
      formattedAddress,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      city,
      district,
      street,
      buildingNumber,
      postalCode,
      country,
      searchKeywords,
    });
    
    return address;
  } catch (error) {
    console.error('Error adding address:', error);
    throw error;
  }
};

Address.generateSearchKeywords = function(addressText, additionalData = {}) {
  const keywords = new Set();
  
  // Add words from address text
  const words = addressText.toLowerCase()
    .replace(/[^\w\s]/g, ' ') // Remove special characters
    .split(/\s+/)
    .filter(word => word.length > 1); // Filter out single characters
  
  words.forEach(word => keywords.add(word));
  
  // Add additional data as keywords
  Object.values(additionalData).forEach(value => {
    if (value && typeof value === 'string') {
      const additionalWords = value.toLowerCase()
        .replace(/[^\w\s]/g, ' ')
        .split(/\s+/)
        .filter(word => word.length > 1);
      
      additionalWords.forEach(word => keywords.add(word));
    }
  });
  
  return Array.from(keywords);
};

Address.incrementPopularity = async function(addressId) {
  try {
    await Address.increment('popularityScore', {
      where: { id: addressId },
      by: 1,
    });
  } catch (error) {
    console.error('Error incrementing address popularity:', error);
    throw error;
  }
};

module.exports = Address;
