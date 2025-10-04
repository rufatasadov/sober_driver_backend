# Ayiq Sürücü Customer App

Flutter müştəri tətbiqi - taksi sifariş sistemi üçün mobil tətbiq.

## 🚀 Xüsusiyyətlər

### 🔐 Authentication
- OTP ilə telefon nömrəsi yoxlaması
- Avtomatik istifadəçi qeydiyyatı
- Profil idarəetməsi

### 📱 Sifariş Funksiyaları
- Yeni sifariş yaratma
- Real-time sifariş izləmə
- Sifariş tarixçəsi
- Ödəniş üsulları (nəğd, kart, onlayn)

### 📍 Yer Xidmətləri
- Avtomatik yer təyini
- Ünvan axtarışı
- Xəritə inteqrasiyası

### 🔔 Bildirişlər
- Real-time sifariş yeniləmələri
- Sürücü yer izləmə
- Push bildirişlər

## 🛠️ Texnologiyalar

- **Flutter** - UI framework
- **Dart** - Proqramlaşdırma dili
- **BLoC/Cubit** - State management
- **Socket.IO** - Real-time communication
- **Firebase** - Push notifications
- **Google Maps** - Xəritə xidmətləri
- **Geolocator** - Yer xidmətləri

## 📦 Quraşdırma

### Tələblər
- Flutter SDK (3.7.2+)
- Dart SDK
- Android Studio / Xcode
- Node.js backend server

### Addımlar

1. **Layihəni klonlayın**
```bash
git clone <repository-url>
cd customer_app
```

2. **Asılılıqları quraşdırın**
```bash
flutter pub get
```

3. **Backend serverini işə salın**
```bash
# Backend qovluğunda
npm install
npm run dev
```

4. **Tətbiqi işə salın**
```bash
# Android
flutter run

# iOS
flutter run -d ios
```

## 🔧 Konfiqurasiya

### API Endpoints
- Base URL: `http://65.21.25.57:14122/api`
- Socket URL: `http://65.21.25.57:14122`

### Permissions
- **Android**: Location, Internet, Camera, Storage
- **iOS**: Location, Camera, Photo Library

### Firebase Setup
1. Firebase layihəsi yaradın
2. `google-services.json` (Android) və `GoogleService-Info.plist` (iOS) fayllarını əlavə edin
3. Google Maps API açarını konfiqurasiya edin

## 📱 Platform Dəstəyi

- ✅ Android (API 21+)
- ✅ iOS (12.0+)
- ✅ Responsive design

## 🏗️ Layihə Strukturu

```
lib/
├── core/
│   ├── constants/     # App constants
│   ├── services/      # Core services
│   ├── theme/         # App theme
│   └── utils/         # Utilities
├── features/
│   ├── auth/          # Authentication
│   ├── home/          # Home screen
│   ├── orders/        # Order management
│   ├── profile/       # User profile
│   └── notifications/ # Notifications
├── shared/
│   ├── widgets/       # Shared widgets
│   └── models/        # Data models
└── main.dart
```

## 🔄 State Management

BLoC/Cubit pattern istifadə olunur:

- **AuthCubit** - Authentication state
- **OrdersCubit** - Order management
- **ProfileCubit** - User profile
- **NotificationsCubit** - Notifications

## 🌐 API İnteqrasiyası

### Authentication
- `POST /auth/send-otp` - OTP göndər
- `POST /auth/verify-otp` - OTP yoxla
- `GET /auth/me` - İstifadəçi məlumatları

### Orders
- `POST /orders` - Yeni sifariş
- `GET /orders` - Sifarişlər
- `PATCH /orders/:id/status` - Sifariş statusu

### Socket Events
- `new_order_available` - Yeni sifariş
- `order_status_changed` - Status dəyişikliyi
- `driver_location_updated` - Sürücü yeri

## 🧪 Test

```bash
# Unit testlər
flutter test

# Widget testlər
flutter test test/widget_test.dart
```

## 📦 Build

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🚀 Deployment

### Google Play Store
1. APK/AAB faylını yaradın
2. Google Play Console-da yükləyin
3. Store listing konfiqurasiya edin

### Apple App Store
1. iOS build yaradın
2. Xcode ilə App Store Connect-ə yükləyin
3. App Store-da təqdim edin

## 🤝 Töhfə

1. Fork edin
2. Feature branch yaradın (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add some amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request yaradın

## 📝 Lisenziya

MIT License

## 📞 Əlaqə

Layihə haqqında suallarınız üçün issue yaradın və ya əlaqə saxlayın.

## 🔮 Gələcək Planlar

- [ ] Real-time xəritə inteqrasiyası
- [ ] Çoxlu ödəniş üsulları
- [ ] Sürücü rating sistemi
- [ ] Sifariş tarixçəsi
- [ ] Push bildirişlər
- [ ] Offline rejim
- [ ] Çoxdilli dəstək