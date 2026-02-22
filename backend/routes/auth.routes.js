const express = require('express');
const router = express.Router();

const {
  registerPatient,
  registerCaregiver,
  login,
} = require('../controllers/auth.controller');
const { validatePatientSignup } = require('../middleware/validateSignup');

router.post('/register/patient', validatePatientSignup, registerPatient);
router.post('/register/caregiver', registerCaregiver);
router.post('/login', login);

module.exports = router;
