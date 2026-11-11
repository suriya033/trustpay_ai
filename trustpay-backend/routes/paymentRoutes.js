const express = require("express");
const crypto = require("crypto");
const mongoose = require("mongoose");
const Project = require("../models/Project");
const Transaction = require("../models/Transaction");
const { authenticate, authorize } = require("../middleware/auth");
const paypalService = require("../services/paypalService");

const router = express.Router();

// 1. Create PayPal Order for Approved Milestone (Client only)
router.post(
  "/:projectId/milestones/:milestoneId/create-paypal-order",
  authenticate,
  authorize("client"),
  async (req, res) => {
    try {
      const { projectId, milestoneId } = req.params;

      const project = await Project.findOne({
        _id: projectId,
        client: req.user._id,
      });

      if (!project) {
        return res.status(404).json({ message: "Project not found" });
      }

      const milestone = project.milestones.id(milestoneId);
      if (!milestone) {
        return res.status(404).json({ message: "Milestone not found" });
      }

      if (milestone.status === "paid") {
        return res
          .status(400)
          .json({ message: "This milestone has already been paid" });
      }

      if (milestone.status !== "approved") {
        return res.status(400).json({
          message:
            "Milestone must be approved before releasing PayPal payment",
        });
      }

      const order = await paypalService.createOrder({
        amount: milestone.amount,
        currency: milestone.currency || "USD",
        description: `TrustPay AI Escrow: ${project.title} - ${milestone.title}`,
        referenceId: milestone._id.toString(),
      });

      milestone.payment.paypalOrderId = order.id;
      milestone.payment.amount = milestone.amount;
      milestone.payment.currency = milestone.currency || "USD";
      milestone.payment.status = "ORDER_CREATED";
      milestone.status = "payment_pending";

      await project.save();

      res.json({
        message: "PayPal Sandbox Order created successfully",
        orderId: order.id,
        status: order.status,
        isSandbox: order.isSandbox,
        isSimulated: order.isSimulated,
        approveUrl: order.links?.[0]?.href || "",
        amount: milestone.amount,
        currency: milestone.currency,
      });
    } catch (err) {
      console.error("Create PayPal Order Error:", err);
      res.status(500).json({
        message: "Failed to create PayPal order",
        error: err.message,
      });
    }
  }
);

// 2. Capture PayPal Payment (Client only)
router.post(
  "/:projectId/milestones/:milestoneId/capture-paypal-order",
  authenticate,
  authorize("client"),
  async (req, res) => {
    try {
      const { projectId, milestoneId } = req.params;
      const { orderId } = req.body;

      const project = await Project.findOne({
        _id: projectId,
        client: req.user._id,
      }).populate("client freelancer", "name email");

      if (!project) {
        return res.status(404).json({ message: "Project not found" });
      }

      const milestone = project.milestones.id(milestoneId);
      if (!milestone) {
        return res.status(404).json({ message: "Milestone not found" });
      }

      if (milestone.status === "paid") {
        return res.status(400).json({
          message: "Milestone is already marked as paid",
          payment: milestone.payment,
        });
      }

      const activeOrderId = orderId || milestone.payment.paypalOrderId;
      if (!activeOrderId) {
        return res.status(400).json({
          message: "No active PayPal Order ID found for this milestone",
        });
      }

      // Server-side verification & capture
      const captureResult = await paypalService.captureOrder(activeOrderId);

      if (captureResult.status !== "COMPLETED") {
        return res.status(400).json({
          message: `PayPal capture status is ${captureResult.status}`,
          captureResult,
        });
      }

      // Generate verifiable receipt ID
      const receiptId =
        "TP-REC-" +
        new Date().getFullYear() +
        "-" +
        crypto.randomBytes(4).toString("hex").toUpperCase();

      // Update Milestone
      milestone.status = "paid";
      milestone.payment = {
        paypalOrderId: activeOrderId,
        paypalCaptureId: captureResult.captureId,
        paidAt: new Date(),
        amount: milestone.amount,
        currency: milestone.currency || "USD",
        receiptId,
        status: "COMPLETED",
        payerEmail: req.user.email,
      };

      // Unlock next pending milestone
      const currentIndex = project.milestones.findIndex((m) =>
        m._id.equals(milestoneId)
      );
      if (
        currentIndex !== -1 &&
        currentIndex + 1 < project.milestones.length &&
        project.milestones[currentIndex + 1].status === "pending"
      ) {
        project.milestones[currentIndex + 1].status = "in_progress";
      }

      // If all milestones paid, mark project complete
      const allPaid = project.milestones.every((m) => m.status === "paid");
      if (allPaid) {
        project.status = "completed";
      }

      await project.save();

      // Create permanent transaction record
      const transaction = new Transaction({
        receiptId,
        projectId: project._id,
        projectTitle: project.title,
        milestoneId: milestone._id,
        milestoneTitle: milestone.title,
        client: project.client._id,
        clientName: project.client.name,
        clientEmail: project.client.email,
        freelancer: project.freelancer ? project.freelancer._id : req.user._id,
        freelancerName: project.freelancer
          ? project.freelancer.name
          : "Assigned Freelancer",
        freelancerEmail: project.freelancer
          ? project.freelancer.email
          : project.invitedFreelancerEmail || "freelancer@trustpay.ai",
        amount: milestone.amount,
        currency: milestone.currency || "USD",
        paypalOrderId: activeOrderId,
        paypalCaptureId: captureResult.captureId,
        paymentStatus: "COMPLETED",
        isSandbox: true,
        paidAt: new Date(),
      });

      await transaction.save();

      res.json({
        message: "Payment captured successfully! Milestone paid.",
        receiptId,
        transaction,
        milestone,
        project,
      });
    } catch (err) {
      console.error("Capture PayPal Order Error:", err);
      res.status(500).json({
        message: "Failed to capture PayPal payment",
        error: err.message,
      });
    }
  }
);

// 3. Get User's Transactions & Receipts
router.get("/transactions", authenticate, async (req, res) => {
  try {
    const query =
      req.user.role === "client"
        ? { client: req.user._id }
        : { freelancer: req.user._id };

    const transactions = await Transaction.find(query).sort({ paidAt: -1 });
    res.json(transactions);
  } catch (err) {
    res.status(500).json({
      message: "Failed to fetch transactions",
      error: err.message,
    });
  }
});

// 4. Get Single Receipt
router.get("/transactions/:id/receipt", authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    let transaction = null;

    if (mongoose.isValidObjectId(id)) {
      transaction = await Transaction.findById(id);
    } else {
      transaction = await Transaction.findOne({ receiptId: id });
    }

    if (!transaction) {
      return res.status(404).json({ message: "Receipt not found" });
    }

    res.json(transaction);
  } catch (err) {
    res.status(500).json({
      message: "Failed to fetch receipt",
      error: err.message,
    });
  }
});

module.exports = router;
