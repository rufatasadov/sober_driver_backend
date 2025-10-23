# 📍 Smart Address Search System

## Overview

The Smart Address Search System provides intelligent address searching capabilities for the operator panel's new order screen. It combines local database storage with Google Maps API fallback to deliver fast, accurate, and comprehensive address search results.

## 🏗️ Architecture

### Components

1. **Addresses Table** - PostgreSQL table storing local addresses with coordinates
2. **Address Model** - Sequelize model for database operations
3. **AddressSearchService** - Core service handling search logic
4. **Address API Routes** - RESTful endpoints for address operations
5. **SmartAddressSearchField** - Flutter widget for the operator panel

### Database Schema

```sql
CREATE TABLE addresses (
    id SERIAL PRIMARY KEY,
    address_text TEXT NOT NULL,
    formatted_address TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    city VARCHAR(100),
    district VARCHAR(100),
    street VARCHAR(200),
    building_number VARCHAR(20),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'Azerbaijan',
    search_keywords TEXT[], -- Array for fast searching
    popularity_score INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_address_coordinates UNIQUE (latitude, longitude)
);
```

## 🔍 Search Algorithm

### 1. Local Database Search
- **Full-text search** on `address_text` and `formatted_address`
- **Keyword array matching** using PostgreSQL GIN indexes
- **Individual word matching** for partial matches
- **Relevance scoring** based on multiple factors
- **Popularity ranking** for frequently used addresses

### 2. Google Maps Fallback
- **Text search API** with Azerbaijan region bias
- **Automatic saving** of Google results to local database
- **Duplicate prevention** to avoid storing same addresses
- **Error handling** with graceful fallback

### 3. Result Combination
- **Deduplication** between local and Google results
- **Smart ranking** prioritizing local results
- **Source indication** showing data origin
- **Popularity tracking** for future searches

## 🚀 API Endpoints

### Search Addresses
```http
GET /api/addresses/search?query=28 May metro&limit=10
```

**Response:**
```json
{
  "success": true,
  "data": {
    "query": "28 May metro",
    "results": [
      {
        "id": 1,
        "address": "28 May metro station, Baku, Azerbaijan",
        "addressText": "28 May metro station",
        "latitude": 40.3777,
        "longitude": 49.8520,
        "city": "Baku",
        "district": "Nasimi",
        "street": "28 May Street",
        "source": "local",
        "relevanceScore": 15.5,
        "popularityScore": 100
      }
    ],
    "total": 1,
    "sources": {
      "local": 1,
      "google": 0
    }
  }
}
```

### Reverse Geocoding
```http
GET /api/addresses/reverse-geocode?latitude=40.3777&longitude=49.8520
```

### Add Address
```http
POST /api/addresses/add
Content-Type: application/json

{
  "addressText": "28 May metro station",
  "formattedAddress": "28 May metro station, Baku, Azerbaijan",
  "latitude": 40.3777,
  "longitude": 49.8520,
  "city": "Baku",
  "district": "Nasimi",
  "street": "28 May Street",
  "buildingNumber": "1",
  "country": "Azerbaijan"
}
```

### Popular Addresses
```http
GET /api/addresses/popular?limit=10
```

### Address Statistics
```http
GET /api/addresses/stats
```

## 🎯 Flutter Widget Usage

### SmartAddressSearchField

```dart
SmartAddressSearchField(
  controller: _pickupAddressController,
  labelText: 'Götürülmə ünvanı',
  hintText: 'Götürülmə ünvanını daxil edin və ya axtarın',
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Götürülmə ünvanı tələb olunur';
    }
    return null;
  },
  onChanged: (value) => _calculateFare(),
  onCoordinatesSelected: (lat, lng) {
    setState(() {
      _pickupLatLon = [lat, lng];
    });
    _calculateFare();
  },
  onAddressSelected: (address) {
    _calculateFare();
  },
)
```

### Features
- **Real-time search** as user types (minimum 2 characters)
- **Visual indicators** showing search source (local vs Google)
- **Popularity scores** displayed for local results
- **Loading states** with progress indicators
- **Error handling** with fallback to manual input
- **Keyboard navigation** support
- **Accessibility** features

