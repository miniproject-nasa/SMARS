const SOS =
  require('../models/SOS');

const Location =
  require('../models/Location');

const User =
  require('../models/User');

const Caregiver =
  require('../models/Caregiver');

const admin =
  require('../config/firebaseAdmin');

// 🚨 TRIGGER SOS
exports.triggerSOS = async (req, res) => {
  try {
    const { patientId } = req.body;

    console.log(
      "PATIENT ID:",
      patientId,
    );

    const sos = new SOS({
      patientId,
      active: true,
    });

    await sos.save();

    // Get patient details
    const patient =
      await User.findOne({
        patientId,
      });

      console.log(
        "PATIENT:",
        patient?.fullName,
      );

    // Find linked caregivers
    const caregivers =
      await Caregiver.find({
        patientId,
        fcmToken: {
          $ne: null,
        },
      });

      console.log(
        "CAREGIVERS FOUND:",
        caregivers.length,
      );

      console.log(
        caregivers,
      );

    // Send notification
    for (const caregiver
        of caregivers) {

      try {

        console.log(
          "SENDING TO:",
          caregiver.username,
        );

        await admin
          .messaging()
          .send({

            token:
              caregiver.fcmToken,

            notification: {
              title:
                "🚨 SOS Emergency Alert",

              body:
                `${patient?.fullName ?? "Patient"} needs help`,
            },

            android: {
              priority:
                "high",

              notification: {
                sound:
                  "default",

                priority:
                  "max",
              },
            },

            data: {
              type:
                "sos",
            },
          });

        console.log(
          "🚨 SOS notification sent"
        );

      } catch (err) {

        console.error(
          "FCM ERROR:",
          err.message,
        );
      }
    }

    console.log('🚨 SOS SAVED TO DB');

    res.status(200).json({
      success: true,
      message: 'SOS received and saved',
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to save SOS' });
  }
};

// 🚨 GET LATEST SOS STATUS
exports.getSOSStatus = async (req, res) => {
  try {
    const sos = await SOS.findOne().sort({ timestamp: -1 });

    if (!sos) {
      return res.json({
        active: false,
      });
    }

    res.json({
      active: sos.active,
      patientId: sos.patientId,
      timestamp: sos.timestamp,
    });
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch SOS status' });
  }
};

// 📍 UPDATE LOCATION
exports.updateLocation = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;

    const location = new Location({
      latitude,
      longitude,
    });

    await location.save();

    console.log('📍 LOCATION SAVED TO DB');

    res.status(200).json({
      success: true,
      message: 'Location updated',
    });
  } catch (err) {
    res.status(500).json({ message: 'Failed to save location' });
  }
};

// 📍 GET LATEST LOCATION
exports.getLocation = async (req, res) => {
  try {
    const location = await Location.findOne().sort({ updatedAt: -1 });

    if (!location) {
      return res.json({});
    }

    res.json({
      latitude: location.latitude,
      longitude: location.longitude,
      updatedAt: location.updatedAt,
    });
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch location' });
  }
};

exports.resetSOS = async (req, res) => {
  try {
    const sos = await SOS.findOne().sort({
      timestamp: -1,
    });

    if (!sos) {
      return res.status(404).json({
        message: 'No SOS found',
      });
    }

    sos.active = false;

    await sos.save();

    res.json({
      success: true,
      message: 'SOS reset successfully',
    });

  } catch (err) {
    res.status(500).json({
      message: 'Failed to reset SOS',
    });
  }
};