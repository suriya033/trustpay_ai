const mongoose = require("mongoose");

const transactionSchema = new mongoose.Schema(
  {
    receiptId: {
      type: String,
      required: true,
      unique: true,
    },
    projectId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Project",
      required: true,
    },
    projectTitle: {
      type: String,
      required: true,
    },
    milestoneId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
    },
    milestoneTitle: {
      type: String,
      required: true,
    },
    client: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    clientName: String,
    clientEmail: String,
    freelancer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    freelancerName: String,
    freelancerEmail: String,
    amount: {
      type: Number,
      required: true,
    },
    currency: {
      type: String,
      default: "USD",
    },
    paypalOrderId: {
      type: String,
      required: true,
    },
    paypalCaptureId: {
      type: String,
      required: true,
    },
    paymentStatus: {
      type: String,
      default: "COMPLETED",
    },
    isSandbox: {
      type: Boolean,
      default: true,
    },
    note: {
      type: String,
      default: "PayPal Sandbox Milestone Escrow Release",
    },
    paidAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Transaction", transactionSchema);
