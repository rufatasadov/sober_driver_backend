const NodeGeocoder = require('node-geocoder');

const geocoder = NodeGeocoder({
  provider: 'google',
  apiKey: process.env.GOOGLE_MAPS_API_KEY
});

// Haversine formula ilə iki nöqtə arasındakı məsafəni hesabla
const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // Yerin radiusu (km)
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const distance = R * c;
  return distance;
};

// Koordinatlardan ünvan alma
const getAddressFromCoordinates = async (latitude, longitude) => {
  try {
    const results = await geocoder.reverse({ lat: latitude, lon: longitude });
    if (results && results.length > 0) {
      return results[0].formattedAddress;
    }
    return null;
  } catch (error) {
    console.error('Ünvan alma xətası:', error);
    return null;
  }
};

// Ünvandan koordinat alma
const getCoordinatesFromAddress = async (address) => {
  try {
    const results = await geocoder.geocode(address);
    if (results && results.length > 0) {
      return {
        latitude: results[0].latitude,
        longitude: results[0].longitude
      };
    }
    return null;
  } catch (error) {
    console.error('Koordinat alma xətası:', error);
    return null;
  }
};

// Qiymət hesablama
const calculateFare = (distance, estimatedTime) => {
  const baseFare = 2; // AZN
  const perKmRate = 0.5; // AZN/km
  const perMinuteRate = 0.1; // AZN/dəqiqə
  
  const distanceFare = distance * perKmRate;
  const timeFare = estimatedTime * perMinuteRate;
  const totalFare = baseFare + distanceFare + timeFare;
  
  return {
    base: baseFare,
    distance: Math.round(distanceFare * 100) / 100,
    time: Math.round(timeFare * 100) / 100,
    total: Math.round(totalFare * 100) / 100
  };
};

// Yaxın sürücüləri tap (Sequelize ilə)
const findNearbyDrivers = async (latitude, longitude, maxDistance = 5) => {
  try {
    const Driver = require('../models/Driver');
    const User = require('../models/User');
    const { Op } = require('sequelize');
    
    console.log('Finding nearby drivers:', {
      latitude,
      longitude,
      maxDistance
    });

    // Bütün online və available sürücüləri al
    const drivers = await Driver.findAll({
      where: {
        isOnline: true,
        isAvailable: true,
        currentLocation: {
          [Op.ne]: null
        }
      },
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'phone']
        }
      ]
    });

    console.log('Found online drivers:', drivers.length);

    // Məsafəyə görə filter et
    const nearbyDrivers = drivers.filter(driver => {
      if (!driver.currentLocation || !driver.currentLocation.coordinates) {
        return false;
      }

      const [driverLon, driverLat] = driver.currentLocation.coordinates;
      const distance = calculateDistance(latitude, longitude, driverLat, driverLon);
      
      console.log(`Driver ${driver.id} distance: ${distance.toFixed(2)} km`);
      
      return distance <= maxDistance;
    });

    console.log('Nearby drivers within', maxDistance, 'km:', nearbyDrivers.length);

    return nearbyDrivers;
  } catch (error) {
    console.error('Yaxın sürücü tapma xətası:', error);
    return [];
  }
};

// Təxmini səyahət vaxtı hesabla (sadə hesablama)
const estimateTravelTime = (distance) => {
  const averageSpeed = 30; // km/saat (şəhər şəraitində)
  const timeInHours = distance / averageSpeed;
  const timeInMinutes = Math.round(timeInHours * 60);
  return Math.max(timeInMinutes, 5); // minimum 5 dəqiqə
};

module.exports = {
  calculateDistance,
  getAddressFromCoordinates,
  getCoordinatesFromAddress,
  calculateFare,
  findNearbyDrivers,
  estimateTravelTime
}; 