const express = require('express');
const { body, validationResult } = require('express-validator');
const AddressSearchService = require('../services/AddressSearchService');
const Address = require('../models/Address');

const router = express.Router();
const addressSearchService = new AddressSearchService();

/**
 * @route GET /api/addresses/search
 * @desc Search addresses with local database and Google Maps fallback
 * @access Public
 */
router.get('/search', async (req, res) => {
  try {
    const { query, limit = 10 } = req.query;
    
    if (!query || query.trim().length === 0) {
      return res.status(400).json({ 
        success: false,
        error: 'Search query is required'
      });
    }
    
    console.log(`🔍 Address search request: "${query}", limit: ${limit}`);
    
    const results = await addressSearchService.searchAddresses(query, parseInt(limit));
    
    res.json({
      success: true,
      data: {
        query,
        results,
        total: results.length,
        sources: {
          local: results.filter(r => r.source === 'local').length,
          google: results.filter(r => r.source === 'google').length,
        }
      }
    });
    
  } catch (error) {
    console.error('Address search error:', error);
    res.status(500).json({
      success: false,
      error: 'Address search failed',
      message: error.message
    });
  }
});

/**
 * @route GET /api/addresses/reverse-geocode
 * @desc Get address by coordinates (reverse geocoding)
 * @access Public
 */
router.get('/reverse-geocode', async (req, res) => {
  try {
    const { latitude, longitude } = req.query;
    
    if (!latitude || !longitude) {
      return res.status(400).json({ 
        success: false,
        error: 'Latitude and longitude are required'
      });
    }
    
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    
    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({ 
        success: false,
        error: 'Valid latitude and longitude are required'
      });
    }
    
    console.log(`📍 Reverse geocoding request: ${lat}, ${lng}`);
    
    const result = await addressSearchService.getAddressByCoordinates(
      parseFloat(latitude), 
      parseFloat(longitude)
    );
    
    if (!result) {
      return res.status(404).json({
        success: false,
        error: 'Address not found for the given coordinates'
      });
    }
    
    res.json({
      success: true,
      data: result
    });
    
  } catch (error) {
    console.error('Reverse geocoding error:', error);
    res.status(500).json({
      success: false,
      error: 'Reverse geocoding failed',
      message: error.message
    });
  }
});

/**
 * @route POST /api/addresses/add
 * @desc Add a new address to the local database
 * @access Public (could be restricted to admin)
 */
router.post('/add', [
  body('addressText').notEmpty().withMessage('Address text is required'),
  body('formattedAddress').notEmpty().withMessage('Formatted address is required'),
  body('latitude').isFloat().withMessage('Valid latitude is required'),
  body('longitude').isFloat().withMessage('Valid longitude is required'),
  body('city').optional().isString(),
  body('district').optional().isString(),
  body('street').optional().isString(),
  body('buildingNumber').optional().isString(),
  body('postalCode').optional().isString(),
  body('country').optional().isString(),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        success: false,
        errors: errors.array() 
      });
    }

    const addressData = req.body;
    
    console.log(`➕ Adding new address: "${addressData.addressText}"`);
    
    const address = await Address.addAddress(addressData);
    
    res.status(201).json({
      success: true,
      data: {
        id: address.id,
        addressText: address.addressText,
        formattedAddress: address.formattedAddress,
        latitude: parseFloat(address.latitude),
        longitude: parseFloat(address.longitude),
        city: address.city,
        district: address.district,
        street: address.street,
        buildingNumber: address.buildingNumber,
        postalCode: address.postalCode,
        country: address.country,
        searchKeywords: address.searchKeywords,
        popularityScore: address.popularityScore,
        createdAt: address.createdAt,
      }
    });
    
  } catch (error) {
    console.error('Add address error:', error);
    
    if (error.message.includes('duplicate')) {
      return res.status(409).json({
        success: false,
        error: 'Address already exists',
        message: 'An address with these coordinates already exists'
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Failed to add address',
      message: error.message
    });
  }
});

/**
 * @route GET /api/addresses/popular
 * @desc Get popular addresses
 * @access Public
 */
router.get('/popular', async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    
    console.log(`⭐ Getting popular addresses, limit: ${limit}`);
    
    const addresses = await Address.findAll({
      order: [['popularityScore', 'DESC']],
      limit: parseInt(limit),
      attributes: [
        'id',
        'addressText',
        'formattedAddress',
        'latitude',
        'longitude',
        'city',
        'district',
        'street',
        'buildingNumber',
        'popularityScore',
        'createdAt',
      ],
    });
    
    const results = addresses.map(address => ({
      id: address.id,
      address: address.formattedAddress,
      addressText: address.addressText,
      latitude: parseFloat(address.latitude),
      longitude: parseFloat(address.longitude),
      city: address.city,
      district: address.district,
      street: address.street,
      buildingNumber: address.buildingNumber,
      popularityScore: address.popularityScore,
      createdAt: address.createdAt,
    }));
    
    res.json({
      success: true,
      data: {
        results,
        total: results.length,
      }
    });
    
  } catch (error) {
    console.error('Popular addresses error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get popular addresses',
      message: error.message
    });
  }
});

/**
 * @route GET /api/addresses/stats
 * @desc Get address database statistics
 * @access Public
 */
router.get('/stats', async (req, res) => {
  try {
    console.log('📊 Getting address database statistics');
    
    const [totalCount] = await Address.sequelize.query(
      'SELECT COUNT(*) as count FROM addresses'
    );
    
    const [cityStats] = await Address.sequelize.query(`
      SELECT city, COUNT(*) as count 
      FROM addresses 
      WHERE city IS NOT NULL 
      GROUP BY city 
      ORDER BY count DESC 
      LIMIT 10
    `);
    
    const [districtStats] = await Address.sequelize.query(`
      SELECT district, COUNT(*) as count 
      FROM addresses 
      WHERE district IS NOT NULL 
      GROUP BY district 
      ORDER BY count DESC 
      LIMIT 10
    `);
    
    const [popularityStats] = await Address.sequelize.query(`
      SELECT 
        AVG(popularity_score) as avg_popularity,
        MAX(popularity_score) as max_popularity,
        MIN(popularity_score) as min_popularity
      FROM addresses
    `);
    
    res.json({
      success: true,
      data: {
        totalAddresses: parseInt(totalCount[0].count),
        cityDistribution: cityStats,
        districtDistribution: districtStats,
        popularityStats: {
          average: parseFloat(popularityStats[0].avg_popularity || 0),
          maximum: parseInt(popularityStats[0].max_popularity || 0),
          minimum: parseInt(popularityStats[0].min_popularity || 0),
        },
      }
    });
    
  } catch (error) {
    console.error('Address stats error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get address statistics',
      message: error.message
    });
  }
});

module.exports = router;
