const express = require("express");
const { authenticate, authorize } = require("../middleware/auth");
const {
  validate,
  generateMilestonesSchema,
} = require("../middleware/validators");
const geminiService = require("../services/geminiService");

const router = express.Router();

// Generate Milestones via Gemini AI
router.post(
  "/generate-milestones",
  authenticate,
  authorize("client"),
  validate(generateMilestonesSchema),
  async (req, res) => {
    try {
      const {
        title,
        description,
        category,
        totalBudget,
        currency,
        duration,
        technicalRequirements,
        additionalInstructions,
      } = req.body;

      const milestones = await geminiService.generateMilestones({
        title,
        description,
        category,
        totalBudget,
        currency,
        duration,
        technicalRequirements,
        additionalInstructions,
      });

      res.json({
        success: true,
        projectSummary: {
          title,
          totalBudget,
          currency,
          milestonesCount: milestones.length,
        },
        milestones,
      });
    } catch (err) {
      console.error("AI Generate Milestones Error:", err);
      res.status(500).json({
        message: "Failed to generate milestones with AI",
        error: err.message,
      });
    }
  }
);

// General AI Work Review Endpoint
router.post("/review-submission", authenticate, async (req, res) => {
  try {
    const {
      milestoneTitle,
      milestoneDescription,
      deliverables,
      acceptanceCriteria,
      submissionDescription,
      githubUrl,
      liveDemoUrl,
      notes,
      evidenceFiles,
    } = req.body;

    if (!submissionDescription || !milestoneTitle) {
      return res.status(400).json({
        message: "Milestone title and submission description are required",
      });
    }

    const report = await geminiService.reviewSubmission({
      milestoneTitle,
      milestoneDescription,
      deliverables: deliverables || [],
      acceptanceCriteria: acceptanceCriteria || [],
      submissionDescription,
      githubUrl,
      liveDemoUrl,
      notes,
      evidenceFiles: evidenceFiles || [],
    });

    res.json({
      success: true,
      report,
    });
  } catch (err) {
    console.error("AI Review Submission Error:", err);
    res.status(500).json({
      message: "Failed to perform AI review",
      error: err.message,
    });
  }
});

module.exports = router;
