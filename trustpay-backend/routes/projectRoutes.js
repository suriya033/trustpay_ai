const express = require("express");
const mongoose = require("mongoose");
const Project = require("../models/Project");
const User = require("../models/User");
const { authenticate, authorize } = require("../middleware/auth");
const {
  validate,
  createProjectSchema,
} = require("../middleware/validators");

const router = express.Router();

// Create Project (Client only)
router.post(
  "/",
  authenticate,
  authorize("client"),
  validate(createProjectSchema),
  async (req, res) => {
    try {
      const {
        title,
        description,
        category,
        currency,
        totalBudget,
        duration,
        deadline,
        technicalRequirements,
        additionalInstructions,
        invitedFreelancerEmail,
        milestones,
      } = req.body;

      // Find freelancer by email if provided
      let freelancerId = null;
      if (invitedFreelancerEmail) {
        const found = await User.findOne({
          email: invitedFreelancerEmail.toLowerCase(),
          role: "freelancer",
        });
        if (found) {
          freelancerId = found._id;
        }
      }

      // Format milestones
      const formattedMilestones = (milestones || []).map((m, idx) => ({
        ...m,
        status: idx === 0 ? "in_progress" : "pending",
        submissions: [],
      }));

      const project = new Project({
        title,
        description,
        category,
        currency,
        totalBudget,
        duration,
        deadline: deadline ? new Date(deadline) : null,
        technicalRequirements,
        additionalInstructions,
        client: req.user._id,
        freelancer: freelancerId,
        invitedFreelancerEmail: invitedFreelancerEmail || "",
        status: "pending_agreement",
        agreement: {
          terms: `Mutual Freelance Milestone Contract between Client (${req.user.name}) and assigned Freelancer for project: ${title}. Total Budget: ${totalBudget} ${currency}. Payments released upon acceptance criteria verification.`,
          clientAccepted: true,
          clientAcceptedAt: new Date(),
          freelancerAccepted: false,
        },
        milestones: formattedMilestones,
      });

      await project.save();
      await project.populate("client freelancer", "name email avatar");

      res.status(201).json(project);
    } catch (err) {
      console.error("Create Project Error:", err);
      res.status(500).json({
        message: "Failed to create project",
        error: err.message,
      });
    }
  }
);

// Get User's Projects (Filtered by role and status)
router.get("/", authenticate, async (req, res) => {
  try {
    const { status, filter } = req.query;
    let query = {};

    if (req.user.role === "client") {
      query.client = req.user._id;
    } else {
      // Freelancer sees assigned projects or invited by email
      query.$or = [
        { freelancer: req.user._id },
        { invitedFreelancerEmail: req.user.email },
      ];
    }

    if (status && status !== "all") {
      if (status === "active") {
        query.status = "active";
      } else if (status === "pending") {
        query.status = "pending_agreement";
      } else if (status === "completed") {
        query.status = "completed";
      }
    }

    const projects = await Project.find(query)
      .populate("client", "name email avatar")
      .populate("freelancer", "name email avatar")
      .sort({ createdAt: -1 });

    res.json(projects);
  } catch (err) {
    console.error("Get Projects Error:", err);
    res.status(500).json({
      message: "Failed to fetch projects",
      error: err.message,
    });
  }
});

// Get Project Details
router.get("/:id", authenticate, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ message: "Invalid project ID" });
    }

    const project = await Project.findById(req.params.id)
      .populate("client", "name email avatar bio")
      .populate("freelancer", "name email avatar bio skills");

    if (!project) {
      return res.status(404).json({ message: "Project not found" });
    }

    // Check authorization: must be either the client or assigned freelancer
    const isClient = project.client._id.equals(req.user._id);
    const isFreelancer =
      (project.freelancer && project.freelancer._id.equals(req.user._id)) ||
      project.invitedFreelancerEmail === req.user.email;

    if (!isClient && !isFreelancer) {
      return res.status(403).json({
        message: "You are not authorized to view this project",
      });
    }

    res.json(project);
  } catch (err) {
    res.status(500).json({
      message: "Failed to fetch project details",
      error: err.message,
    });
  }
});

