const express = require("express");
const router = express.Router();
const dashboardController = require("../controllers/dashboardController");
const User = require("../models/User");

// 🟢 REQUIRE MULTER FOR FILE UPLOADS
const multer = require("multer");
const upload = multer({ storage: multer.memoryStorage() }); // Store in memory for direct Cloudinary upload

const requireAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res
        .status(401)
        .json({ message: "No authorization token provided" });
    }
    const token = authHeader.split(" ")[1];
    const user = await User.findOne({ token: token });
    if (!user) {
      return res.status(401).json({ message: "Invalid or expired token" });
    }
    req.user = { id: user._id };
    next();
  } catch (error) {
    res
      .status(500)
      .json({ message: "Authentication error", error: error.message });
  }
};

router.use(requireAuth);

router.get("/tasks", dashboardController.getTasks);
router.post("/tasks", dashboardController.createTask);
router.put("/tasks/:id/toggle", dashboardController.toggleTask);
// 🟢 NEW: Update and delete routes for tasks
router.put("/tasks/:id", dashboardController.updateTask);
router.delete("/tasks/:id", dashboardController.deleteTask);

// 🟢 UPDATED: Added multer for profile picture upload
router.get("/profile", dashboardController.getProfile);
router.put(
  "/profile",
  upload.single("profilePic"),
  dashboardController.updateProfile,
);

router.get("/notes", dashboardController.getNotes);
router.post("/notes", upload.single("photo"), dashboardController.createNote);
router.put(
  "/notes/:id",
  upload.single("photo"),
  dashboardController.updateNote,
);
router.delete("/notes/:id", dashboardController.deleteNote);

router.get("/contacts", dashboardController.getContacts);
router.post(
  "/contacts",
  upload.single("photo"),
  dashboardController.createContact,
);
// 🟢 NEW: Update and delete routes for contacts
router.put(
  "/contacts/:id",
  upload.single("photo"),
  dashboardController.updateContact,
);
router.delete("/contacts/:id", dashboardController.deleteContact);

module.exports = router;
