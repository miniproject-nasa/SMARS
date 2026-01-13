const express = require('express');
const router = express.Router();

const {
  triggerSOS,
  getSOSStatus,
  updateLocation,
  getLocation,
} = require('../controllers/sos.controller');

router.post('/', triggerSOS);
router.get('/status', getSOSStatus);

// GPS routes
router.post('/location', updateLocation);
router.get('/location', getLocation);

module.exports = router;
