require("dotenv").config(); // 🟢 THIS IS THE CRUCIAL MISSING LINE

const express = require("express");
const cors = require("cors");

const connectDB = require("./config/db");
const sosRoutes = require("./routes/sos.routes");
const authRoutes = require("./routes/auth.routes");
const dashboardRoutes = require("./routes/dashboard"); 

const app = express();
const PORT = process.env.PORT || 5000;

connectDB();

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

app.get("/", (req, res) => {
  res.send("SMARS Backend is running");
});

app.use("/api/sos", sosRoutes);
app.use("/api/auth", authRoutes);
app.use("/api", dashboardRoutes); 

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});