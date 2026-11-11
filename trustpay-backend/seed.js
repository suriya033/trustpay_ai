require("dotenv").config();
const mongoose = require("mongoose");
const User = require("./models/User");
const Project = require("./models/Project");
const Transaction = require("./models/Transaction");

async function seed() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected to MongoDB for seeding...");

    // Check if test users already exist
    let client = await User.findOne({ email: "client@trustpay.ai" });
    if (!client) {
      client = new User({
        name: "Sarah Jenkins",
        email: "client@trustpay.ai",
        password: "Password123!",
        role: "client",
        bio: "Product Director at FinTech Ventures. Building smart escrow and transparent milestone projects.",
        skills: ["Product Management", "Scrum", "Strategy"],
      });
      await client.save();
      console.log("Created demo Client: client@trustpay.ai / Password123!");
    }

    let freelancer = await User.findOne({ email: "freelancer@trustpay.ai" });
    if (!freelancer) {
      freelancer = new User({
        name: "Alex Rivera",
        email: "freelancer@trustpay.ai",
        password: "Password123!",
        role: "freelancer",
        bio: "Senior Full Stack & AI Mobile Developer specializing in Flutter, Node.js, and PayPal integrations.",
        skills: ["Flutter", "Dart", "Node.js", "MongoDB", "Gemini AI", "PayPal REST"],
      });
      await freelancer.save();
      console.log("Created demo Freelancer: freelancer@trustpay.ai / Password123!");
    }

    // Check if a demo project exists
    const existingProject = await Project.findOne({ client: client._id });
    if (!existingProject) {
      const demoProject = new Project({
        title: "TrustPay AI Mobile App MVP",
        description:
          "Development of the complete cross-platform mobile application and secure Node.js backend for AI milestone validation and PayPal Sandbox payments.",
        category: "Mobile & AI Development",
        currency: "USD",
        totalBudget: 1500,
        duration: "4 weeks",
        deadline: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        technicalRequirements:
          "Flutter Material 3 mobile app, Node.js REST API with JWT, MongoDB Atlas, PayPal Orders v2 sandbox, and Google Gemini 1.5 Flash review.",
        additionalInstructions:
          "Ensure clean code architecture, integer currency calculations, and responsive fintech design system.",
        client: client._id,
        freelancer: freelancer._id,
        invitedFreelancerEmail: freelancer.email,
        status: "active",
        agreement: {
          terms:
            "TrustPay Standard Freelance Agreement: Milestones are funded in escrow, verified against stated acceptance criteria by Google Gemini AI, and released via PayPal Sandbox upon client approval.",
          clientAccepted: true,
          clientAcceptedAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
          freelancerAccepted: true,
          freelancerAcceptedAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
          acceptedSnapshot: {
            terms: "TrustPay Standard Agreement",
            totalBudget: 1500,
            currency: "USD",
            client: client._id,
            freelancer: freelancer._id,
          },
        },
        milestones: [
          {
            title: "Milestone 1: UI/UX Architecture & Design System",
            description: "Finalize fintech design tokens, navigation wireframes, and theme setup.",
            deliverables: [
              "Figma high-fidelity interactive flow",
              "Material 3 theme configuration in Flutter",
              "App skeleton screens",
            ],
            acceptanceCriteria: [
              "Teal primary color (#008C82) with high contrast",
              "Responsive across Android devices",
              "Clean typography and iconography",
            ],
            amount: 400,
            currency: "USD",
            suggestedDuration: "1 week",
            dependencies: ["Project kickoff"],
            potentialRisks: ["Device fragmentation"],
            status: "paid",
            submissions: [
              {
                description: "Delivered Figma system and full Flutter Material 3 widget library.",
                githubUrl: "https://github.com/example/trustpay-ui",
                liveDemoUrl: "https://trustpay-demo.web.app",
                notes: "Tested on Pixel 7 and Samsung S23 viewports.",
                version: 1,
                submittedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
                aiReview: {
                  reviewedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
                  score: 95,
                  passed: true,
                  verdict: "PASSED",
                  summary: "Milestone 1 deliverables fully satisfy agreed design tokens and theme specifications.",
                  criteriaChecks: [
                    { criterion: "Teal primary color (#008C82)", satisfied: true, explanation: "Correct hex used in theme." },
                    { criterion: "Responsive layout", satisfied: true, explanation: "Tested on multiple viewports." },
                  ],
                  deliverablesChecks: [
                    { deliverable: "Material 3 theme", satisfied: true, explanation: "ThemeData configured." },
                  ],
                  identifiedRisks: ["None identified."],
                  recommendations: ["Maintain component modularity in Phase 2."],
                },
                clientReview: {
                  reviewedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
                  decision: "approved",
                  feedback: "Great work! Design looks sleek and professional.",
                },
              },
            ],
            payment: {
              paypalOrderId: "PAYPAL-ORD-TEST-001",
              paypalCaptureId: "CAPTURE-SB-9912",
              paidAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
              amount: 400,
              currency: "USD",
              receiptId: "TP-REC-2026-0001",
              status: "COMPLETED",
              payerEmail: client.email,
            },
          },
          {
            title: "Milestone 2: Backend REST APIs & Gemini AI Integration",
            description: "Implement Express auth, rate limiting, MongoDB models, and Gemini AI verification.",
            deliverables: [
              "JWT auth with refresh rotation",
              "Google Gemini structured milestone generation",
              "AI work audit engine",
            ],
            acceptanceCriteria: [
              "Passwords hashed with bcrypt",
              "Milestone totals match project budget exactly in minor currency units",
              "Zero unhandled exceptions on invalid input",
            ],
            amount: 500,
            currency: "USD",
            suggestedDuration: "1 week",
            dependencies: ["Milestone 1 approved"],
            potentialRisks: ["AI prompt hallucination"],
            status: "approved",
            submissions: [
              {
                description: "Completed full backend server with Gemini 1.5 Flash endpoints and PayPal Orders v2.",
                githubUrl: "https://github.com/example/trustpay-backend",
                liveDemoUrl: "https://trustpay-api.onrender.com",
                notes: "Includes test suite and rate limiters.",
                version: 1,
                submittedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
                aiReview: {
                  reviewedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
                  score: 92,
                  passed: true,
                  verdict: "PASSED",
                  summary: "Backend implementation successfully satisfies all security, database, and AI audit acceptance criteria.",
                  criteriaChecks: [
                    { criterion: "Passwords hashed with bcrypt", satisfied: true, explanation: "Salt factor 10 verified." },
                    { criterion: "Budget matching", satisfied: true, explanation: "Cent-based balance algorithm implemented." },
                  ],
                  deliverablesChecks: [
                    { deliverable: "Gemini milestone generator", satisfied: true, explanation: "Structured JSON response active." },
                  ],
                  identifiedRisks: ["Monitor Gemini API rate limits in high concurrency."],
                  recommendations: ["Keep caching enabled for common project categories."],
                },
                clientReview: {
                  reviewedAt: new Date(Date.now() - 12 * 60 * 60 * 1000),
                  decision: "approved",
                  feedback: "Ready for PayPal payment release!",
                },
              },
            ],
            payment: {
              status: "ORDER_CREATED",
              amount: 500,
              currency: "USD",
            },
          },
          {
            title: "Milestone 3: PayPal Sandbox Integration & Milestone Escrow",
            description: "Integrate PayPal Orders v2 API with server-side capture and receipt generator.",
            deliverables: [
              "PayPal Sandbox OAuth2 flow",
              "Client-side checkout modal & trigger",
              "Tamper-proof receipt generation",
            ],
            acceptanceCriteria: [
              "Capture verified on backend before marking milestone paid",
              "Receipt numbers unique and formatted TP-REC-YYYY-XXXX",
              "Clear test transaction labeling",
            ],
            amount: 350,
            currency: "USD",
            suggestedDuration: "1 week",
            dependencies: ["Milestone 2 approved"],
            potentialRisks: ["PayPal webhook latency"],
            status: "in_progress",
            submissions: [],
          },
          {
            title: "Milestone 4: End-to-End Testing & APK Deployment",
            description: "End-to-end integration tests, edge cases, error states, and APK release.",
            deliverables: [
              "Release Android APK",
              "Comprehensive README setup guide",
              "PayPal Hackathon presentation walkthrough",
            ],
            acceptanceCriteria: [
              "Zero crash reports across all critical user journeys",
              "Smooth offline graceful degradation",
            ],
            amount: 250,
            currency: "USD",
            suggestedDuration: "1 week",
            dependencies: ["Milestone 3 approved"],
            potentialRisks: ["Release signing credentials"],
            status: "pending",
            submissions: [],
          },
        ],
      });

      await demoProject.save();

      // Create matching transaction for Milestone 1
      const transaction = new Transaction({
        receiptId: "TP-REC-2026-0001",
        projectId: demoProject._id,
        projectTitle: demoProject.title,
        milestoneId: demoProject.milestones[0]._id,
        milestoneTitle: demoProject.milestones[0].title,
        client: client._id,
        clientName: client.name,
        clientEmail: client.email,
        freelancer: freelancer._id,
        freelancerName: freelancer.name,
        freelancerEmail: freelancer.email,
        amount: 400,
        currency: "USD",
        paypalOrderId: "PAYPAL-ORD-TEST-001",
        paypalCaptureId: "CAPTURE-SB-9912",
        paymentStatus: "COMPLETED",
        isSandbox: true,
        note: "PayPal Sandbox Milestone Escrow Release - Phase 1 UI/UX",
        paidAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
      });

      await transaction.save();
      console.log("Created demo Project and Transaction records!");
    }

    console.log("Seeding completed successfully!");
    process.exit(0);
  } catch (err) {
    console.error("Seeding error:", err);
    process.exit(1);
  }
}

seed();
