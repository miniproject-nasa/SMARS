const Task = require("../models/Task");
const Note = require("../models/Note");
const Contact = require("../models/Contact");
const Profile = require("../models/Profile");
const User = require("../models/User");
const {
  syncTaskEmbedding,
  syncNoteEmbedding,
  deleteSourceEmbedding,
} = require("../services/ragService");

const cloudinary = require("cloudinary").v2;
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const getActualUserId = async (req) => {

  // If caregiver, use linked patient ID
  if (req.user.role === "caregiver") {

    const patient = await User.findOne({
      username: req.user.patientUsername,
    });

    if (patient) {
      return patient._id;
    }
  }

  // Otherwise normal patient
  return req.user.id;
};

// --- TASKS ---
exports.getTasks = async (req, res) => {
  try {
    if (req.query.date) {
      const startOfDay = new Date(req.query.date);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(req.query.date);
      endOfDay.setHours(23, 59, 59, 999);
      const tasks = await Task.find({
        userId: await getActualUserId(req),
        date: { $gte: startOfDay, $lte: endOfDay },
      });
      return res.json(tasks);
    }
    const tasks = await Task.find({ userId: await getActualUserId(req) }).sort({ date: 1 });
    res.json(tasks);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.createTask = async (req, res) => {
  try {
    const payload = { ...req.body, userId: await getActualUserId(req) };

    const task = new Task(payload);
    await task.save();

    await syncTaskEmbedding(task, await getActualUserId(req));

    res.status(201).json(task);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.toggleTask = async (req, res) => {
  try {
    const task = await Task.findOne({ _id: req.params.id, userId: await getActualUserId(req) });
    if (!task) {
      return res.status(404).json({ error: "Task not found" });
    }

    task.done = !task.done;
    await task.save();

    await syncTaskEmbedding(task, await getActualUserId(req));

    res.json(task);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 🟢 NEW: UPDATE TASK
exports.updateTask = async (req, res) => {
  try {
    const task = await Task.findOneAndUpdate(
      { _id: req.params.id, userId: await getActualUserId(req) },
      req.body,
      {
      new: true,
      },
    );

    if (!task) {
      return res.status(404).json({ error: "Task not found" });
    }

    await syncTaskEmbedding(task, await getActualUserId(req));

    res.json(task);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 🟢 NEW: DELETE TASK
exports.deleteTask = async (req, res) => {
  try {
    const task = await Task.findOneAndDelete({ _id: req.params.id, userId: await getActualUserId(req) });
    if (!task) {
      return res.status(404).json({ error: "Task not found" });
    }

    await deleteSourceEmbedding(await getActualUserId(req), "task", task._id);

    res.json({ message: "Task deleted" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// --- PROFILE DETAILS ---
// 🟢 UPDATED: Query User directly instead of Profile
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(await getActualUserId(req)).select("-password");
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Return user profile data
    res.json({
      patientId: user.patientId,
      name: user.fullName,
      mobile: user.mobile,
      dob: user.dateOfBirth,
      address: user.address,
      aadhar: user.aadhar,
      profilePicUrl: user.profilePicUrl,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 🟢 UPDATED: Upload profile picture with multipart handling - Fixed for web
exports.updateProfile = async (req, res) => {
  try {
    const updateData = {};

    // Update text fields if provided
    if (req.body.name) updateData.fullName = req.body.name;
    if (req.body.mobile) updateData.mobile = req.body.mobile;
    if (req.body.dob) updateData.dateOfBirth = req.body.dob;
    if (req.body.address) updateData.address = req.body.address;
    if (req.body.aadhar) updateData.aadhar = req.body.aadhar;

    // Handle profile picture upload
    if (req.file) {
      try {
        const uploadedImageUrl = await new Promise((resolve, reject) => {
          // 🟢 FIXED: Pass explicit timestamp to bypass stale clock issues
          const timestamp = Math.floor(Date.now() / 1000);
          const stream = cloudinary.uploader.upload_stream(
            {
              folder: "smars_profiles",
              resource_type: "auto",
              timestamp: timestamp,
              transformation: [
                { width: 300, height: 300, crop: "fill", gravity: "face" },
              ],
            },
            (error, result) => {
              if (error) {
                console.error("Cloudinary upload error:", error);
                reject(error);
              } else {
                resolve(result.secure_url);
              }
            },
          );
          stream.end(req.file.buffer);
        });
        updateData.profilePicUrl = uploadedImageUrl;
      } catch (uploadError) {
        console.error("Profile picture upload failed:", uploadError);
        return res.status(500).json({
          error: "Failed to upload profile picture: " + uploadError.message,
        });
      }
    }

    // Update user with new data
    const updatedUser = await User.findByIdAndUpdate(
      await getActualUserId(req),
      { $set: updateData },
      { new: true, runValidators: true },
    ).select("-password");

    if (!updatedUser) {
      return res.status(404).json({ error: "User not found" });
    }

    // Return updated profile
    res.json({
      patientId: updatedUser.patientId,
      name: updatedUser.fullName,
      mobile: updatedUser.mobile,
      dob: updatedUser.dateOfBirth,
      address: updatedUser.address,
      aadhar: updatedUser.aadhar,
      profilePicUrl: updatedUser.profilePicUrl,
    });
  } catch (error) {
    console.error("Update profile error:", error);
    res
      .status(500)
      .json({ error: error.message || "Failed to update profile" });
  }
};

// --- NOTES & CONTACTS ---
exports.getNotes = async (req, res) =>
  res.json(await Note.find({ userId: await getActualUserId(req) }).sort({ createdAt: -1 }));

// 🟢 UPDATED: CREATE NOTE WITH IMAGE
exports.createNote = async (req, res) => {
  try {
    let uploadedImageUrl = null;
    if (req.file) {
      uploadedImageUrl = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          { folder: "smars_notes" },
          (error, result) => {
            if (error) reject(error);
            else resolve(result.secure_url);
          },
        );
        stream.end(req.file.buffer);
      });
    }

    const baseData = {
      ...req.body,
      imageUrl: uploadedImageUrl,
      userId: await getActualUserId(req),
    };

    const note = await Note.create(baseData);

    await syncNoteEmbedding(note, await getActualUserId(req));

    res.status(201).json(note);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 🟢 UPDATED: UPDATE NOTE WITH IMAGE
exports.updateNote = async (req, res) => {
  try {
    let updateData = { ...req.body };
    if (req.file) {
      const uploadedImageUrl = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          { folder: "smars_notes" },
          (error, result) => {
            if (error) reject(error);
            else resolve(result.secure_url);
          },
        );
        stream.end(req.file.buffer);
      });
      updateData.imageUrl = uploadedImageUrl;
    }
    const note = await Note.findOneAndUpdate(
      { _id: req.params.id, userId: await getActualUserId(req) },
      updateData,
      {
        new: true,
      },
    );

    if (!note) {
      return res.status(404).json({ error: "Note not found" });
    }

    await syncNoteEmbedding(note, await getActualUserId(req));

    res.json(note);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteNote = async (req, res) => {
  try {
    const note = await Note.findOneAndDelete({ _id: req.params.id, userId: await getActualUserId(req) });
    if (!note) {
      return res.status(404).json({ error: "Note not found" });
    }

    await deleteSourceEmbedding(await getActualUserId(req), "note", note._id);

    res.json(note);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getContacts = async (req, res) =>
  res.json(await Contact.find({ userId: await getActualUserId(req) }));

// 🟢 NEW CREATE CONTACT WITH CLOUDINARY UPLOAD
exports.createContact = async (req, res) => {
  try {

    if (!req.files || req.files.length < 3) {
      return res.status(400).json({
        error: "At least 3 images required",
      });
    }

    const uploadedImages = [];

    for (const file of req.files) {

      const uploadedImageUrl =
        await new Promise((resolve, reject) => {

          const stream =
            cloudinary.uploader.upload_stream(
              { folder: "smars_contacts" },

              (error, result) => {
                if (error) reject(error);
                else resolve(result.secure_url);
              },
            );

          stream.end(file.buffer);
        });

      uploadedImages.push(uploadedImageUrl);
    }

    const contact = await Contact.create({
      ...req.body,
      images: uploadedImages,
      userId: await getActualUserId(req),
    });

    res.status(201).json(contact);

  } catch (error) {

    console.error("Cloudinary Upload Error:", error);

    res.status(500).json({
      error: error.message,
    });
  }
};

// 🟢 NEW: UPDATE CONTACT WITH CLOUDINARY UPLOAD
exports.updateContact = async (req, res) => {
  try {
    let updateData = { ...req.body };
    if (req.file) {
      const uploadedImageUrl = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          { folder: "smars_contacts" },
          (error, result) => {
            if (error) reject(error);
            else resolve(result.secure_url);
          },
        );
        stream.end(req.file.buffer);
      });
      updateData.imageUrl = uploadedImageUrl;
    }
    const contact = await Contact.findByIdAndUpdate(req.params.id, updateData, {
      new: true,
    });
    res.json(contact);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 🟢 NEW: DELETE CONTACT
exports.deleteContact = async (req, res) => {
  try {
    await Contact.findByIdAndDelete(req.params.id);
    res.json({ message: "Contact deleted" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
