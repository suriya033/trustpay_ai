require("dotenv").config();
const mongoose = require("mongoose");
const User = require("./models/User");
const Project = require("./models/Project");
const Transaction = require("./models/Transaction");
const paypalService = require("./services/paypalService");
const geminiService = require("./services/geminiService");

async function runTests() {
  console.log("=== STARTING TRUSTPAY AI FULL-STACK INTEGRATION TEST ===");

  try {
    // 1. Database Connection
    await mongoose.connect(process.env.MONGO_URI);
    console.log("✓ 1. MongoDB Atlas connected successfully.");

    // 2. User Authentication Model Verification
    const testEmail = `test_client_${Date.now()}@trustpay.ai`;
    const user = new User({
      name: "Fintech Test Client",
      email: testEmail,
      password: "TestPassword123!",
      role: "client",
    });
    await user.save();

    const isMatch = await user.comparePassword("TestPassword123!");
    if (!isMatch) throw new Error("Password hashing verification failed");
    console.log("✓ 2. User registration and bcrypt password hashing verified.");

    // 3. Google Gemini AI Milestone Generation & Budget Balancer
    console.log("Testing AI Milestone Generation...");
    const milestones = await geminiService.generateMilestones({
      title: "FinTech Automated Invoicing App",
      description: "Build an invoice tracking mobile app with automated receipt generation and payment tracking.",
      category: "FinTech & Mobile",
      totalBudget: 1200,
      currency: "USD",
      duration: "3 weeks",
    });

    if (!Array.isArray(milestones) || milestones.length === 0) {
      throw new Error("AI Milestone generation failed");
    }

    const totalAllocated = milestones.reduce((sum, m) => sum + m.amount, 0);
    const diff = Math.abs(totalAllocated - 1200);
    if (diff > 0.01) {
      throw new Error(`Budget balancing mismatch: allocated ${totalAllocated} vs target 1200`);
    }
    console.log(`✓ 3. Gemini AI generated ${milestones.length} milestones. Sum = $${totalAllocated} (Matches total budget exactly in minor units).`);

    // 4. Project Creation & Agreement
    const project = new Project({
      title: "E2E Test Contract",
      description: "Automated end-to-end test project for hackathon verification.",
      category: "Web Development",
      totalBudget: 1200,
      currency: "USD",
      client: user._id,
      milestones: milestones.map((m, idx) => ({
        ...m,
        status: idx === 0 ? "in_progress" : "pending",
      })),
      agreement: {
        terms: "Standard TrustPay AI Hackathon Escrow Terms",
        clientAccepted: true,
        freelancerAccepted: true,
      },
      status: "active",
    });
    await project.save();
    console.log("✓ 4. Project created and mutual agreement activated.");

    // 5. Work Submission
    const firstMilestone = project.milestones[0];
    firstMilestone.submissions.push({
      description: "Completed full architecture and initial deployment on Render with MongoDB Atlas integration.",
      githubUrl: "https://github.com/example/trustpay-verified",
      liveDemoUrl: "https://trustpay-demo.web.app",
      notes: "All test cases passing 100%.",
      version: 1,
      submittedAt: new Date(),
    });
    firstMilestone.status = "submitted";
    await project.save();
    console.log("✓ 5. Freelancer work submission recorded with GitHub & demo links.");

    // 6. Gemini AI Work Verification
    console.log("Running Gemini AI verification on submitted work...");
    const aiReview = await geminiService.reviewSubmission({
      milestoneTitle: firstMilestone.title,
      milestoneDescription: firstMilestone.description,
      deliverables: firstMilestone.deliverables,
      acceptanceCriteria: firstMilestone.acceptanceCriteria,
      submissionDescription: firstMilestone.submissions[0].description,
      githubUrl: firstMilestone.submissions[0].githubUrl,
      liveDemoUrl: firstMilestone.submissions[0].liveDemoUrl,
      notes: firstMilestone.submissions[0].notes,
    });

    if (!aiReview || typeof aiReview.score !== "number") {
      throw new Error("AI review report invalid");
    }

    firstMilestone.submissions[0].aiReview = aiReview;
    firstMilestone.status = "under_ai_review";
    await project.save();
    console.log(`✓ 6. Gemini AI verification complete. Score: ${aiReview.score}/100. Verdict: ${aiReview.verdict}.`);

    // 7. Client Approval
    firstMilestone.submissions[0].clientReview = {
      reviewedAt: new Date(),
      decision: "approved",
      feedback: "Verified against criteria. Approved for PayPal release.",
    };
    firstMilestone.status = "approved";
    await project.save();
    console.log("✓ 7. Client approved milestone based on AI verification audit.");

    // 8. PayPal Sandbox Order Creation (Orders v2)
    console.log("Creating PayPal Sandbox Order...");
    const paypalOrder = await paypalService.createOrder({
      amount: firstMilestone.amount,
      currency: "USD",
      description: `Escrow release: ${firstMilestone.title}`,
      referenceId: firstMilestone._id.toString(),
    });

    if (!paypalOrder.id) throw new Error("PayPal order creation failed");
    console.log(`✓ 8. PayPal Sandbox Order created: ${paypalOrder.id} (${paypalOrder.status}).`);

    // 9. PayPal Sandbox Capture & Receipt Issuance
    console.log("Capturing PayPal Sandbox Order...");
    const captureResult = await paypalService.captureOrder(paypalOrder.id);
    if (captureResult.status !== "COMPLETED") throw new Error("Capture failed");

    const receiptId = `TP-REC-${Date.now()}`;
    firstMilestone.status = "paid";
    firstMilestone.payment = {
      paypalOrderId: paypalOrder.id,
      paypalCaptureId: captureResult.captureId,
      paidAt: new Date(),
      amount: firstMilestone.amount,
      currency: "USD",
      receiptId,
      status: "COMPLETED",
    };
    await project.save();

    const transaction = new Transaction({
      receiptId,
      projectId: project._id,
      projectTitle: project.title,
      milestoneId: firstMilestone._id,
      milestoneTitle: firstMilestone.title,
      client: user._id,
      clientName: user.name,
      clientEmail: user.email,
      freelancer: user._id,
      freelancerName: "Alex Rivera",
      freelancerEmail: "freelancer@trustpay.ai",
      amount: firstMilestone.amount,
      currency: "USD",
      paypalOrderId: paypalOrder.id,
      paypalCaptureId: captureResult.captureId,
      paymentStatus: "COMPLETED",
      isSandbox: true,
      paidAt: new Date(),
    });
    await transaction.save();
    console.log(`✓ 9. PayPal Sandbox capture verified! Receipt generated: ${receiptId}.`);

    // Cleanup test record
    await Project.deleteOne({ _id: project._id });
    await Transaction.deleteOne({ _id: transaction._id });
    await User.deleteOne({ _id: user._id });
    console.log("✓ 10. Cleaned up transient test artifacts.");

    console.log("\n=======================================================");
    console.log("  ALL TRUSTPAY AI CORE SYSTEM TESTS PASSED SUCCESSFULLY!  ");
    console.log("=======================================================\n");

    process.exit(0);
  } catch (error) {
    console.error("\n❌ Test Failed:", error);
    process.exit(1);
  }
}

runTests();
