# Peregon hayda - Backend API

Bu layihə taxi sifariş sistemi üçün tam funksional backend API-dir. Sistem müştəri, sürücü, operator, dispetçer və admin modullarını dəstəkləyir.

## 🚀 Xüsusiyyətlər

### 🔐 Authentication & Authorization
- OTP ilə telefon nömrəsi yoxlaması (müştərilər üçün)
- Username/password ilə giriş (operator və admin üçün)
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
- **PostgreSQL** - Database
- **Sequelize** - ORM
- **Socket.IO** - Real-time communication
- **JWT** - Authentication
- **Firebase Admin** - Push notifications
- **Node-geocoder** - Geolocation services

## 📦 Quraşdırma

### Tələblər
- Node.js (v14 və ya daha yuxarı)
- PostgreSQL (v12 və ya daha yuxarı)
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

3. **PostgreSQL verilənlər bazasını yaradın**
```sql
CREATE DATABASE ayiqsurucu;
CREATE USER ayiqsurucu_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE ayiqsurucu TO ayiqsurucu_user;
```

4. **Environment dəyişənlərini konfiqurasiya edin**
```bash
cp env.example .env
```

`.env` faylını redaktə edin:
```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Database (PostgreSQL)
DATABASE_URL=postgresql://ayiqsurucu_user:your_password@localhost:5432/ayiqsurucu

# JWT Secret
JWT_SECRET=your-super-secret-jwt-key-here

# Firebase Configuration
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY=your-firebase-private-key
FIREBASE_CLIENT_EMAIL=your-firebase-client-email

# Google Maps API
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

5. **Default operator istifadəçisini yaradın**
```bash
npm run create-operator
```

Bu əmr default operator istifadəçisini yaradacaq:
- **Username:** operator
- **Password:** operator123
- **Role:** operator

6. **Serveri başladın**
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

#### Operator login (username/password)
```
POST /api/auth/operator-login
Content-Type: application/json

{
  "username": "operator",
  "password": "operator123"
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

### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR NOT NULL UNIQUE,
  name VARCHAR NOT NULL,
  email VARCHAR UNIQUE,
  role VARCHAR NOT NULL DEFAULT 'customer',
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  profile_image VARCHAR,
  fcm_token VARCHAR,
  last_login TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Drivers Table
```sql
CREATE TABLE drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  license_number VARCHAR NOT NULL UNIQUE,
  vehicle_info JSONB NOT NULL DEFAULT '{}',
  documents JSONB DEFAULT '{}',
  is_online BOOLEAN DEFAULT FALSE,
  is_available BOOLEAN DEFAULT FALSE,
  current_location JSONB,
  rating JSONB DEFAULT '{"average": 0, "count": 0}',
  earnings JSONB DEFAULT '{"total": 0, "today": 0, "thisWeek": 0, "thisMonth": 0}',
  status VARCHAR DEFAULT 'pending',
  commission DECIMAL(5,2) DEFAULT 20.00,
  last_active TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Orders Table
```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number VARCHAR NOT NULL UNIQUE,
  customer_id UUID REFERENCES users(id),
  driver_id UUID REFERENCES drivers(id),
  pickup JSONB NOT NULL,
  destination JSONB NOT NULL,
  status VARCHAR DEFAULT 'pending',
  estimated_time INTEGER,
  estimated_distance DECIMAL(8,2),
  fare JSONB NOT NULL DEFAULT '{"base": 0, "distance": 0, "time": 0, "total": 0, "currency": "AZN"}',
  payment JSONB DEFAULT '{"method": "cash", "status": "pending", "transactionId": null}',
  rating JSONB,
  timeline JSONB DEFAULT '[]',
  notes TEXT,
  cancelled_by VARCHAR,
  cancellation_reason TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
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