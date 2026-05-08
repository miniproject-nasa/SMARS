const User = require("../models/User");

exports.getPatientProfileForCaregiver = async (req, res) => {
  try {
    const { username } = req.params;

    const patient = await User.findOne({
      username,
      role: "patient",
    });

    if (!patient) {
      return res.status(404).json({
        message: "Patient not found",
      });
    }

    res.json({
      name: patient.fullName || "",
      mobile: patient.mobile || "",
      dob: patient.dateOfBirth || "",
      aadhar: patient.aadhar || "",
      address: patient.address || "",
      patientId: patient.patientId || "",
      profilePicUrl: patient.profilePicUrl || "",
    });

  } catch (err) {
    res.status(500).json({
      message: "Failed to fetch patient profile",
    });
  }
};

exports.updatePatientProfileForCaregiver = async (req, res) => {
  try {
    const { username } = req.params;

    const updated = await User.findOneAndUpdate(
      {
        username,
        role: "patient",
      },
      {
        fullName: req.body.name,
        mobile: req.body.mobile,
        dateOfBirth: req.body.dob,
        aadhar: req.body.aadhar,
        address: req.body.address,
      },
      {
        new: true,
      }
    );

    if (!updated) {
      return res.status(404).json({
        message: "Patient not found",
      });
    }

    res.json({
      success: true,
      message: "Patient profile updated",
    });

  } catch (err) {
    res.status(500).json({
      message: "Failed to update patient profile",
    });
  }
};