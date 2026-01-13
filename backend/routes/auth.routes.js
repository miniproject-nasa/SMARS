const express = require('express');
const router = express.Router();

const {
  registerPatient,
  registerCaregiver,
  login,
} = require('../controllers/auth.controller');

router.post('/register/patient', registerPatient);
router.post('/register/caregiver', registerCaregiver);
router.post('/login', login);

module.exports = router;
