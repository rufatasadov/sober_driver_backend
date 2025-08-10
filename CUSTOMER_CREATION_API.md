# Customer Creation API for Orders

## Overview
The order creation API now supports automatic customer creation when a new order is placed. If a phone number is provided that doesn't exist in the customer table, a new customer will be automatically created.

## API Endpoint
`POST /orders`

## Request Body

### Required Fields
- `pickup.coordinates`: Array of coordinates [longitude, latitude]
- `pickup.address`: Pickup address string
- `destination.coordinates`: Array of coordinates [longitude, latitude]
- `destination.address`: Destination address string
- `payment.method`: Payment method ('cash', 'card', 'online')

### Optional Fields for Customer Creation
- `customerPhone`: Phone number for the customer (if not provided, current authenticated user will be used)
- `customerName`: Customer name (required if customerPhone is provided)
- `notes`: Additional notes for the order

## Customer Creation Logic

1. **If `customerPhone` is provided:**
   - System checks if a customer with that phone number already exists
   - If customer exists: uses existing customer ID
   - If customer doesn't exist: creates new customer with provided name and phone
   - `customerName` is required when `customerPhone` is provided

2. **If `customerPhone` is not provided:**
   - Uses the currently authenticated user as the customer
   - No new customer is created

## Example Requests

### Create Order for Existing Customer
```json
{
  "pickup": {
    "coordinates": [49.8516, 40.3777],
    "address": "Baku, Azerbaijan",
    "instructions": "Main entrance"
  },
  "destination": {
    "coordinates": [49.8516, 40.3777],
    "address": "Baku, Azerbaijan",
    "instructions": "Reception desk"
  },
  "payment": {
    "method": "cash"
  },
  "customerPhone": "+994501234567",
  "customerName": "John Doe"
}
```

### Create Order for New Customer
```json
{
  "pickup": {
    "coordinates": [49.8516, 40.3777],
    "address": "Baku, Azerbaijan"
  },
  "destination": {
    "coordinates": [49.8516, 40.3777],
    "address": "Baku, Azerbaijan"
  },
  "payment": {
    "method": "card"
  },
  "customerPhone": "+994507654321",
  "customerName": "Jane Smith"
}
```

### Create Order for Current User (No Customer Creation)
```json
{
  "pickup": {
    "coordinates": [49.8516, 40.3777],
    "address": "Baku, Azerbaijan"
  },
  "destination": {
    "coordinates": [49.8516, 40.3777],
    "address": "Baku, Azerbaijan"
  },
  "payment": {
    "method": "cash"
  }
}
```

## Response

### Success Response (201)
```json
{
  "message": "Sifariş uğurla yaradıldı",
  "order": {
    "id": "uuid",
    "orderNumber": "ORD-20241201-0001",
    "status": "pending",
    "estimatedTime": 15,
    "estimatedDistance": 2.5,
    "fare": {
      "base": 2.0,
      "distance": 1.5,
      "time": 0.5,
      "total": 4.0,
      "currency": "AZN"
    },
    "nearbyDrivers": 3,
    "customer": {
      "id": "uuid",
      "name": "John Doe",
      "phone": "+994501234567"
    }
  }
}
```

### Error Responses

#### Missing Customer Name (400)
```json
{
  "error": "Yeni müştəri yaratmaq üçün ad tələb olunur",
  "details": "customerPhone verildiyi halda customerName də tələb olunur"
}
```

#### Customer Creation Failed (500)
```json
{
  "error": "Müştəri yaradıla bilmədi",
  "details": "Error message details"
}
```

## Notes

- Phone numbers are automatically cleaned (spaces removed) before processing
- New customers are created with `isVerified: true` and `role: 'customer'`
- The system maintains backward compatibility - existing orders without customerPhone will work as before
- Customer information is included in the response for verification purposes
