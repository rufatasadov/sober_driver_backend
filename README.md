# Ayiq Sürücü - Backend API

Bu layihə taxi sifariş sistemi üçün tam funksional backend API-dir. Sistem müştəri, sürücü, operator, dispetçer və admin modullarını dəstəkləyir.

## 🚀 Xüsusiyyətlər

### 🔐 Authentication & Authorization
- OTP ilə telefon nömrəsi yoxlaması (Twilio)
- JWT token əsaslı authentication
- Role-based access control (RBAC)
- İstifadəçi rolları: customer, driver, operator, dispatcher, admin

### 📱 Müştəri Funksiyaları
- OTP ilə qeydiyyat və login
- Sifariş yaratma
- Real-time sifariş izləmə
- Qiymətləndirmə və geribildirim
- Sifariş tarixçəsi

### 🚗 Sürücü Funksiyaları
- Sürücü qeydiyyatı və sənəd yükləmə
- Online/offline status
- Real-time yer yeniləməsi
- Yaxın sifarişləri görə bilmə
- Sifariş qəbul/imtina
- Qazanc hesabatları

### 🎛️ Operator Panel
- Manual sifariş əlavə etmə
- Müştəri məlumatları idarəetməsi
- Sifariş status izləmə
- Sürücü təyin etmə

### 📊 Dispetçer Panel
- Aktiv sifarişləri izləmə
- Real-time sürücü yer izləmə
- Manual sürücü təyin etmə
- Xəritə üzərində koordinasiya

### 👨‍💼 Admin Panel
- İstifadəçi idarəetməsi
- Sürücü sənəd təsdiqi
- Statistika və hesabatlar
- Sistem parametrləri

### 🔌 Real-time Kommunikasiya
- Socket.IO ilə real-time bildirişlər
- Sifariş status yeniləmələri
- Sürücü yer izləmə
- Push bildirişlər (FCM)

## 🛠️ Texnologiyalar

- **Node.js** - Server runtime
- **Express.js** - Web framework
- **MongoDB** - Database
- **Mongoose** - ODM
- **Socket.IO** - Real-time communication
- **JWT** - Authentication
- **Twilio** - SMS/OTP
- **Firebase Admin** - Push notifications
- **Node-geocoder** - Geolocation services

## 📦 Quraşdırma

### Tələblər
- Node.js (v14 və ya daha yuxarı)
- MongoDB (v4.4 və ya daha yuxarı)
- Twilio hesabı
- Firebase layihəsi

### Quraşdırma addımları

1. **Layihəni klonlayın**
```bash
git clone <repository-url>
cd ayiqsurucu
```

2. **Asılılıqları quraşdırın**
```bash
npm install
```

3. **Environment dəyişənlərini konfiqurasiya edin**
```bash
cp env.example .env
```

`.env` faylını redaktə edin:
```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Database
MONGODB_URI=mongodb://localhost:27017/ayiqsurucu

# JWT Secret
JWT_SECRET=your-super-secret-jwt-key-here

# Twilio Configuration
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=your-twilio-phone-number

# Firebase Configuration
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY=your-firebase-private-key
FIREBASE_CLIENT_EMAIL=your-firebase-client-email

# Google Maps API
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

4. **Serveri başladın**
```bash
# Development
npm run dev

# Production
npm start
```

## 📚 API Sənədləri

### Authentication Endpoints

#### OTP göndər
```
POST /api/auth/send-otp
Content-Type: application/json

{
  "phone": "+994501234567"
}
```

#### OTP yoxla və login
```
POST /api/auth/verify-otp
Content-Type: application/json

{
  "phone": "+994501234567",
  "otp": "123456",
  "name": "John Doe" // yeni istifadəçi üçün
}
```

### Sifariş Endpoints

#### Yeni sifariş yarat
```
POST /api/orders
Authorization: Bearer <token>
Content-Type: application/json

{
  "pickup": {
    "coordinates": [49.8516, 40.3777],
    "address": "Bakı şəhəri, Nərimanov rayonu",
    "instructions": "Körpü yaxınlığında"
  },
  "destination": {
    "coordinates": [49.8516, 40.3777],
    "address": "Bakı şəhəri, Yasamal rayonu",
    "instructions": "Mərkəz yaxınlığında"
  },
  "payment": {
    "method": "cash"
  },
  "notes": "Təcili sifariş"
}
```

#### Sifariş statusunu yenilə
```
PATCH /api/orders/:orderId/status
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "completed",
  "location": [49.8516, 40.3777]
}
```

### Sürücü Endpoints

#### Sürücü qeydiyyatı
```
POST /api/drivers/register
Authorization: Bearer <token>
Content-Type: application/json

