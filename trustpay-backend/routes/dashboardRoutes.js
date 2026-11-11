const express = require("express");
const Project = require("../models/Project");
const Transaction = require("../models/Transaction");
const { authenticate, authorize } = require("../middleware/auth");

const router = express.Router();

// Client Dashboard Stats
router.get("/client-stats", authenticate, authorize("client"), async (req, res) => {
  try {
    const projects = await Project.find({ client: req.user._id }).sort({
      updatedAt: -1,
    });

    const totalProjects = projects.length;
    const activeProjects = projects.filter((p) => p.status === "active").length;
    const completedProjects = projects.filter(
      (p) => p.status === "completed"
    ).length;

    let totalProjectBudget = 0;
    let approvedMilestoneValue = 0;
    let pendingApprovals = 0;

    const recentActivities = [];

    projects.forEach((p) => {
      totalProjectBudget += p.totalBudget || 0;
      p.milestones.forEach((m) => {
        if (m.status === "approved" || m.status === "paid") {
          approvedMilestoneValue += m.amount || 0;
        }
        if (m.status === "submitted" || m.status === "under_ai_review") {
          pendingApprovals++;
          recentActivities.push({
            type: "SUBMISSION",
            projectTitle: p.title,
            milestoneTitle: m.title,
            amount: m.amount,
            status: m.status,
            date: m.updatedAt || p.updatedAt,
          });
        }
      });
    });

    // Completed sandbox payments
    const transactions = await Transaction.find({ client: req.user._id }).sort({
      paidAt: -1,
    });

    const completedSandboxPayments = transactions.reduce(
      (sum, t) => sum + (t.amount || 0),
      0
    );

    transactions.slice(0, 5).forEach((t) => {
      recentActivities.push({
        type: "PAYMENT",
        projectTitle: t.projectTitle,
        milestoneTitle: t.milestoneTitle,
        amount: t.amount,
        status: "PAID",
        receiptId: t.receiptId,
        date: t.paidAt,
      });
    });

    // Sort recent activities by date desc
    recentActivities.sort((a, b) => new Date(b.date) - new Date(a.date));

    res.json({
      totalProjects,
      activeProjects,
      completedProjects,
      pendingApprovals,
      totalProjectBudget: parseFloat(totalProjectBudget.toFixed(2)),
      approvedMilestoneValue: parseFloat(approvedMilestoneValue.toFixed(2)),
      completedSandboxPayments: parseFloat(completedSandboxPayments.toFixed(2)),
      isSandbox: true,
      recentActivities: recentActivities.slice(0, 10),
    });
  } catch (err) {
    console.error("Client Stats Error:", err);
    res.status(500).json({
      message: "Failed to fetch client statistics",
      error: err.message,
    });
  }
});

// Freelancer Dashboard Stats
router.get(
  "/freelancer-stats",
  authenticate,
  authorize("freelancer"),
  async (req, res) => {
    try {
      const projects = await Project.find({
        $or: [
          { freelancer: req.user._id },
          { invitedFreelancerEmail: req.user.email },
        ],
      }).sort({ updatedAt: -1 });

      const assignedProjects = projects.length;
      let activeMilestones = 0;
      let pendingSubmissions = 0;
      let revisionRequests = 0;
      let approvedWork = 0;
      const upcomingDeadlines = [];

      projects.forEach((p) => {
        p.milestones.forEach((m) => {
          if (m.status === "in_progress") {
            activeMilestones++;
            pendingSubmissions++;
            if (m.deadline) {
              upcomingDeadlines.push({
                projectTitle: p.title,
                milestoneTitle: m.title,
                deadline: m.deadline,
                amount: m.amount,
              });
            }
          } else if (m.status === "needs_revision") {
            revisionRequests++;
          } else if (m.status === "approved" || m.status === "paid") {
            approvedWork++;
          }
        });
      });

      // Total earnings in Sandbox
      const transactions = await Transaction.find({
        freelancer: req.user._id,
      }).sort({ paidAt: -1 });

      const totalPaidSandboxTransactionValue = transactions.reduce(
        (sum, t) => sum + (t.amount || 0),
        0
      );

      const recentNotifications = [];
      if (revisionRequests > 0) {
        recentNotifications.push({
          title: "Revision Required",
          message: `You have ${revisionRequests} milestone(s) awaiting revisions.`,
          type: "warning",
        });
      }
      if (activeMilestones > 0) {
        recentNotifications.push({
          title: "Active Work in Progress",
          message: `${activeMilestones} milestone(s) are actively awaiting your submission.`,
          type: "info",
        });
      }
      if (transactions.length > 0) {
        recentNotifications.push({
          title: "Milestone Paid via PayPal Sandbox",
          message: `Latest payment of $${transactions[0].amount} received for "${transactions[0].milestoneTitle}".`,
          type: "success",
        });
      }

      res.json({
        assignedProjects,
        activeMilestones,
        pendingSubmissions,
        revisionRequests,
        approvedWork,
        totalPaidSandboxTransactionValue: parseFloat(
          totalPaidSandboxTransactionValue.toFixed(2)
        ),
        isSandbox: true,
        upcomingDeadlines: upcomingDeadlines.slice(0, 5),
        paymentHistory: transactions.slice(0, 10),
        recentNotifications,
      });
    } catch (err) {
      console.error("Freelancer Stats Error:", err);
      res.status(500).json({
        message: "Failed to fetch freelancer statistics",
        error: err.message,
      });
    }
  }
);

module.exports = router;
