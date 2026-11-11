const mongoose = require("mongoose");

const submissionSchema = new mongoose.Schema({
  description: {
    type: String,
    required: true,
  },
  githubUrl: {
    type: String,
    default: "",
  },
  liveDemoUrl: {
    type: String,
    default: "",
  },
  evidenceFiles: [
    {
      name: String,
      url: String,
      fileType: String,
      size: Number,
    },
  ],
  notes: {
    type: String,
    default: "",
  },
  version: {
    type: Number,
    default: 1,
  },
  submittedAt: {
    type: Date,
    default: Date.now,
  },
  aiReview: {
    reviewedAt: Date,
    score: Number, // 0-100
    passed: Boolean,
    criteriaChecks: [
      {
        criterion: String,
        satisfied: Boolean,
        explanation: String,
      },
    ],
    deliverablesChecks: [
      {
        deliverable: String,
        satisfied: Boolean,
        explanation: String,
      },
    ],
    identifiedRisks: [String],
    recommendations: [String],
    verdict: {
      type: String,
      enum: ["PASSED", "NEEDS_IMPROVEMENT", "FAILED", ""],
      default: "",
    },
    summary: String,
  },
  clientReview: {
    reviewedAt: Date,
    decision: {
      type: String,
      enum: ["approved", "revision_requested", ""],
      default: "",
    },
    feedback: {
      type: String,
      default: "",
    },
  },
});

const milestoneSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      default: "",
    },
    deliverables: {
      type: [String],
      default: [],
    },
    acceptanceCriteria: {
      type: [String],
      default: [],
    },
    amount: {
      type: Number,
      required: true,
      min: 0,
    },
    currency: {
      type: String,
      default: "USD",
    },
    suggestedDuration: {
      type: String,
      default: "",
    },
    dependencies: {
      type: [String],
      default: [],
    },
    potentialRisks: {
      type: [String],
      default: [],
    },
    deadline: {
      type: Date,
    },
    status: {
      type: String,
      enum: [
        "pending",
        "in_progress",
        "submitted",
        "under_ai_review",
        "needs_revision",
        "approved",
        "payment_pending",
        "paid",
      ],
      default: "pending",
    },
    submissions: [submissionSchema],
    payment: {
      paypalOrderId: { type: String, default: "" },
      paypalCaptureId: { type: String, default: "" },
      paidAt: { type: Date },
      amount: { type: Number },
      currency: { type: String, default: "USD" },
      receiptId: { type: String, default: "" },
      status: { type: String, default: "" },
      payerEmail: { type: String, default: "" },
    },
  },
  { timestamps: true }
);

const projectSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
    },
    category: {
      type: String,
      default: "General",
    },
    currency: {
      type: String,
      default: "USD",
    },
    totalBudget: {
      type: Number,
      required: true,
      min: 0,
    },
    duration: {
      type: String,
      default: "2-4 weeks",
    },
    deadline: {
      type: Date,
    },
    technicalRequirements: {
      type: String,
      default: "",
    },
    additionalInstructions: {
      type: String,
      default: "",
    },
    client: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    freelancer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },
    invitedFreelancerEmail: {
      type: String,
      default: "",
    },
    status: {
      type: String,
      enum: [
        "draft",
        "pending_agreement",
        "active",
        "completed",
        "cancelled",
      ],
      default: "pending_agreement",
    },
    agreement: {
      terms: {
        type: String,
        default:
          "Mutual Freelance Agreement: Milestones are funded, verified against stated acceptance criteria, and released transparently via PayPal upon approval.",
      },
      clientAccepted: {
        type: Boolean,
        default: true,
      },
      clientAcceptedAt: {
        type: Date,
        default: Date.now,
      },
      freelancerAccepted: {
        type: Boolean,
        default: false,
      },
      freelancerAcceptedAt: {
        type: Date,
        default: null,
      },
      freelancerChangeRequest: {
        type: String,
        default: "",
      },
      acceptedSnapshot: {
        type: mongoose.Schema.Types.Mixed,
        default: null,
      },
    },
    milestones: {
      type: [milestoneSchema],
      default: [],
    },
  },
  { timestamps: true }
);

// Virtual to calculate total progress
projectSchema.virtual("progress").get(function () {
  if (!this.milestones || this.milestones.length === 0) return 0;
  const completed = this.milestones.filter((m) => m.status === "paid").length;
  return Math.round((completed / this.milestones.length) * 100);
});

projectSchema.set("toJSON", { virtuals: true });
projectSchema.set("toObject", { virtuals: true });

module.exports = mongoose.model("Project", projectSchema);
