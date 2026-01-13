const SOS = require('../models/SOS');
const Location = require('../models/Location');

// 🚨 TRIGGER SOS
exports.triggerSOS = async (req, res) => {
  try {
    const { patientId } = req.body;

    const sos = new SOS({
      patientId,
      active: true,
    });

    await sos.save();

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