// Invite or Assign Freelancer
router.post(
  "/:id/invite-freelancer",
  authenticate,
  authorize("client"),
  async (req, res) => {
    try {
      const { freelancerId, email } = req.body;
      const project = await Project.findOne({
        _id: req.params.id,
        client: req.user._id,
      });

      if (!project) {
        return res.status(404).json({ message: "Project not found" });
      }

      let freelancer = null;
      if (freelancerId && mongoose.isValidObjectId(freelancerId)) {
        freelancer = await User.findById(freelancerId);
      } else if (email) {
        freelancer = await User.findOne({ email: email.toLowerCase() });
      }

      if (freelancer) {
        project.freelancer = freelancer._id;
        project.invitedFreelancerEmail = freelancer.email;
      } else if (email) {
        project.invitedFreelancerEmail = email.toLowerCase();
      } else {
        return res.status(400).json({ message: "Freelancer ID or email required" });
      }

      // Reset agreement for new freelancer
      project.agreement.freelancerAccepted = false;
      project.agreement.freelancerAcceptedAt = null;
      project.agreement.freelancerChangeRequest = "";
      project.status = "pending_agreement";

      await project.save();
      await project.populate("client freelancer", "name email avatar");

      res.json({
        message: "Freelancer invited successfully",
        project,
      });
    } catch (err) {
      res.status(500).json({
        message: "Failed to invite freelancer",
        error: err.message,
      });
    }
  }
);

// Freelancer Respond to Agreement (Accept or Request Changes)
router.post(
  "/:id/agreement/freelancer-respond",
  authenticate,
  authorize("freelancer"),
  async (req, res) => {
    try {
      const { action, changeRequest } = req.body; // action: 'accept' | 'request_changes'
      const project = await Project.findById(req.params.id);

      if (!project) {
        return res.status(404).json({ message: "Project not found" });
      }

      // Check if this freelancer is assigned
      const isAssigned =
        (project.freelancer && project.freelancer.equals(req.user._id)) ||
        project.invitedFreelancerEmail === req.user.email;

      if (!isAssigned) {
        return res.status(403).json({
          message: "You are not assigned to this project",
        });
      }

      // If freelancer wasn't explicitly linked by ID, link now
      if (!project.freelancer) {
        project.freelancer = req.user._id;
      }

      if (action === "accept") {
        project.agreement.freelancerAccepted = true;
        project.agreement.freelancerAcceptedAt = new Date();
        project.agreement.freelancerChangeRequest = "";
        project.status = "active";

        // Save immutable snapshot of agreement
        project.agreement.acceptedSnapshot = {
          terms: project.agreement.terms,
          totalBudget: project.totalBudget,
          currency: project.currency,
          milestones: project.milestones.map((m) => ({
            id: m._id,
            title: m.title,
            description: m.description,
            amount: m.amount,
            deliverables: m.deliverables,
            acceptanceCriteria: m.acceptanceCriteria,
          })),
          acceptedAt: new Date(),
          client: project.client,
          freelancer: req.user._id,
        };

        // Set first milestone to in_progress if pending
        if (project.milestones.length > 0 && project.milestones[0].status === "pending") {
          project.milestones[0].status = "in_progress";
        }
      } else if (action === "request_changes") {
        project.agreement.freelancerAccepted = false;
        project.agreement.freelancerChangeRequest =
          changeRequest || "Freelancer requested scope/budget adjustments.";
        project.status = "pending_agreement";
      } else {
        return res.status(400).json({ message: "Invalid action" });
      }

      await project.save();
      await project.populate("client freelancer", "name email avatar");

      res.json({
        message:
          action === "accept"
            ? "Agreement accepted! Project is now active."
            : "Change request submitted to client.",
        project,
      });
    } catch (err) {
      res.status(500).json({
        message: "Failed to respond to agreement",
        error: err.message,
      });
    }
  }
);

// Client Confirm Updated Agreement
router.post(
  "/:id/agreement/client-confirm",
  authenticate,
  authorize("client"),
  async (req, res) => {
    try {
      const { updatedTerms } = req.body;
      const project = await Project.findOne({
        _id: req.params.id,
        client: req.user._id,
      });

      if (!project) {
        return res.status(404).json({ message: "Project not found" });
      }

      if (updatedTerms) {
        project.agreement.terms = updatedTerms;
      }
      project.agreement.clientAccepted = true;
      project.agreement.clientAcceptedAt = new Date();
      project.agreement.freelancerChangeRequest = "";

      await project.save();
      await project.populate("client freelancer", "name email avatar");

      res.json({ message: "Agreement updated and confirmed by client", project });
    } catch (err) {
      res.status(500).json({
        message: "Failed to update agreement",
        error: err.message,
      });
    }
  }
);

module.exports = router;
