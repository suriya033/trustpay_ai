const { z } = require("zod");

const validate = (schema) => (req, res, next) => {
  try {
    req.body = schema.parse(req.body);
    next();
  } catch (error) {
    if (error instanceof z.ZodError) {
      const messages = error.issues.map((i) => `${i.path.join(".")}: ${i.message}`);
      return res.status(400).json({
        message: "Validation Error",
        errors: messages,
      });
    }
    return res.status(400).json({ message: "Invalid request payload" });
  }
};

const registerSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters"),
  email: z.string().email("Invalid email address"),
  password: z.string().min(6, "Password must be at least 6 characters"),
  role: z.enum(["client", "freelancer"]).default("client"),
});

const loginSchema = z.object({
  email: z.string().email("Invalid email address"),
  password: z.string().min(1, "Password is required"),
});

const createProjectSchema = z.object({
  title: z.string().min(3, "Title must be at least 3 characters"),
  description: z.string().min(10, "Description must be at least 10 characters"),
  category: z.string().optional().default("General"),
  currency: z.string().optional().default("USD"),
  totalBudget: z.number().positive("Total budget must be greater than 0"),
  duration: z.string().optional().default("2-4 weeks"),
  deadline: z.string().optional(),
  technicalRequirements: z.string().optional().default(""),
  additionalInstructions: z.string().optional().default(""),
  invitedFreelancerEmail: z.string().optional().default(""),
  milestones: z
    .array(
      z.object({
        title: z.string().min(2),
        description: z.string().optional().default(""),
        deliverables: z.array(z.string()).optional().default([]),
        acceptanceCriteria: z.array(z.string()).optional().default([]),
        amount: z.number().positive(),
        suggestedDuration: z.string().optional().default(""),
        dependencies: z.array(z.string()).optional().default([]),
        potentialRisks: z.array(z.string()).optional().default([]),
        deadline: z.string().optional(),
      })
    )
    .optional()
    .default([]),
});

const generateMilestonesSchema = z.object({
  title: z.string().min(3),
  description: z.string().min(10),
  category: z.string().optional().default("Software Development"),
  totalBudget: z.number().positive(),
  currency: z.string().optional().default("USD"),
  duration: z.string().optional().default("4 weeks"),
  technicalRequirements: z.string().optional().default(""),
  additionalInstructions: z.string().optional().default(""),
});

const submitWorkSchema = z.object({
  description: z.string().min(5, "Work description must be at least 5 characters"),
  githubUrl: z.string().url("Must be a valid URL").optional().or(z.literal("")),
  liveDemoUrl: z.string().url("Must be a valid URL").optional().or(z.literal("")),
  notes: z.string().optional().default(""),
  evidenceFiles: z
    .array(
      z.object({
        name: z.string(),
        url: z.string(),
        fileType: z.string().optional().default("link"),
      })
    )
    .optional()
    .default([]),
});

const clientDecisionSchema = z.object({
  decision: z.enum(["approved", "revision_requested"]),
  feedback: z.string().optional().default(""),
});

module.exports = {
  validate,
  registerSchema,
  loginSchema,
  createProjectSchema,
  generateMilestonesSchema,
  submitWorkSchema,
  clientDecisionSchema,
};
