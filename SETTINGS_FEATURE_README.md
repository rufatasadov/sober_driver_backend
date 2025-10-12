# Sifariş Nömrəsi Prefix Parametri

Bu yenilik admin paneldən operator paneldə yeni sifarişlərin nömrə prefix-ini konfiqurasiya etməyə imkan verir.

## Əlavə edilən funksionallıq

### Backend

1. **Settings Model** (`models/Setting.js`)
   - Sistem parametrlərini saxlamaq üçün yeni model
   - `getValue()`, `setValue()`, və `getAll()` metodları

2. **Settings API Endpoints** (`routes/admin.js`)
   - `GET /api/admin/settings` - Bütün parametrləri gətir
   - `GET /api/admin/settings/:key` - Müəyyən parametri gətir
   - `POST /api/admin/settings` - Yeni parametr yarat
   - `PUT /api/admin/settings/:key` - Parametri yenilə
   - `DELETE /api/admin/settings/:key` - Parametri sil

3. **Order Model Yeniləmələri** (`models/Order.js`)
   - Sifariş nömrəsi yaradılmasında dinamik prefix istifadəsi
   - `order_prefix` parametri settings-dən oxunur

4. **Orders Route Yeniləmələri** (`routes/orders.js`)
   - `generateOrderNumber()` funksiyası dinamik prefix istifadə edir

5. **Database Migration** (`migrations/add_settings_table.sql`)
   - Settings cədvəli yaradılır
   - Default parametrlər əlavə edilir (order_prefix, fare məlumatları və s.)

### Frontend (Operator Panel)

1. **Admin Provider Yeniləmələri** (`operator_panel/lib/providers/admin_provider.dart`)
   - `loadSettings()` - Parametrləri yüklə
   - `getSetting()` - Müəyyən parametri al
   - `updateSetting()` - Parametri yenilə
   - `createSetting()` - Yeni parametr yarat
   - `deleteSetting()` - Parametri sil

2. **Settings Tab** (`operator_panel/lib/widgets/admin/settings_tab.dart`)
   - Parametrləri göstərən UI
   - Parametrləri redaktə etmək, əlavə etmək və silmək üçün dialoglar

3. **Admin Screen Yeniləmələri** (`operator_panel/lib/screens/admin_screen.dart`)
   - "Parametrlər" tabı əlavə edildi

## Quraşdırma

### 1. Database Migration-u icra edin

PostgreSQL üçün:
```bash
psql -U your_username -d your_database -f migrations/add_settings_table.sql
```

Və ya Node.js ilə:
```bash
node -e "
const { sequelize } = require('./config/database');
const fs = require('fs');

async function runMigration() {
  try {
    const sql = fs.readFileSync('./migrations/add_settings_table.sql', 'utf8');
    await sequelize.query(sql);
    console.log('Migration completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

runMigration();
"
```

### 2. Server-i yenidən başladın

```bash
npm start
# və ya
node server.js
```

### 3. Operator Panel-i yenidən build edin

```bash
cd operator_panel
flutter pub get
flutter build web
# və ya development üçün
flutter run -d chrome
```

## İstifadə

1. Operator panel-ə admin kimi daxil olun
2. "Admin Panel" səhifəsinə keçin
3. "Parametrlər" tabına klikləyin
4. `order_prefix` parametrini tapın və redaktə edin
5. Yeni prefix-i daxil edin (məsələn: "SIP", "ORD", "SF" və s.)
6. "Saxla" düyməsinə klikləyin

Artıq yeni sifarişlər yeni prefix ilə yaradılacaq.

## Nümunə

Əgər prefix-i "SIP" olaraq dəyişsəniz, yeni sifariş nömrələri belə olacaq:
- `SIP-20241012-0001`
- `SIP-20241012-0002`
- və s.

Default prefix "ORD"-dir:
- `ORD-20241012-0001`
- `ORD-20241012-0002`
- və s.

## Əlavə parametrlər

Migration həmçinin digər faydalı parametrləri də əlavə edir:
- `base_fare` - Əsas tarif (AZN)
- `per_km_fare` - Kilometr başına tarif (AZN)
- `per_minute_fare` - Dəqiqə başına tarif (AZN)
- `minimum_fare` - Minimum tarif (AZN)
- `currency` - Valyuta (AZN)

Bu parametrlər də eyni şəkildə admin paneldən idarə oluna bilər.

## Texniki detallar

- Prefix boş ola bilməz
- Prefix maksimum 20 simvol ola bilər
- Əgər settings-də prefix tapılmazsa, default "ORD" istifadə olunur
- Order nömrəsi formatı: `{PREFIX}-{YYYYMMDD}-{XXXX}` 
  - PREFIX: Konfiqurasiya edilə bilən prefix
  - YYYYMMDD: İl, ay, gün
  - XXXX: Təsadüfi 4 rəqəmli nömrə

## Troubleshooting

Əgər parametrlər yüklənmirsə:
1. Database migration-un düzgün icra edildiyindən əmin olun
2. Backend server-in yenidən başladıldığından əmin olun
3. Admin istifadəçisinin `admin.access` və `settings.update` privileyalarına sahib olduğundan əmin olun
4. Browser console-da xəta mesajlarını yoxlayın

Əgər yeni prefix işləmirsə:
1. Parametrin saxlanıldığından əmin olun (POST/PUT sorğusunun uğurlu olduğunu yoxlayın)
2. Backend loglarını yoxlayın
3. Database-də settings cədvəlində parametrin mövcud olduğunu yoxlayın:
   ```sql
   SELECT * FROM settings WHERE key = 'order_prefix';
   ```

