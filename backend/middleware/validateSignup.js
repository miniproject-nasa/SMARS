/**
 * Validation middleware for patient signup (Sign Up page).
 * Expects: fullName, dateOfBirth, mobile, otp
 */
const validatePatientSignup = (req, res, next) => {
  const { fullName, dateOfBirth, mobile, otp } = req.body;
  const errors = [];

  if (!fullName || typeof fullName !== 'string' || !fullName.trim()) {
    errors.push('Full name is required');
  }
  if (!dateOfBirth || typeof dateOfBirth !== 'string' || !dateOfBirth.trim()) {
    errors.push('Date of birth is required');
  }
  if (!mobile || typeof mobile !== 'string' || !mobile.trim()) {
    errors.push('Mobile number is required');
  }
  if (!otp || typeof otp !== 'string' || !otp.trim()) {
    errors.push('OTP is required');
  }

  if (errors.length > 0) {
    return res.status(400).json({ message: errors.join('; ') });
  }

  req.body.fullName = req.body.fullName.trim();
  req.body.dateOfBirth = req.body.dateOfBirth.trim();
  req.body.mobile = req.body.mobile.trim();
  req.body.otp = req.body.otp.trim();
  next();
};

module.exports = { validatePatientSignup };
