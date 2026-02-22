const express = require('express');
const router = express.Router();

const {
  sendOtp,
  registerPatient,
  registerCaregiver,
  login,
} = require('../controllers/auth.controller');
const { validatePatientSignup } = require('../middleware/validateSignup');
const { validateCaregiverSignup } = require('../middleware/validateCaregiverSignup');

router.post('/otp/send', sendOtp);
router.post('/register/patient', validatePatientSignup, registerPatient);
router.post('/register/caregiver', validateCaregiverSignup, registerCaregiver);
router.post('/login', login);

module.exports = router;
