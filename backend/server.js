const express = require('express');
const cors = require('cors');

const sosRoutes = require('./routes/sos.routes');

const app = express();
const PORT = 5000;

const connectDB = require('./config/db');
connectDB();

app.use(cors());
app.use(express.json());

// Routes
app.use('/api/sos', sosRoutes);

app.get('/', (req, res) => {
  res.send('SMARS Backend is running');
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});

const authRoutes = require('./routes/auth.routes');
app.use('/api/auth', authRoutes);

