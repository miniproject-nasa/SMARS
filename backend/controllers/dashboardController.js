const Task = require('../models/Task');
const Note = require('../models/Note');
const Contact = require('../models/Contact');
const Profile = require('../models/Profile');

const cloudinary = require('cloudinary').v2;
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// --- TASKS ---
exports.getTasks = async (req, res) => {
  try {
    if (req.query.date) {
      const startOfDay = new Date(req.query.date);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(req.query.date);
      endOfDay.setHours(23, 59, 59, 999);
      const tasks = await Task.find({ userId: req.user.id, date: { $gte: startOfDay, $lte: endOfDay } });
      return res.json(tasks);
    }
    const tasks = await Task.find({ userId: req.user.id }).sort({ date: 1 });
    res.json(tasks);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.createTask = async (req, res) => {
  try {
    const task = new Task({ ...req.body, userId: req.user.id });
    await task.save();
    res.status(201).json(task);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.toggleTask = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    task.done = !task.done;
    await task.save();
    res.json(task);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// --- PROFILE DETAILS ---
exports.getProfile = async (req, res) => {
  try {
    let profile = await Profile.findOne({ userId: req.user.id });
    if (!profile) profile = await Profile.create({ userId: req.user.id });
    res.json(profile);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const profile = await Profile.findOneAndUpdate(
      { userId: req.user.id },
      { $set: req.body },
      { new: true, upsert: true }
    );
    res.json(profile);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// --- NOTES & CONTACTS ---
exports.getNotes = async (req, res) => res.json(await Note.find({ userId: req.user.id }).sort({ createdAt: -1 }));

// 🟢 UPDATED: CREATE NOTE WITH IMAGE
exports.createNote = async (req, res) => {
  try {
    let uploadedImageUrl = null;
    if (req.file) {
      uploadedImageUrl = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream({ folder: 'smars_notes' }, (error, result) => {
          if (error) reject(error); else resolve(result.secure_url);
        });
        stream.end(req.file.buffer);
      });
    }
    const note = await Note.create({ ...req.body, imageUrl: uploadedImageUrl, userId: req.user.id });
    res.status(201).json(note);
  } catch (error) { res.status(500).json({ error: error.message }); }
};

// 🟢 UPDATED: UPDATE NOTE WITH IMAGE
exports.updateNote = async (req, res) => {
  try {
    let updateData = { ...req.body };
    if (req.file) {
      const uploadedImageUrl = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream({ folder: 'smars_notes' }, (error, result) => {
          if (error) reject(error); else resolve(result.secure_url);
        });
        stream.end(req.file.buffer);
      });
      updateData.imageUrl = uploadedImageUrl;
    }
    const note = await Note.findByIdAndUpdate(req.params.id, updateData, { new: true });
    res.json(note);
  } catch (error) { res.status(500).json({ error: error.message }); }
};

exports.deleteNote = async (req, res) => res.json(await Note.findByIdAndDelete(req.params.id));

exports.getContacts = async (req, res) => res.json(await Contact.find({ userId: req.user.id }));

// 🟢 NEW CREATE CONTACT WITH CLOUDINARY UPLOAD
exports.createContact = async (req, res) => {
  try {
    let uploadedImageUrl = null;

    // Check if an image was uploaded in the request
    if (req.file) {
      // Upload buffer directly to Cloudinary via stream
      uploadedImageUrl = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          { folder: 'smars_contacts' }, // Optional: puts them in a specific folder on Cloudinary
          (error, result) => {
            if (error) reject(error);
            else resolve(result.secure_url);
          }
        );
        stream.end(req.file.buffer);
      });
    }

    // Save contact to database with the Cloudinary URL
    const contact = await Contact.create({ 
      ...req.body, 
      imageUrl: uploadedImageUrl, 
      userId: req.user.id 
    });

    res.status(201).json(contact);
  } catch (error) {
    console.error("Cloudinary Upload Error:", error);
    res.status(500).json({ error: error.message });
  }
};