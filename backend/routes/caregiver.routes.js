const express = require("express");
const router = express.Router();

const {
  getPatientProfileForCaregiver,
  updatePatientProfileForCaregiver,
} = require("../controllers/caregiver.controller");

router.get("/patient-profile/:username", getPatientProfileForCaregiver);

router.put(
  "/patient-profile/:username",
  updatePatientProfileForCaregiver
);

module.exports = router;