# 📮 Postman Collection Setup Guide

Bu təlimat Ayiq Sürücü API-ni test etmək üçün Postman collection-unu quraşdırmaq və istifadə etmək üçündür.

## 📋 Tələblər

- Postman Desktop App (v10.0 və ya daha yuxarı)
- Ayiq Sürücü Backend API işləyir (localhost:3000)
- PostgreSQL verilənlər bazası qoşulub

## 🚀 Quraşdırma Addımları

### 1. Collection və Environment İdxal Et

1. **Collection İdxal Et:**
   - Postman açın
   - "Import" düyməsinə basın
   - `AyiqSurucu_API.postman_collection.json` faylını seçin
   - "Import" düyməsinə basın

2. **Environment İdxal Et:**
   - "Import" düyməsinə basın
   - `AyiqSurucu_Environment.postman_environment.json` faylını seçin
   - "Import" düyməsinə basın

3. **Environment Seç:**
   - Sağ üst küncdə "Ayiq Sürücü - Development" environment-ni seçin

### 2. Backend API-ni Başlat

```bash
# Backend qovluğuna keç
cd backend

# Asılılıqları yüklə
npm install

# Environment dəyişənlərini təyin et
cp env.example .env
# .env faylını redaktə et və lazımi dəyərləri daxil et

# Serveri başlat
npm run dev
```

## 🔐 Authentication Test Etmə

### 1. OTP Göndər

1. **"🔐 Authentication"** qovluğunu açın
2. **"Send OTP"** request-ini seçin
3. Body-də telefon nömrəsini dəyişin (məsələn: `+994501234567`)
4. **"Send"** düyməsinə basın
5. Console-da OTP kodunu görün (development rejimində)

### 2. OTP Yoxla və Token Al

1. **"Verify OTP & Login"** request-ini seçin
2. Body-də:
   - `phone`: Eyni telefon nömrəsi
   - `otp`: Console-da görünən OTP kodu
   - `name`: İstifadəçi adı
3. **"Send"** düyməsinə basın
4. Response-dan JWT token-i kopyalayın

### 3. Token-i Environment-a Əlavə Et

1. Sağ üst küncdə environment düyməsinə basın
2. **"auth_token"** dəyişənini tapın
3. Kopyaladığınız token-i daxil edin
4. **"Save"** düyməsinə basın

## 🧪 Test Ssenariləri

### Customer Test Ssenarisi

1. **Authentication:**
   - Send OTP → Verify OTP → Token al

2. **Order Yaratma:**
   - "🚗 Orders" → "Create Order"
   - Body-də pickup və destination məlumatlarını daxil edin
   - Send → Order ID-ni qeyd edin

3. **Order-ləri Görüntüləmə:**
   - "Get My Orders" → Send
   - Yaratdığınız order-ləri görün

4. **Order Detalları:**
   - "Get Order Details" → Order ID daxil edin → Send

### Operator Test Ssenarisi

1. **Operator Token Al:**
   - Admin panelindən istifadəçiyə "operator" rolunu verin
   - Eyni telefon nömrəsi ilə login olun
   - Token-i "operator_token" dəyişəninə əlavə edin

2. **Dashboard:**
   - "👨‍💼 Operator Panel" → "Get Dashboard" → Send

3. **Manual Order Yaratma:**
   - "Create Order (Manual)" → Customer məlumatları ilə → Send

4. **Order-ləri İdarə Etmə:**
   - "Get All Orders" → Filter və pagination ilə → Send

### Driver Test Ssenarisi

1. **Driver Qeydiyyatı:**
   - "🚕 Driver Management" → "Driver Registration"
   - Vehicle və document məlumatları ilə → Send

2. **Status Yeniləmə:**
   - "Update Driver Status" → Online/Available → Send

3. **Order Qəbul Etmə:**
   - "Get Driver Orders" → Mövcud order-ləri görün
   - "Accept Order" → Order ID ilə → Send

## 🔧 Environment Dəyişənləri