## ⚡ Performance Optimizations

### Database Indexes
- **GIN indexes** on `search_keywords` array
- **Full-text search indexes** on address fields
- **Composite indexes** on city/district combinations
- **Popularity index** for ranking

### Caching Strategy
- **Local results** cached in widget state
- **Popular addresses** cached for quick access
- **Search debouncing** to prevent excessive API calls

### API Optimizations
- **Request batching** for multiple searches
- **Timeout handling** (5 seconds for Google Maps)
- **Error recovery** with graceful degradation
- **Rate limiting** to prevent abuse

## 🔧 Setup Instructions

### 1. Database Migration
```bash
# Run the addresses table migration
npm run migrate-addresses
# or
node run_addresses_migration.js
```

### 2. Environment Variables
```env
# Add to .env file
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
DATABASE_URL=postgresql://postgres:password@localhost:5432/ayiqsurucu
```

### 3. Install Dependencies
```bash
npm install axios
```

### 4. Start Server
```bash
npm start
```

## 📊 Sample Data

The migration includes sample addresses for Baku, Azerbaijan:
- 28 May metro station
- Fountain Square
- Heydar Aliyev Center
- Baku International Airport
- Port Baku Mall
- Caspian Waterfront Mall
- Ganjlik Mall
- Nizami Street
- Baku State University
- Carpet Museum

## 🎨 UI/UX Features

### Search Results Display
- **Source indicators** (local database vs Google Maps)
- **Popularity badges** for frequently used addresses
- **Address hierarchy** (city, district, street)
- **Visual feedback** for loading states
- **Keyboard shortcuts** for quick selection

### Error Handling
- **Network error recovery** with retry options
- **Empty state messages** with helpful suggestions
- **Fallback to manual input** when search fails
- **User-friendly error messages** in Azerbaijani

## 🔒 Security Considerations

- **Input validation** on all API endpoints
- **Rate limiting** to prevent abuse
- **SQL injection protection** via Sequelize ORM
- **API key security** for Google Maps integration
- **Data sanitization** for search queries

## 📈 Analytics & Monitoring

### Metrics Tracked
- **Search success rates** (local vs Google)
- **Popular address usage** patterns
- **Search query performance** times
- **Database growth** statistics
- **API error rates**

### Logging
- **Search queries** with results count
- **Google Maps API usage** and costs
- **Database performance** metrics
- **Error tracking** with stack traces

## 🚀 Future Enhancements

### Planned Features
- **Fuzzy matching** for typos and variations
- **Voice search** integration
- **Address suggestions** based on user history
- **Multi-language support** for search queries
- **Batch address import** from external sources
- **Address validation** and verification
- **Geofencing** for location-based suggestions

### Performance Improvements
- **Redis caching** for popular searches
- **Elasticsearch integration** for advanced search
- **CDN integration** for static address data
- **Database sharding** for large datasets
- **Background sync** with Google Maps updates

## 📝 Testing

### Unit Tests
- Address model operations
- Search service logic
- API endpoint validation
- Widget functionality

### Integration Tests
- Database migration
- API integration
- Google Maps fallback
- End-to-end search flow

### Performance Tests
- Search response times
- Database query optimization
- Memory usage monitoring
- Concurrent user handling

## 🐛 Troubleshooting

### Common Issues

1. **Search not working**
   - Check database connection
   - Verify API endpoints are accessible
   - Ensure Google Maps API key is valid

2. **Slow search results**
   - Check database indexes
   - Monitor API response times
   - Verify network connectivity

3. **Google Maps errors**
   - Check API key validity
   - Monitor quota usage
   - Verify billing status

### Debug Mode
Enable debug logging by setting:
```env
NODE_ENV=development
DEBUG=addresses:*
```

## 📞 Support

For issues or questions regarding the Smart Address Search System:
- Check the logs for error details
- Verify database connectivity
- Test API endpoints with Postman
- Review Google Maps API status
- Check network connectivity

---

**Last Updated:** December 2024  
**Version:** 1.0.0  
**Maintainer:** AyiqSurucu Development Team
