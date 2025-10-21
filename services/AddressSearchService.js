const Address = require('../models/Address');
const axios = require('axios');

class AddressSearchService {
  constructor() {
    this.googleMapsApiKey = process.env.GOOGLE_MAPS_API_KEY;
    this.googleMapsBaseUrl = 'https://maps.googleapis.com/maps/api/place';
  }

  /**
   * Search for addresses with local database first, then Google Maps fallback
   * @param {string} query - Search query
   * @param {number} limit - Maximum number of results
   * @returns {Promise<Array>} Array of address results
   */
  async searchAddresses(query, limit = 10) {
    try {
      console.log(`🔍 Searching addresses for: "${query}"`);
      
      // First, search local database
      const localResults = await this.searchLocalAddresses(query, limit);
      
      // If we have enough results, return them
      if (localResults.length >= limit) {
        console.log(`✅ Found ${localResults.length} local results`);
        return localResults;
      }
      
      // If we need more results, search Google Maps
      const remainingLimit = limit - localResults.length;
      const googleResults = await this.searchGoogleMaps(query, remainingLimit);
      
      // Combine results, avoiding duplicates
      const combinedResults = this.combineSearchResults(localResults, googleResults);
      
      console.log(`✅ Found ${localResults.length} local + ${googleResults.length} Google results = ${combinedResults.length} total`);
      
      return combinedResults.slice(0, limit);
      
    } catch (error) {
      console.error('Error in address search:', error);
      
      // Fallback to local search only if Google Maps fails
      try {
        const localResults = await this.searchLocalAddresses(query, limit);
        console.log(`⚠️ Fallback to local search: ${localResults.length} results`);
        return localResults;
      } catch (localError) {
        console.error('Local search also failed:', localError);
        throw new Error('Address search failed');
      }
    }
  }

  /**
   * Search addresses in local database
   * @param {string} query - Search query
   * @param {number} limit - Maximum number of results
   * @returns {Promise<Array>} Array of local address results
   */
  async searchLocalAddresses(query, limit = 10) {
    try {
      const results = await Address.searchAddresses(query, limit);
      
      // Increment popularity for found addresses
      results.forEach(result => {
        Address.incrementPopularity(result.id).catch(err => 
          console.error('Error incrementing popularity:', err)
        );
      });
      
      return results.map(result => ({
        id: result.id,
        address: result.formatted_address,
        addressText: result.address_text,
        latitude: parseFloat(result.latitude),
        longitude: parseFloat(result.longitude),
        city: result.city,
        district: result.district,
        street: result.street,
        buildingNumber: result.building_number,
        source: 'local',
        relevanceScore: result.relevance_score,
        popularityScore: result.popularity_score,
      }));
    } catch (error) {
      console.error('Error in local address search:', error);
      throw error;
    }
  }

  /**
   * Search addresses using Google Maps API
   * @param {string} query - Search query
   * @param {number} limit - Maximum number of results
   * @returns {Promise<Array>} Array of Google Maps address results
   */
  async searchGoogleMaps(query, limit = 5) {
    try {
      if (!this.googleMapsApiKey) {
        console.log('⚠️ Google Maps API key not configured');
        return [];
      }

      console.log(`🌍 Searching Google Maps for: "${query}"`);
      
      const response = await axios.get(`${this.googleMapsBaseUrl}/textsearch/json`, {
        params: {
          query: `${query}, Azerbaijan`, // Add Azerbaijan for better results
          key: this.googleMapsApiKey,
          language: 'en',
          region: 'az', // Azerbaijan region bias
        },
        timeout: 5000, // 5 second timeout
      });

      if (response.data.status !== 'OK') {
        console.log(`⚠️ Google Maps API error: ${response.data.status}`);
        return [];
      }

      const results = response.data.results.slice(0, limit);
      
      // Process and save Google Maps results to local database
      const processedResults = await Promise.all(
        results.map(async (place) => {
          try {
            // Save to local database for future searches
            const addressData = {
              addressText: place.name,
              formattedAddress: place.formatted_address,
              latitude: place.geometry.location.lat,
              longitude: place.geometry.location.lng,
              city: this.extractCityFromAddress(place.formatted_address),
              district: this.extractDistrictFromAddress(place.formatted_address),
              street: place.name,
              country: 'Azerbaijan',
            };

            // Try to save to local database (ignore if duplicate)
            try {
              await Address.addAddress(addressData);
            } catch (saveError) {
              // Ignore duplicate errors
              if (!saveError.message.includes('duplicate')) {
                console.error('Error saving Google Maps result:', saveError);
              }
            }

            return {
              id: null, // Google Maps result, no local ID
              address: place.formatted_address,
              addressText: place.name,
              latitude: place.geometry.location.lat,
              longitude: place.geometry.location.lng,
              city: addressData.city,
              district: addressData.district,
              street: place.name,
              buildingNumber: null,
              source: 'google',
              relevanceScore: 0,
              popularityScore: 0,
            };
          } catch (error) {
            console.error('Error processing Google Maps result:', error);
            return null;
          }
        })
      );

      return processedResults.filter(result => result !== null);
      
    } catch (error) {
      console.error('Error in Google Maps search:', error);
      return [];
    }
  }

