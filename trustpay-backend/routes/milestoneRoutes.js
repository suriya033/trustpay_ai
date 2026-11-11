const express = require("express");
const mongoose = require("mongoose");
const Project = require("../models/Project");
const { authenticate, authorize } = require("../middleware/auth");
const {
  validate,
  submitWorkSchema,
  clientDecisionSchema,
} = require("../middleware/validators");
const geminiService = require("../services/geminiService");

const router = express.Router();

// Edit Milestone Details (Client only, before finalized or during negotiation)
router.put(
  "/:projectId/milestones/:milestoneId",
  authenticate,
  authorize("client"),
  async (req, res) => {
    try {
      const { projectId, milestoneId } = req.params;
      const {
        title,
        description,
        deliverables,
        acceptanceCriteria,
        amount,
        deadline,
        suggestedDuration,
      } = req.body;

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
          .json({ message: "Cannot edit an already paid milestone" });
      }

      if (title) milestone.title = title;
      if (description !== undefined) milestone.description = description;
      if (deliverables) milestone.deliverables = deliverables;
      if (acceptanceCriteria) milestone.acceptanceCriteria = acceptanceCriteria;
      if (amount !== undefined) milestone.amount = amount;
      if (deadline) milestone.deadline = new Date(deadline);
      if (suggestedDuration) milestone.suggestedDuration = suggestedDuration;

      // Recalculate total budget if amount changed
      const calculatedBudget = project.milestones.reduce(
        (sum, m) => sum + (m.amount || 0),
        0
      );
      project.totalBudget = parseFloat(calculatedBudget.toFixed(2));

      await project.save();
      res.json({ message: "Milestone updated successfully", milestone, project });
    } catch (err) {
      res.status(500).json({
        message: "Failed to update milestone",
        error: err.message,
      });
    }
  }
);

// Freelancer Submits Work Evidence
router.post(
  "/:projectId/milestones/:milestoneId/submit",
  authenticate,
  authorize("freelancer"),
  validate(submitWorkSchema),
  async (req, res) => {
    try {
      const { projectId, milestoneId } = req.params;
      const { description, githubUrl, liveDemoUrl, notes, evidenceFiles } =
        req.body;

      const project = await Project.findById(projectId);
      if (!project) {
        return res.status(404).json({ message: "Project not found" });
      }

      // Check freelancer authorization
      const isAssigned =
        (project.freelancer && project.freelancer.equals(req.user._id)) ||
        project.invitedFreelancerEmail === req.user.email;

      if (!isAssigned) {
        return res.status(403).json({
          message: "You are not assigned to submit work for this project",
        });
      }

      const milestone = project.milestones.id(milestoneId);
      if (!milestone) {
        return res.status(404).json({ message: "Milestone not found" });
      }

      if (milestone.status === "paid" || milestone.status === "approved") {
        return res
          .status(400)
          .json({ message: "Milestone is already approved/paid" });
      }

      const newVersion = (milestone.submissions?.length || 0) + 1;
      const newSubmission = {
        description,
        githubUrl: githubUrl || "",
        liveDemoUrl: liveDemoUrl || "",
        notes: notes || "",
        evidenceFiles: evidenceFiles || [],
        version: newVersion,
        submittedAt: new Date(),
      };

      milestone.submissions.push(newSubmission);
      milestone.status = "submitted";

      await project.save();

      res.status(201).json({
        message: "Work submitted successfully",
        submission: newSubmission,
        milestone,
      });
    } catch (err) {
      console.error("Submit Work Error:", err);
      res.status(500).json({
        message: "Failed to submit work",
        error: err.message,
      });
    }
  }
);

// Request Gemini AI Review for Submitted Work
router.post(
  "/:projectId/milestones/:milestoneId/ai-review",
  authenticate,
  async (req, res) => {
    try {
      const { projectId, milestoneId } = req.params;
      const project = await Project.findById(projectId);

      if (!project) {
        return res.status(404).json({ message: "Project not found" });
      }

      const milestone = project.milestones.id(milestoneId);
      if (!milestone) {
        return res.status(404).json({ message: "Milestone not found" });
      }

      if (!milestone.submissions || milestone.submissions.length === 0) {
        return res.status(400).json({
          message: "No submission found to review. Please submit work first.",
        });
      }

      // Get latest submission
      const latestSubmission =
        milestone.submissions[milestone.submissions.length - 1];

      milestone.status = "under_ai_review";
      await project.save();

      // Run Gemini verification against agreed acceptance criteria
      const reviewReport = await geminiService.reviewSubmission({
        milestoneTitle: milestone.title,
        milestoneDescription: milestone.description,
        deliverables: milestone.deliverables,
        acceptanceCriteria: milestone.acceptanceCriteria,
        submissionDescription: latestSubmission.description,
        githubUrl: latestSubmission.githubUrl,
        liveDemoUrl: latestSubmission.liveDemoUrl,
        notes: latestSubmission.notes,
        evidenceFiles: latestSubmission.evidenceFiles,
      });

      latestSubmission.aiReview = {
        reviewedAt: new Date(),
        score: reviewReport.score,
        passed: reviewReport.passed,
        criteriaChecks: reviewReport.criteriaChecks,
        deliverablesChecks: reviewReport.deliverablesChecks,
        identifiedRisks: reviewReport.identifiedRisks,
        recommendations: reviewReport.recommendations,
        verdict: reviewReport.verdict,
        summary: reviewReport.summary,
      };

      await project.save();

      res.json({
        message: "AI Review completed successfully",
        review: latestSubmission.aiReview,
        milestone,
      });
    } catch (err) {
      console.error("AI Review Error:", err);
      res.status(500).json({
        message: "Failed to generate AI review",
        error: err.message,
      });
    }
  }
);

// Client Decision: Approve or Request Revision (Client ONLY)
router.post(
  "/:projectId/milestones/:milestoneId/client-decision",
  authenticate,
  authorize("client"),
  validate(clientDecisionSchema),
  async (req, res) => {
    try {
      const { projectId, milestoneId } = req.params;
      const { decision, feedback } = req.body;

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
          .json({ message: "Milestone has already been paid" });
      }

      if (!milestone.submissions || milestone.submissions.length === 0) {
        return res.status(400).json({
          message: "Cannot make a decision on a milestone with no submissions",
        });
      }

      const latestSubmission =
        milestone.submissions[milestone.submissions.length - 1];

      latestSubmission.clientReview = {
        reviewedAt: new Date(),
        decision,
        feedback: feedback || "",
      };

      if (decision === "approved") {
        milestone.status = "approved"; // Ready for PayPal payment release!
      } else {
        milestone.status = "needs_revision";
      }

      await project.save();

      res.json({
        message:
          decision === "approved"
            ? "Milestone approved! You can now proceed to PayPal payment."
            : "Revision requested. Freelancer has been notified.",
        milestone,
      });
    } catch (err) {
      console.error("Client Decision Error:", err);
      res.status(500).json({
        message: "Failed to record decision",
        error: err.message,
      });
    }
  }
);

module.exports = router;
