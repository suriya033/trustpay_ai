const express = require("express");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const User = require("../models/User");
const { authenticate } = require("../middleware/auth");
const {
  validate,
  registerSchema,
  loginSchema,
} = require("../middleware/validators");
const { authLimiter } = require("../middleware/rateLimiter");

const router = express.Router();

const generateTokens = (user) => {
  const accessToken = jwt.sign(
    { id: user._id, role: user.role, email: user.email },
    process.env.JWT_SECRET || "default_jwt_secret",
    { expiresIn: process.env.JWT_EXPIRES_IN || "7d" }
  );

  const refreshToken = jwt.sign(
    { id: user._id },
    process.env.JWT_REFRESH_SECRET || "default_refresh_secret",
    { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || "30d" }
  );

  return { accessToken, refreshToken };
};

// Register
router.post("/register", authLimiter, validate(registerSchema), async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(400).json({ message: "Email is already registered" });
    }

    const user = new User({
      name,
      email,
      password,
      role: role || "client",
    });

    const { accessToken, refreshToken } = generateTokens(user);
    user.refreshToken = refreshToken;
    await user.save();

    res.status(201).json({
      message: "User registered successfully",
      user: user.toSafeJSON(),
      accessToken,
      refreshToken,
    });
  } catch (err) {
    console.error("Register error:", err);
    res.status(500).json({ message: "Registration failed", error: err.message });
  }
});

// Login
router.post("/login", authLimiter, validate(loginSchema), async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    const { accessToken, refreshToken } = generateTokens(user);
    user.refreshToken = refreshToken;
    await user.save();

    res.json({
      message: "Login successful",
      user: user.toSafeJSON(),
      accessToken,
      refreshToken,
    });
  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ message: "Login failed", error: err.message });
  }
});

// Refresh Token
router.post("/refresh-token", async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ message: "Refresh token is required" });
    }

    const decoded = jwt.verify(
      refreshToken,
      process.env.JWT_REFRESH_SECRET || "default_refresh_secret"
    );

    const user = await User.findById(decoded.id);
    if (!user || user.refreshToken !== refreshToken) {
      return res.status(401).json({ message: "Invalid or expired refresh token" });
    }

    const tokens = generateTokens(user);
    user.refreshToken = tokens.refreshToken;
    await user.save();

    res.json({
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    });
  } catch (err) {
    res.status(401).json({ message: "Invalid refresh token", error: err.message });
  }
});

// Forgot Password
router.post("/forgot-password", authLimiter, async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(200).json({
        message: "If an account with this email exists, a reset code was generated.",
      });
    }

    const resetToken = crypto.randomBytes(3).toString("hex").toUpperCase();
    user.resetPasswordToken = resetToken;
    user.resetPasswordExpires = Date.now() + 3600000; // 1 hour
    await user.save();

    res.json({
      message: "Reset code generated",
      resetCode: resetToken, // returned for development/demo ease
    });
  } catch (err) {
    res.status(500).json({ message: "Failed to process forgot password", error: err.message });
  }
});

// Reset Password
router.post("/reset-password", authLimiter, async (req, res) => {
  try {
    const { email, resetCode, newPassword } = req.body;
    const user = await User.findOne({
      email,
      resetPasswordToken: resetCode,
      resetPasswordExpires: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({ message: "Invalid or expired reset code" });
    }

    user.password = newPassword;
    user.resetPasswordToken = null;
    user.resetPasswordExpires = null;
    await user.save();

    res.json({ message: "Password reset successfully. You can now log in." });
  } catch (err) {
    res.status(500).json({ message: "Failed to reset password", error: err.message });
  }
});

// Current User Profile
router.get("/me", authenticate, async (req, res) => {
  res.json({ user: req.user.toSafeJSON() });
});

// Update Profile
router.put("/profile", authenticate, async (req, res) => {
  try {
    const { name, bio, skills, avatar } = req.body;
    if (name) req.user.name = name;
    if (bio !== undefined) req.user.bio = bio;
    if (skills !== undefined) req.user.skills = skills;
    if (avatar !== undefined) req.user.avatar = avatar;

    await req.user.save();
    res.json({ message: "Profile updated", user: req.user.toSafeJSON() });
  } catch (err) {
    res.status(500).json({ message: "Failed to update profile", error: err.message });
  }
});

// List Freelancers (for project invitation)
router.get("/freelancers", authenticate, async (req, res) => {
  try {
    const freelancers = await User.find({ role: "freelancer" })
      .select("name email avatar bio skills")
      .limit(50);
    res.json(freelancers);
  } catch (err) {
    res.status(500).json({ message: "Failed to fetch freelancers", error: err.message });
  }
});

// Logout
router.post("/logout", authenticate, async (req, res) => {
  try {
    req.user.refreshToken = null;
    await req.user.save();
    res.json({ message: "Logged out successfully" });
  } catch (err) {
    res.status(500).json({ message: "Logout failed" });
  }
});

module.exports = router;
