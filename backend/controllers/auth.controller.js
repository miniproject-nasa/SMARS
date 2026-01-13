const bcrypt = require('bcryptjs');
const User = require('../models/User');

/* =========================
   👤 PATIENT REGISTRATION
   ========================= */
exports.registerPatient = async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    const existingUser = await User.findOne({ username });

    if (existingUser) {
      return res.status(409).json({ message: 'Username already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const patient = new User({
      username,
      password: hashedPassword,
      role: 'patient',
    });

    await patient.save();

    res.status(201).json({
      message: 'Patient registered successfully',
      username: patient.username,
      role: patient.role,
    });
  } catch (err) {
    res.status(500).json({ message: 'Patient registration failed' });
  }
};

/* =========================
   👩‍⚕️ CAREGIVER REGISTRATION
   ========================= */
exports.registerCaregiver = async (req, res) => {
  try {
    const { username, password, patientUsername } = req.body;

    if (!username || !password || !patientUsername) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    // Check patient exists
    const patient = await User.findOne({
      username: patientUsername,
      role: 'patient',
    });

    if (!patient) {
      return res.status(404).json({ message: 'Patient not found' });
    }

    // Check caregiver username unique
    const existingUser = await User.findOne({ username });

    if (existingUser) {
      return res.status(409).json({ message: 'Username already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const caregiver = new User({
      username,
      password: hashedPassword,
      role: 'caregiver',
      patientUsername,
    });

    await caregiver.save();

    res.status(201).json({
      message: 'Caregiver registered successfully',
      username: caregiver.username,
      role: caregiver.role,
      patientUsername: caregiver.patientUsername,
    });
  } catch (err) {
    res.status(500).json({ message: 'Caregiver registration failed' });
  }
};

/* =========================
   🔐 LOGIN (unchanged)
   ========================= */
exports.login = async (req, res) => {
  try {
    const { username, password } = req.body;

    const user = await User.findOne({ username });

    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    res.json({
      username: user.username,
      role: user.role,
      patientUsername: user.patientUsername,
    });
  } catch (err) {
    res.status(500).json({ message: 'Login failed' });
  }
};