  /**
   * Combine local and Google Maps search results, avoiding duplicates
   * @param {Array} localResults - Local search results
   * @param {Array} googleResults - Google Maps search results
   * @returns {Array} Combined results
   */
  combineSearchResults(localResults, googleResults) {
    const combined = [...localResults];
    const localAddresses = new Set(localResults.map(r => r.address.toLowerCase()));
    
    // Add Google results that don't duplicate local results
    googleResults.forEach(googleResult => {
      if (!localAddresses.has(googleResult.address.toLowerCase())) {
        combined.push(googleResult);
      }
    });
    
    // Sort by relevance and popularity
    return combined.sort((a, b) => {
      // Local results first
      if (a.source === 'local' && b.source === 'google') return -1;
      if (a.source === 'google' && b.source === 'local') return 1;
      
      // Then by relevance score
      return (b.relevanceScore || 0) - (a.relevanceScore || 0);
    });
  }

  /**
   * Extract city from formatted address
   * @param {string} formattedAddress - Formatted address string
   * @returns {string} Extracted city
   */
  extractCityFromAddress(formattedAddress) {
    // Common cities in Azerbaijan
    const cities = ['Baku', 'Ganja', 'Sumgayit', 'Mingachevir', 'Lankaran', 'Shirvan', 'Nakhchivan'];
    
    for (const city of cities) {
      if (formattedAddress.includes(city)) {
        return city;
      }
    }
    
    // Default to Baku if no city found
    return 'Baku';
  }

  /**
   * Extract district from formatted address
   * @param {string} formattedAddress - Formatted address string
   * @returns {string} Extracted district
   */
  extractDistrictFromAddress(formattedAddress) {
    // Common districts in Baku
    const districts = [
      'Nasimi', 'Sabail', 'Yasamal', 'Narimanov', 'Binagadi', 
      'Khazar', 'Sabunchu', 'Nizami', 'Pirallahi', 'Garadagh',
      'Surakhani', 'Khatai', 'Absheron'
    ];
    
    for (const district of districts) {
      if (formattedAddress.includes(district)) {
        return district;
      }
    }
    
    return null;
  }

  /**
   * Get address details by coordinates (reverse geocoding)
   * @param {number} latitude - Latitude
   * @param {number} longitude - Longitude
   * @returns {Promise<Object>} Address details
   */
  async getAddressByCoordinates(latitude, longitude) {
    try {
      // First check local database
      const localResult = await Address.findOne({
        where: {
          latitude: parseFloat(latitude),
          longitude: parseFloat(longitude),
        },
        limit: 1,
      });

      if (localResult) {
        return {
          id: localResult.id,
          address: localResult.formattedAddress,
          addressText: localResult.addressText,
          latitude: parseFloat(localResult.latitude),
          longitude: parseFloat(localResult.longitude),
          city: localResult.city,
          district: localResult.district,
          street: localResult.street,
          buildingNumber: localResult.buildingNumber,
          source: 'local',
        };
      }

      // If not found locally, use Google Maps reverse geocoding
      if (this.googleMapsApiKey) {
        const response = await axios.get(`${this.googleMapsBaseUrl}/geocode/json`, {
          params: {
            latlng: `${latitude},${longitude}`,
            key: this.googleMapsApiKey,
            language: 'en',
          },
          timeout: 5000,
        });

        if (response.data.status === 'OK' && response.data.results.length > 0) {
          const result = response.data.results[0];
          
          return {
            id: null,
            address: result.formatted_address,
            addressText: result.formatted_address,
            latitude: parseFloat(latitude),
            longitude: parseFloat(longitude),
            city: this.extractCityFromAddress(result.formatted_address),
            district: this.extractDistrictFromAddress(result.formatted_address),
            street: null,
            buildingNumber: null,
            source: 'google',
          };
        }
      }

      return null;
    } catch (error) {
      console.error('Error getting address by coordinates:', error);
      throw error;
    }
  }
}

module.exports = AddressSearchService;
