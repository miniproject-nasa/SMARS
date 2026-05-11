const express = require("express");
const router = express.Router();

const {
  saveFCMToken,
} = require("../controllers/fcm.controller");

router.post("/save-token", saveFCMToken);

module.exports = router;