| Dəyişən | Təsvir | Nümunə |
|---------|--------|--------|
| `base_url` | API əsas URL | `http://localhost:3000` |
| `auth_token` | Customer JWT token | `eyJhbGciOiJIUzI1NiIs...` |
| `operator_token` | Operator JWT token | `eyJhbGciOiJIUzI1NiIs...` |
| `driver_token` | Driver JWT token | `eyJhbGciOiJIUzI1NiIs...` |
| `admin_token` | Admin JWT token | `eyJhbGciOiJIUzI1NiIs...` |
| `order_id` | Test üçün order ID | `uuid-here` |
| `user_id` | Test üçün user ID | `uuid-here` |
| `driver_id` | Test üçün driver ID | `uuid-here` |
| `test_phone` | Test telefon nömrəsi | `+994501234567` |
| `test_otp` | Test OTP kodu | `123456` |

## 📝 Test Nümunələri

### Order Yaratma Nümunəsi

```json
{
  "pickup": {
    "coordinates": [49.8516, 40.3777],
    "address": "Bakı şəhəri, Nərimanov rayonu",
    "instructions": "Körpü yaxınlığında"
  },
  "destination": {
    "coordinates": [49.8516, 40.3777],
    "address": "Bakı şəhəri, Yasamal rayonu",
    "instructions": "Mərmər bina"
  },
  "payment": {
    "method": "cash"
  },
  "notes": "Təcili sifariş"
}
```

### Driver Qeydiyyat Nümunəsi

```json
{
  "licenseNumber": "AZ123456789",
  "vehicleInfo": {
    "make": "Toyota",
    "model": "Camry",
    "year": 2020,
    "color": "Ağ",
    "plateNumber": "10-AA-123"
  },
  "documents": {
    "license": "license_file_url",
    "insurance": "insurance_file_url",
    "vehicleRegistration": "registration_file_url"
  }
}
```

## 🚨 Xətalar və Həll Yolları

### 401 Unauthorized
- Token-in düzgün olduğunu yoxlayın
- Token-in vaxtının keçmədiyini yoxlayın
- Environment-da düzgün token dəyişənini istifadə etdiyinizi yoxlayın

### 400 Bad Request
- Request body-nin düzgün formatda olduğunu yoxlayın
- Validation xətalarını oxuyun
- Lazımi sahələrin doldurulduğunu yoxlayın

### 500 Internal Server Error
- Backend server-in işlədiyini yoxlayın
- Database qoşulmasını yoxlayın
- Console log-larını yoxlayın

## 🔄 Automation

### Collection Runner

1. **Test Ssenarisi Yarat:**
   - Collection-a sağ basın → "Run collection"
   - Test sırasını təyin edin
   - Environment seçin

2. **Test Script-ləri:**
   - Hər request-də "Tests" tab-ında JavaScript yazın
   - Response status kodunu yoxlayın
   - Token-ləri avtomatik saxlayın

### Newman CLI

```bash
# Newman quraşdır
npm install -g newman

# Collection-i run et
newman run AyiqSurucu_API.postman_collection.json -e AyiqSurucu_Environment.postman_environment.json

# HTML report yarat
newman run AyiqSurucu_API.postman_collection.json -e AyiqSurucu_Environment.postman_environment.json -r html
```

## 📊 Monitoring

### Response Time
- Hər request-in response vaxtını izləyin
- 2 saniyədən çox olan request-ləri analiz edin

### Error Rate
- 4xx və 5xx xətalarının sayını izləyin
- Xəta pattern-lərini analiz edin

### API Usage
- Hangi endpoint-lərin ən çox istifadə olunduğunu izləyin
- Performance bottleneck-ləri tapın

## 🎯 Best Practices

1. **Token Management:**
   - Token-ləri environment dəyişənlərində saxlayın
   - Token vaxtını izləyin
   - Avtomatik token yeniləmə istifadə edin

2. **Test Data:**
   - Test üçün ayrı data istifadə edin
   - Production data-nı test etməyin
   - Test data-nı təmizləyin

3. **Documentation:**
   - Hər request üçün description yazın
   - Response nümunələri əlavə edin
   - Error case-ləri sənədləşdirin

4. **Version Control:**
   - Collection və environment fayllarını Git-də saxlayın
   - Dəyişiklikləri commit edin
   - Team üzvləri ilə paylaşın

## 📞 Dəstək

Əgər problem yaşayırsınızsa:

1. Console log-larını yoxlayın
2. Network tab-ında request/response-ları izləyin
3. Environment dəyişənlərini yoxlayın
4. Backend server status-unu yoxlayın

---

**Qeyd:** Bu collection development mühiti üçün hazırlanıb. Production-da istifadə etməzdən əvvəl security tədbirlərini yoxlayın. 