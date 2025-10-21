// In-memory OTP storage (production-da Redis istifadə edilməlidir)
const otpStorage = new Map();

const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

const sendOTP = async (phoneNumber, otp) => {
  try {
    // Development üçün console-a yazdır
    console.log(`📱 OTP göndərildi: ${phoneNumber} - Kod: ${otp}`);
    console.log(`💬 Mesaj: Peregon hayda tətbiqi üçün OTP kodunuz: ${otp}. Kod 5 dəqiqə ərzində etibarlıdır.`);
    
    // Production-da burada SMS göndərmə servisi əlavə edilə bilər
    // Məsələn: AWS SNS, MessageBird, və ya başqa SMS provider

    return {
      success: true,
      messageId: `dev_${Date.now()}`
    };
  } catch (error) {
    console.error('OTP göndərilmə xətası:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

const storeOTP = (phoneNumber, otp) => {
  const expiryTime = Date.now() + 5 * 60 * 1000; // 5 dəqiqə
  otpStorage.set(phoneNumber, {
    otp,
    expiryTime
  });
  
  console.log(`💾 OTP saxlanıldı: ${phoneNumber} - Vaxt: ${new Date(expiryTime).toLocaleString()}`);
};

const verifyOTP = (phoneNumber, otp) => {
  const storedData = otpStorage.get(phoneNumber);
  
  if (!storedData) {
    console.log(`❌ OTP tapılmadı: ${phoneNumber}`);
    return { valid: false, message: 'OTP tapılmadı' };
  }

  if (Date.now() > storedData.expiryTime) {
    otpStorage.delete(phoneNumber);
    console.log(`⏰ OTP vaxtı keçib: ${phoneNumber}`);
    return { valid: false, message: 'OTP vaxtı keçib' };
  }

  if (storedData.otp !== otp) {
    console.log(`❌ Yanlış OTP: ${phoneNumber} - Göndərilən: ${otp}, Saxlanılan: ${storedData.otp}`);
    return { valid: false, message: 'Yanlış OTP' };
  }

  // OTP uğurla yoxlandıqdan sonra sil
  otpStorage.delete(phoneNumber);
  console.log(`✅ OTP uğurla yoxlandı: ${phoneNumber}`);
  
  return { valid: true, message: 'OTP uğurla yoxlandı' };
};

const clearExpiredOTPs = () => {
  const now = Date.now();
  let clearedCount = 0;
  
  for (const [phoneNumber, data] of otpStorage.entries()) {
    if (now > data.expiryTime) {
      otpStorage.delete(phoneNumber);
      clearedCount++;
    }
  }
  
  if (clearedCount > 0) {
    console.log(`🧹 ${clearedCount} ədəd vaxtı keçmiş OTP təmizləndi`);
  }
};

// Hər 5 dəqiqədə bir vaxtı keçmiş OTP-ləri təmizlə
setInterval(clearExpiredOTPs, 5 * 60 * 1000);

module.exports = {
  generateOTP,
  sendOTP,
  storeOTP,
  verifyOTP
}; 