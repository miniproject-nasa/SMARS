const Contact = require("../models/Contact");

exports.createContact = async (req, res) => {

  try {

    const { name, relation, phone } = req.body;

    const images = req.files.map(file => ({
      url: `${req.protocol}://${req.get("host")}/${file.path}`
    }));

    const contact = new Contact({
      userId: req.user.id,
      name,
      relation,
      phone,
      images
    });

    await contact.save();

    res.json(contact);

  } catch (error) {

    res.status(500).json({
      error: error.message
    });

  }

};