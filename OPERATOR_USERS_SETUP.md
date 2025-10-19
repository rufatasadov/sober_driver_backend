# Operator Users Setup Script

Bu script AyiqSurucu operator modulu üçün 3 istifadəçi yaradır.

## 🎯 Yaradılan İstifadəçilər

| Role | Username | Password | Email | Açıqlama |
|------|----------|----------|-------|----------|
| **Admin** | `admin` | `admin123` | admin@ayiqsurucu.com | Tam yetkilər |
| **Dispatcher** | `dispatcher` | `dispatcher123` | dispatcher@ayiqsurucu.com | Sifariş idarəetməsi |
| **Operator** | `operator` | `operator123` | operator@ayiqsurucu.com | Əsas operator funksiyaları |

## 🚀 İstifadə

### 1. PostgreSQL Serveri Başlat
```bash
# Windows
start-postgresql.bat

# Manual
net start postgresql-x64-13
```

### 2. İstifadəçiləri Yarat
```bash
# Windows
create-operators.bat

# Manual
node scripts/create-operator-users.js
```

## 🔧 Tələblər

- ✅ PostgreSQL server işləməlidir
- ✅ Database "ayiqsurucu" mövcud olmalıdır
- ✅ .env faylında DATABASE_URL düzgün təyin edilməlidir
- ✅ Node.js və npm quraşdırılmış olmalıdır

## 📝 .env Faylı Nümunəsi

```env
DATABASE_URL=postgresql://postgres:password@localhost:5432/ayiqsurucu
JWT_SECRET=your-secret-key
PORT=3000
```

## 🔒 Təhlükəsizlik

⚠️ **Vacib**: İstehsal mühitində default şifrələri dəyişdirin!

```sql
-- Şifrələri dəyişdirmək üçün SQL
UPDATE users SET password = '$2a$10$newHashedPassword' WHERE username = 'admin';
```

## 🐛 Problemlər

### PostgreSQL Bağlantı Xətası
```
ConnectionRefusedError: connect ECONNREFUSED 127.0.0.1:5432
```

**Həll yolları:**
1. PostgreSQL serveri başladın
2. Port 5432 açıq olduğunu yoxlayın
3. DATABASE_URL düzgün olduğunu yoxlayın
4. Database mövcud olduğunu yoxlayın

### İstifadəçi Artıq Mövcuddur
```
User "admin" already exists. Skipping...
```

Bu normaldır - script mövcud istifadəçiləri atlayır.

## 📞 Dəstək

Problemlər üçün:
1. PostgreSQL loglarını yoxlayın
2. Database bağlantısını test edin
3. .env faylını yoxlayın
4. Node.js versiyasını yoxlayın

## 🎉 Uğurlu Quraşdırma

Script uğurla tamamlandıqdan sonra:

1. **Operator Panel**-də giriş edin
2. **Admin** hesabı ilə sistem parametrlərini konfiqurasiya edin
3. **Dispatcher** hesabı ilə sifarişləri idarə edin
4. **Operator** hesabı ilə gündəlik əməliyyatları yerinə yetirin

---

**Qeyd**: Bu script yalnız development/test mühiti üçündür. İstehsal mühitində təhlükəsizlik tədbirlərini gözləyin!
