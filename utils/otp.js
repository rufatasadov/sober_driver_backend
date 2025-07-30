const twilio = require('twilio');

const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

// In-memory OTP storage (production-da Redis istifadə edilməlidir)
const otpStorage = new Map();

const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

const sendOTP = async (phoneNumber, otp) => {
  try {
    const message = await client.messages.create({
      body: `Ayiq Sürücü tətbiqi üçün OTP kodunuz: ${otp}. Kod 5 dəqiqə ərzində etibarlıdır.`,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: phoneNumber
    });

    return {
      success: true,
      messageId: message.sid
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
};

const verifyOTP = (phoneNumber, otp) => {
  const storedData = otpStorage.get(phoneNumber);
  
  if (!storedData) {
    return { valid: false, message: 'OTP tapılmadı' };
  }

  if (Date.now() > storedData.expiryTime) {
    otpStorage.delete(phoneNumber);
    return { valid: false, message: 'OTP vaxtı keçib' };
  }

  if (storedData.otp !== otp) {
    return { valid: false, message: 'Yanlış OTP' };
  }

  // OTP uğurla yoxlandıqdan sonra sil
  otpStorage.delete(phoneNumber);
  
  return { valid: true, message: 'OTP uğurla yoxlandı' };
};

const clearExpiredOTPs = () => {
  const now = Date.now();
  for (const [phoneNumber, data] of otpStorage.entries()) {
    if (now > data.expiryTime) {
      otpStorage.delete(phoneNumber);
    }
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