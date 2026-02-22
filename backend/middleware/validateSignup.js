/**
 * Validation middleware for patient signup (Sign Up page).
 * Expects: fullName, dateOfBirth, mobile, otp, password
 * Coerces all values to string so numeric JSON values (e.g. mobile, otp) still pass.
 */
const validatePatientSignup = (req, res, next) => {
  const fullName = String(req.body.fullName ?? '').trim();
  const dateOfBirth = String(req.body.dateOfBirth ?? '').trim();
  const mobile = String(req.body.mobile ?? '').trim();
  const otp = String(req.body.otp ?? '').trim();
  const password = String(req.body.password ?? '').trim();

  const errors = [];

  if (!fullName) errors.push('Full name is required');
  if (!dateOfBirth) errors.push('Date of birth is required');
  if (!mobile) errors.push('Mobile number is required');
  if (!otp) errors.push('OTP is required');
  if (!password) errors.push('Password is required');
  else if (password.length < 6) errors.push('Password must be at least 6 characters');

  if (errors.length > 0) {
    return res.status(400).json({ message: errors.join('; ') });
  }

  req.body.fullName = fullName;
  req.body.dateOfBirth = dateOfBirth;
  req.body.mobile = mobile;
  req.body.otp = otp;
  req.body.password = password;
  next();
};

module.exports = { validatePatientSignup };
