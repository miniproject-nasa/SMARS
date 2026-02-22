/**
 * Validation for caregiver signup: username, password, dateOfBirth, patientToken, mobile, otp
 * Coerces all values to string so numeric JSON values (e.g. mobile, otp) still pass.
 */
const validateCaregiverSignup = (req, res, next) => {
  req.body = req.body || {};
  const raw = req.body;

  const username = String(raw.username != null ? raw.username : '').trim();
  const password = String(raw.password != null ? raw.password : '').trim();
  const dateOfBirth = String(raw.dateOfBirth != null ? raw.dateOfBirth : '').trim();
  const patientToken = String(raw.patientToken != null ? raw.patientToken : '').trim();
  const mobile = String(raw.mobile != null ? raw.mobile : '').trim();
  const otp = String(raw.otp != null ? raw.otp : '').trim();

  const errors = [];

  if (!username) errors.push('Username is required');
  if (!password) errors.push('Password is required');
  else if (password.length < 6) errors.push('Password must be at least 6 characters');
  if (!dateOfBirth) errors.push('Date of birth is required');
  if (!patientToken) errors.push('Patient token is required');
  if (!mobile) errors.push('Mobile number is required');
  if (!otp) errors.push('OTP is required');

  if (errors.length > 0) {
    const receivedKeys = Object.keys(raw).filter((k) => raw[k] !== undefined && raw[k] !== null);
    const hint = receivedKeys.length === 0
      ? ' (Server received empty body – check that the app sends JSON in the request body.)'
      : ` (Server received keys: ${receivedKeys.join(', ')})`;
    return res.status(400).json({ message: errors.join('; ') + hint });
  }

  req.body.username = username;
  req.body.password = password;
  req.body.dateOfBirth = dateOfBirth;
  req.body.patientToken = patientToken;
  req.body.mobile = mobile;
  req.body.otp = otp;
  next();
};

module.exports = { validateCaregiverSignup };
