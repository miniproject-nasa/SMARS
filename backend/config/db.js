const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    await mongoose.connect(
      process.env.MONGODB_URI ||
        'mongodb+srv://amalkrishnatuttu2004:anhsirklama@amal.ruludza.mongodb.net/smars'
    );
    console.log('✅ MongoDB connected');
  } catch (err) {
    console.error('❌ MongoDB connection failed');
    process.exit(1);
  }
};

module.exports = connectDB;