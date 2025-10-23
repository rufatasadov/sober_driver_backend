# Ayiq Sürücü - Operator Panel

Bu Flutter Web tətbiqi taxi sifariş sistemi üçün operator panelidir. Operatorlar bu panel vasitəsilə sifarişləri idarə edə, müştərilərlə işləyə və sürücüləri təyin edə bilərlər.

## 🚀 Xüsusiyyətlər

### 📊 Dashboard
- Bugünkü statistika (sifarişlər, tamamlanmış, gözləyən, ləğv edilmiş)
- Online sürücülər sayı
- Son sifarişlər siyahısı
- Real-time məlumatlar

### 📋 Sifariş İdarəetməsi
- Bütün sifarişləri görə bilmə
- Yeni sifariş əlavə etmə (manual)
- Sifariş statusunu yeniləmə
- Sürücü təyin etmə
- Sifariş detallarına baxma
- Sifariş ləğv etmə

### 👥 Müştəri İdarəetməsi
- Müştəri axtarışı
- Müştəri məlumatlarını yeniləmə
- Müştəri sifariş tarixçəsi
- Müştəri statistikası

### 🚗 Sürücü İdarəetməsi
- Sürücüləri görə bilmə
- Yaxın sürücüləri tapma
- Sürücü statusunu izləmə
- Sürücü məlumatlarına baxma

### 🔍 Axtarış və Filter
- Sifariş axtarışı
- Tarix aralığı filteri
- Status filteri
- Müştəri telefon nömrəsi ilə axtarış

## 🛠️ Texnologiyalar

- **Flutter Web** - UI framework
- **Provider** - State management
- **HTTP** - API kommunikasiyası
- **Socket.IO** - Real-time bildirişlər
- **Intl** - Beynəlxalqlaşdırma
- **Shared Preferences** - Local storage

## 📦 Quraşdırma

### Tələblər
- Flutter SDK (3.0.0 və ya daha yuxarı)
- Dart SDK
- Web browser (Chrome, Firefox, Safari, Edge)

### Quraşdırma addımları

1. **Layihəni klonlayın**
```bash
git clone <repository-url>
cd ayiqsurucu/operator_panel
```

2. **Asılılıqları quraşdırın**
```bash
flutter pub get
```

3. **Environment dəyişənlərini konfiqurasiya edin**
`lib/utils/constants.dart` faylında API endpoint-lərini yeniləyin:
```dart
class ApiEndpoints {
  static const String baseUrl = 'http://localhost:3000/api';
  // ...
}
```

4. **Tətbiqi işə salın**
```bash
# Development
flutter run -d chrome

# Production build
flutter build web
```

## 📱 İstifadə

### Giriş
1. Telefon nömrəsini daxil edin
2. OTP kodu göndərin
3. OTP kodunu daxil edin
4. Giriş edin

### Dashboard
- Sol paneldə naviqasiya menyusu
- Əsas statistika kartları
- Son sifarişlər siyahısı

### Sifarişlər
- Bütün sifarişləri görə bilmə
- Yeni sifariş əlavə etmə
- Sifariş statusunu yeniləmə
- Sürücü təyin etmə

### Müştərilər
- Müştəri axtarışı
- Müştəri məlumatları
- Sifariş tarixçəsi

### Sürücülər
- Sürücü siyahısı
- Yaxın sürücülər
- Status izləmə

## 🔧 Konfiqurasiya

### API Endpoints
`lib/utils/constants.dart` faylında API endpoint-lərini yeniləyin:

```dart
class ApiEndpoints {
  static const String baseUrl = 'http://your-api-domain.com/api';
  static const String auth = '$baseUrl/auth';
  static const String orders = '$baseUrl/orders';
  static const String drivers = '$baseUrl/drivers';
  static const String operator = '$baseUrl/operator';
  // ...
}
```

### Socket.IO
Real-time bildirişlər üçün Socket.IO konfiqurasiyası:

```dart
class SocketEvents {
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String newOrder = 'new_order';
  static const String orderStatusUpdated = 'order_status_updated';
  // ...
}
```

## 🎨 UI/UX

### Rəng sxemi
- Primary: #1976D2 (Blue)
- Secondary: #42A5F5 (Light Blue)
- Success: #388E3C (Green)
- Warning: #F57C00 (Orange)
- Error: #D32F2F (Red)

### Responsive Design
- Desktop (1200px+)
- Tablet (768px - 1199px)
- Mobile (320px - 767px)

## 🔒 Təhlükəsizlik

- JWT token authentication
- Role-based access control
- HTTPS tələbi
- Input validation
- XSS qorunması

## 🧪 Test

```bash
# Unit testlər
flutter test

# Widget testlər
flutter test test/widget_test.dart

# Integration testlər
flutter drive --target=test_driver/app.dart
```

## 📦 Build

### Development
```bash
flutter run -d chrome --web-port=8080
```

### Production
```bash
flutter build web --release
```

### Docker
```bash
# Docker image yarat
docker build -t ayiqsurucu-operator .

# Container işə sal
docker run -p 8080:80 ayiqsurucu-operator
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

## 🔄 Yeniləmələr

### v1.0.0
- İlkin versiya
- Dashboard
- Sifariş idarəetməsi
- Müştəri idarəetməsi
- Sürücü idarəetməsi
- Real-time bildirişlər 