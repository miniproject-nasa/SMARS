const express = require('express');
const router = express.Router();

const {
  triggerSOS,
  getSOSStatus,
  updateLocation,
  getLocation,
  resetSOS,
} = require('../controllers/sos.controller');

router.post('/', triggerSOS);
router.get('/status', getSOSStatus);

// GPS routes
router.post('/location', updateLocation);
router.get('/location', getLocation);

router.put('/reset', resetSOS);

module.exports = router;
