require("dotenv").config();

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const mongoose = require("mongoose");

const { apiLimiter } = require("./middleware/rateLimiter");
const authRoutes = require("./routes/authRoutes");
const projectRoutes = require("./routes/projectRoutes");
const milestoneRoutes = require("./routes/milestoneRoutes");
const aiRoutes = require("./routes/aiRoutes");
const paymentRoutes = require("./routes/paymentRoutes");
const dashboardRoutes = require("./routes/dashboardRoutes");

const app = express();

// Security and middleware
app.use(helmet());
app.use(
  cors({
    origin: "*", // allow all client platforms in sandbox & mobile
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// Rate limiting
app.use("/api/", apiLimiter);

// Health check endpoint
app.get("/api/health", (req, res) => {
  res.json({
    status: "OK",
    application: "TrustPay AI",
    tagline: "Smart Milestones. Transparent Payments.",
    database:
      mongoose.connection.readyState === 1 ? "Connected" : "Disconnected",
    timestamp: new Date().toISOString(),
  });
});

// Mount Routes
app.use("/api/auth", authRoutes);
app.use("/api/projects", projectRoutes);
app.use("/api/projects", milestoneRoutes);
app.use("/api/ai", aiRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/dashboard", dashboardRoutes);

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ message: "Endpoint not found" });
});

// Centralized error handling
app.use((err, req, res, next) => {
  console.error("Unhandled Error:", err.stack);
  res.status(err.status || 500).json({
    message: err.message || "Internal server error",
    error: process.env.NODE_ENV === "production" ? {} : err,
  });
});

async function startServer() {
  try {
    if (!process.env.MONGO_URI) {
      throw new Error("MONGO_URI is missing in environment variables");
    }

    console.log("Connecting to MongoDB Atlas...");
    await mongoose.connect(process.env.MONGO_URI);
    console.log("MongoDB Atlas Connected Successfully!");

    const PORT = process.env.PORT || 3000;
    app.listen(PORT, "0.0.0.0", () => {
      console.log(`===============================================`);
      console.log(` TrustPay AI Backend Server Running on Port ${PORT} `);
      console.log(` PayPal Sandbox API & Gemini AI Integration Active `);
      console.log(`===============================================`);
    });
  } catch (error) {
    console.error("Server startup error:", error.message);
    process.exit(1);
  }
}

startServer();
