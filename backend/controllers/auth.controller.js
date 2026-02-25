const bcrypt = require("bcryptjs");
const User = require("../models/User");
const Caregiver = require("../models/Caregiver");
const otpService = require("../services/otpService");

// 🟢 UTILITY: Generate unique patient ID
const generatePatientId = () => {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let patientId = "";
  for (let i = 0; i < 8; i++) {
    patientId += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return patientId;
};

/* =========================
   📱 SEND OTP (for patient signup) – generates OTP and returns it for app display
   ========================= */
exports.sendOtp = async (req, res) => {
  try {
    const { mobile } = req.body;
    if (!mobile || !String(mobile).trim()) {
      return res.status(400).json({ message: "Mobile number is required" });
    }
    const mobileStr = String(mobile).trim();
    const otp = otpService.generateOTP();
    otpService.setOTP(mobileStr, otp);

    const payload = { message: "OTP sent successfully" };
    if (process.env.NODE_ENV !== "production") {
      payload.otp = otp;
    }
    res.status(200).json(payload);
  } catch (err) {
    res.status(500).json({ message: "Failed to send OTP" });
  }
};

/* =========================
   👤 PATIENT REGISTRATION (validates OTP, then creates user with all profile data)
   ========================= */
exports.registerPatient = async (req, res) => {
  try {
    const { fullName, dateOfBirth, mobile, otp, password, address } = req.body;

    const username = mobile;
    const existingUser = await User.findOne({ username });

    if (existingUser) {
      return res
        .status(409)
        .json({ message: "This mobile number is already registered" });
    }

    const isValidOtp = otpService.consumeOTP(mobile, otp);
    if (!isValidOtp) {
      return res
        .status(400)
        .json({ message: "Invalid or expired OTP. Please request a new one." });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const token = otpService.generatePatientToken();

    // 🟢 UPDATED: Generate unique patient ID
    let patientId;
    let isUnique = false;
    while (!isUnique) {
      patientId = generatePatientId();
      const existing = await User.findOne({ patientId });
      if (!existing) isUnique = true;
    }

    // 🟢 UPDATED: Save everything in User - no separate Profile needed
    const patient = new User({
      username,
      password: hashedPassword,
      role: "patient",
      fullName,
      dateOfBirth,
      mobile,
      address,
      patientId,
      token,
    });

    await patient.save();

    res.status(201).json({
      message: "Patient registered successfully",
      username: patient.username,
      role: patient.role,
      token: patient.token,
      patientId,
    });
  } catch (err) {
    res
      .status(500)
      .json({ message: err.message || "Patient registration failed" });
  }
};

/* =========================
   👩‍⚕️ CAREGIVER REGISTRATION (OTP + valid patient token required)
   Stores all signup details in the Caregiver collection.
   ========================= */
exports.registerCaregiver = async (req, res) => {
  try {
    const { username, password, dateOfBirth, patientToken, mobile, otp } =
      req.body;

    const isValidOtp = otpService.consumeOTP(mobile, otp);
    if (!isValidOtp) {
      return res
        .status(400)
        .json({ message: "Invalid or expired OTP. Please request a new one." });
    }

    const patient = await User.findOne({
      role: "patient",
      token: patientToken,
    });
    if (!patient) {
      return res
        .status(400)
        .json({
          message:
            "Invalid patient token. Get the token from the patient you care for.",
        });
    }

    const existingByUsername = await Caregiver.findOne({ username });
    if (existingByUsername) {
      return res.status(409).json({ message: "Username already exists" });
    }

    const existingByMobile = await Caregiver.findOne({ mobile });
    if (existingByMobile) {
      return res
        .status(409)
        .json({
          message: "This mobile number is already registered as a caregiver",
        });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const caregiver = new Caregiver({
      username,
      password: hashedPassword,
      dateOfBirth,
      mobile,
      patientUsername: patient.username,
    });

    await caregiver.save();

    res.status(201).json({
      message: "Caregiver registered successfully",
      username: caregiver.username,
      role: "caregiver",
      patientUsername: caregiver.patientUsername,
    });
  } catch (err) {
    res
      .status(500)
      .json({ message: err.message || "Caregiver registration failed" });
  }
};

/* =========================
   🔐 LOGIN (patients from User, caregivers from Caregiver)
   ========================= */
exports.login = async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res
        .status(400)
        .json({ message: "Username and password are required" });
    }

    let payload = null;

    const user = await User.findOne({ username });
    const userByMobile = user ? null : await User.findOne({ mobile: username });
    const foundUser = user || userByMobile;

    if (foundUser) {
      const isMatch = await bcrypt.compare(password, foundUser.password);
      if (isMatch) {
        payload = {
          _id: foundUser._id.toString(),
          username: foundUser.username,
          role: foundUser.role,
          patientUsername: foundUser.patientUsername,
          mobile: foundUser.mobile || foundUser.username,
        };
        if (foundUser.token) payload.token = foundUser.token;
      }
    }

    if (!payload) {
      const caregiver = await Caregiver.findOne({ username });
      const caregiverByMobile = caregiver
        ? null
        : await Caregiver.findOne({ mobile: username });
      const foundCaregiver = caregiver || caregiverByMobile;

      if (foundCaregiver) {
        const isMatch = await bcrypt.compare(password, foundCaregiver.password);
        if (isMatch) {
          payload = {
            _id: foundCaregiver._id.toString(),
            username: foundCaregiver.username,
            role: "caregiver",
            patientUsername: foundCaregiver.patientUsername,
            mobile: foundCaregiver.mobile,
          };
        }
      }
    }

    if (!payload) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    res.json(payload);
  } catch (err) {
    res.status(500).json({ message: "Login failed" });
  }
};
