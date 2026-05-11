const Caregiver = require("../models/Caregiver");

exports.saveFCMToken =
  async (req, res) => {
    try {

      const {
        username,
        token,
      } = req.body;

      await Caregiver.findOneAndUpdate(
        { username },
        { fcmToken: token }
      );

      console.log(
        "✅ FCM token saved"
      );

      res.json({
        success: true,
      });

    } catch (err) {

      console.error(err);

      res.status(500).json({
        message:
          "Failed to save token",
      });
    }
  };