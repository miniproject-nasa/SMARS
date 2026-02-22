const crypto = require('crypto');

const OTP_EXPIRY_MS = 10 * 60 * 1000; // 10 minutes
const OTP_LENGTH = 6;

const otpStore = new Map();

function generateOTP() {
  const digits = '0123456789';
  let otp = '';
  for (let i = 0; i < OTP_LENGTH; i++) {
    otp += digits[crypto.randomInt(0, digits.length)];
  }
  return otp;
}

function generatePatientToken() {
  return crypto.randomBytes(6).toString('hex');
}

function setOTP(mobile, otp) {
  otpStore.set(mobile, {
    otp,
    expiresAt: Date.now() + OTP_EXPIRY_MS,
  });
}

function getOTP(mobile) {
  const entry = otpStore.get(mobile);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    otpStore.delete(mobile);
    return null;
  }
  return entry.otp;
}

function consumeOTP(mobile, otp) {
  const stored = getOTP(mobile);
  if (stored === null) return false;
  if (stored !== otp) return false;
  otpStore.delete(mobile);
  return true;
}

module.exports = {
  generateOTP,
  generatePatientToken,
  setOTP,
  getOTP,
  consumeOTP,
};