{
  "licenseNumber": "AZE123456789",
  "vehicleInfo": {
    "make": "Toyota",
    "model": "Camry",
    "year": 2020,
    "color": "Ağ",
    "plateNumber": "10-AA-123"
  }
}
```

#### Yer yenilə
```
PATCH /api/drivers/location
Authorization: Bearer <token>
Content-Type: application/json

{
  "latitude": 40.3777,
  "longitude": 49.8516,
  "address": "Bakı şəhəri, Nərimanov rayonu"
}
```

## 🔌 Socket.IO Events

### Client-dən Server-ə
- `update_location` - Sürücü yerini yenilə
- `update_status` - Sürücü statusunu yenilə
- `new_order` - Yeni sifariş bildirişi
- `order_status_updated` - Sifariş statusu yeniləndi
- `order_accepted` - Sifariş qəbul edildi
- `order_rejected` - Sifariş imtina edildi
- `track_order` - Sifariş izləməyə başla

### Server-dən Client-ə
- `new_order_available` - Yeni sifariş mövcuddur
- `order_status_changed` - Sifariş statusu dəyişdi
- `driver_assigned` - Sürücü təyin edildi
- `driver_location_updated` - Sürücü yeri yeniləndi
- `order_completed` - Sifariş tamamlandı

## 📊 Database Schema

### User Collection
```javascript
{
  _id: ObjectId,
  phone: String,
  name: String,
  email: String,
  role: String, // customer, driver, operator, dispatcher, admin
  isVerified: Boolean,
  isActive: Boolean,
  profileImage: String,
  fcmToken: String,
  lastLogin: Date,
  createdAt: Date,
  updatedAt: Date
}
```

### Driver Collection
```javascript
{
  _id: ObjectId,
  userId: ObjectId,
  licenseNumber: String,
  vehicleInfo: {
    make: String,
    model: String,
    year: Number,
    color: String,
    plateNumber: String
  },
  documents: {
    license: String,
    insurance: String,
    registration: String,
    vehiclePhoto: String
  },
  isOnline: Boolean,
  isAvailable: Boolean,
  currentLocation: {
    type: String,
    coordinates: [Number],
    address: String
  },
  rating: {
    average: Number,
    count: Number
  },
  earnings: {
    total: Number,
    today: Number,
    thisWeek: Number,
    thisMonth: Number
  },
  status: String, // pending, approved, rejected, suspended
  commission: Number,
  lastActive: Date,
  createdAt: Date,
  updatedAt: Date
}
```

### Order Collection
```javascript
{
  _id: ObjectId,
  orderNumber: String,
  customer: ObjectId,
  driver: ObjectId,
  pickup: {
    location: {
      type: String,
      coordinates: [Number]
    },
    address: String,
    instructions: String
  },
  destination: {
    location: {
      type: String,
      coordinates: [Number]
    },
    address: String,
    instructions: String
  },
  status: String, // pending, accepted, driver_assigned, driver_arrived, in_progress, completed, cancelled
  estimatedTime: Number,
  estimatedDistance: Number,
  fare: {
    base: Number,
    distance: Number,
    time: Number,
    total: Number,
    currency: String
  },
  payment: {
    method: String, // cash, card, online
    status: String, // pending, paid, failed
    transactionId: String
  },
  rating: {
    customerRating: {
      rating: Number,
      comment: String,
      createdAt: Date
    },
    driverRating: {
      rating: Number,
      comment: String,
      createdAt: Date
    }
  },
  timeline: [{
    status: String,
    timestamp: Date,
    location: {
      type: String,
      coordinates: [Number]
    }
  }],
  notes: String,
  cancelledBy: String,
  cancellationReason: String,
  createdAt: Date,
  updatedAt: Date
}
```

## 🔒 Təhlükəsizlik

- JWT token authentication
- Rate limiting
- Input validation
- CORS konfiqurasiyası
- Helmet security headers
- Environment dəyişənləri

## 🧪 Test

```bash
npm test
```

## 📝 Lisenziya

MIT License

## 🤝 Töhfə

Layihəyə töhfə vermək üçün:

1. Fork edin
2. Feature branch yaradın (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add some amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request yaradın

## 📞 Əlaqə

Layihə haqqında suallarınız üçün issue yaradın və ya əlaqə saxlayın. 