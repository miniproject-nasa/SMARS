const Contact = require("../models/Contact");

exports.createContact = async (req, res) => {

  try {

    console.log("FILES:", req.files);

    if (!req.files || req.files.length < 3) {
      return res.status(400).json({
        message: "At least 3 images required",
      });
    }

    const { name, relation, phone } = req.body;

    const images = req.files.map(file => ({
      url: `${req.protocol}://${req.get("host")}/${file.path}`,
    }));

    const contact = new Contact({
      userId: "temporary-user",
      name,
      relation,
      phone,
      images,
    });

    await contact.save();

    res.status(201).json(contact);

  } catch (error) {

    console.log(error);

    res.status(500).json({
      error: error.message,
    });

  }
};