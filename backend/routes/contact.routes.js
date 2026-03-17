const express = require("express");
const router = express.Router();
const multer = require("multer");

const contactController = require("../controllers/contact.controller");

/// 🟢 MULTER STORAGE CONFIGURATION
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "uploads/faces");   // folder where images will be saved
  },
  filename: function (req, file, cb) {
    const uniqueName = Date.now() + "-" + file.originalname;
    cb(null, uniqueName);
  },
});

/// 🟢 MULTER INSTANCE
const upload = multer({ storage });

/// 🟢 CREATE CONTACT ROUTE
router.post(
  "/contacts",
  upload.array("images", 5),   // allow up to 5 images
  contactController.createContact
);

module.exports = router;