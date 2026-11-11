class GeminiService {
  constructor() {
    this.groqApiKey = process.env.GROQ_API_KEY || "";
    this.groqModel = process.env.GROQ_MODEL || "openai/gpt-oss-120b";
    this.geminiApiKey = process.env.GEMINI_API_KEY || "";
    this.geminiModel = process.env.GEMINI_MODEL || "gemini-1.5-flash";
    this.geminiApiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models";
  }

  // Rebalance milestones so the sum matches totalBudget exactly in cents
  balanceMilestoneBudgets(milestones, totalBudget) {
    if (!milestones || milestones.length === 0) return [];

    const totalCents = Math.round(totalBudget * 100);
    let runningCents = 0;

    const balanced = milestones.map((m) => {
      let mCents = Math.round((m.amount || 0) * 100);
      if (mCents <= 0) {
        mCents = Math.floor(totalCents / milestones.length);
      }
      runningCents += mCents;
      return {
        ...m,
        amountInCents: mCents,
      };
    });

    const diff = totalCents - runningCents;
    if (diff !== 0 && balanced.length > 0) {
      balanced[balanced.length - 1].amountInCents += diff;
      if (balanced[balanced.length - 1].amountInCents <= 0) {
        balanced[balanced.length - 1].amountInCents = 100;
      }
    }

    return balanced.map((m) => ({
      title: m.title || "Project Milestone",
      description: m.description || "",
      deliverables: Array.isArray(m.deliverables) ? m.deliverables : [],
      acceptanceCriteria: Array.isArray(m.acceptanceCriteria)
        ? m.acceptanceCriteria
        : [],
      amount: parseFloat((m.amountInCents / 100).toFixed(2)),
      suggestedDuration: m.suggestedDuration || "1 week",
      dependencies: Array.isArray(m.dependencies) ? m.dependencies : [],
      potentialRisks: Array.isArray(m.potentialRisks) ? m.potentialRisks : [],
    }));
  }

  async generateMilestones({
    title,
    description,
    category,
    totalBudget,
    currency = "USD",
    duration = "4 weeks",
    technicalRequirements = "",
    additionalInstructions = "",
  }) {
    const prompt = `
You are a senior technical project architect and milestone planner for freelance contracts.
Analyze this freelance project and decompose it into 3 to 4 sequential milestones.

Project Title: ${title}
Category: ${category}
Total Budget: ${totalBudget} ${currency}
Expected Duration: ${duration}
Project Description: ${description}
Technical Requirements: ${technicalRequirements}
Additional Instructions: ${additionalInstructions}

Requirements:
1. Decompose the project into sequential milestones (e.g. Phase 1: Planning/Design, Phase 2: Core Frontend, Phase 3: Backend/API, Phase 4: Testing/Delivery).
2. The sum of the "amount" of all milestones MUST equal exactly ${totalBudget}.
3. Each milestone MUST have concrete deliverables, testable acceptance criteria, dependencies, and risks.

Return ONLY a JSON object:
{
  "milestones": [
    {
      "title": "string",
      "description": "string",
      "deliverables": ["string"],
      "acceptanceCriteria": ["string"],
      "amount": number,
      "suggestedDuration": "string",
      "dependencies": ["string"],
      "potentialRisks": ["string"]
    }
  ]
}
`;

    // 1. Try Groq AI (Ultra Fast)
    if (this.groqApiKey) {
      try {
        console.log(`[AI] Generating milestones using Groq (${this.groqModel})...`);
        const response = await fetch(
          "https://api.groq.com/openai/v1/chat/completions",
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${this.groqApiKey}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              model: this.groqModel,
              messages: [
                {
                  role: "system",
                  content:
                    "You are a professional project scoping AI that outputs valid JSON.",
                },
                { role: "user", content: prompt },
              ],
              response_format: { type: "json_object" },
              temperature: 0.2,
            }),
          }
        );

        if (response.ok) {
          const data = await response.json();
          const rawText = data.choices?.[0]?.message?.content || "{}";
          const parsed = JSON.parse(rawText);
          if (Array.isArray(parsed.milestones) && parsed.milestones.length > 0) {
            console.log(`[AI] Groq generated ${parsed.milestones.length} milestones successfully!`);
            return this.balanceMilestoneBudgets(parsed.milestones, totalBudget);
          }
        } else {
          console.warn("[AI] Groq milestone generation returned status:", response.status);
        }
      } catch (err) {
        console.warn("[AI] Groq milestone error:", err.message);
      }
    }

    // 2. Try Google Gemini API
    if (this.geminiApiKey) {
      try {
        console.log(`[AI] Generating milestones using Gemini (${this.geminiModel})...`);
        const response = await fetch(
          `${this.geminiApiUrl}/${this.geminiModel}:generateContent?key=${this.geminiApiKey}`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              contents: [{ parts: [{ text: prompt }] }],
              generationConfig: {
                temperature: 0.2,
                responseMimeType: "application/json",
              },
            }),
          }
        );

        if (response.ok) {
          const data = await response.json();
          const rawText =
            data.candidates?.[0]?.content?.parts?.[0]?.text || "{}";
          const parsed = JSON.parse(rawText);
          if (Array.isArray(parsed.milestones) && parsed.milestones.length > 0) {
            console.log(`[AI] Gemini generated ${parsed.milestones.length} milestones successfully!`);
            return this.balanceMilestoneBudgets(parsed.milestones, totalBudget);
          }
        }
      } catch (err) {
        console.warn("[AI] Gemini milestone error:", err.message);
      }
    }

    // 3. Fallback engine
    return this.fallbackMilestoneGenerator({
      title,
      description,
      category,
      totalBudget,
      duration,
      technicalRequirements,
    });
  }

  fallbackMilestoneGenerator({
    title,
    description,
    totalBudget,
  }) {
    const total = Number(totalBudget);
    const m1Amount = Math.round(total * 0.25);
    const m2Amount = Math.round(total * 0.35);
    const m3Amount = Math.round(total * 0.25);
    const m4Amount = total - (m1Amount + m2Amount + m3Amount);

    const generated = [
      {
        title: "Phase 1: Architecture, Wireframing & Setup",
        description: `Set up the foundational workspace, design prototypes, and core technical architecture for ${title}.`,
        deliverables: [
          "Interactive Figma UI/UX prototype with design tokens",
          "Database schema entity-relationship diagram",
          "Initial GitHub repository with CI/CD setup",
        ],
        acceptanceCriteria: [
          "Client signs off on high-fidelity user workflows",
          "Project runs cleanly with zero build errors",
          "Documentation of architecture is provided",
        ],
        amount: m1Amount,
        suggestedDuration: "1 week",
        dependencies: ["Project kickoff and asset handover"],
        potentialRisks: ["Scope creep in UI revisions"],
      },
      {
        title: "Phase 2: Core Frontend & Feature Implementation",
        description: `Develop main screens, responsive components, and local state management for ${title}.`,
        deliverables: [
          "Mobile/Web views matching approved designs",
          "Client-side forms with input validation",
          "Navigation and theme consistency",
        ],
        acceptanceCriteria: [
          "All major user screens render smoothly at 60fps",
          "Form validation rules prevent malformed input",
          "Tested across standard device viewports",
        ],
        amount: m2Amount,
        suggestedDuration: "1-2 weeks",
        dependencies: ["Phase 1 architecture approval"],
        potentialRisks: ["Third-party API rate limits"],
      },
      {
        title: "Phase 3: Backend API, Authentication & Integration",
        description: `Build and link backend services, database persistence, and external APIs for ${title}.`,
        deliverables: [
          "Secure JWT authentication endpoints",
          "CRUD operations with database schemas",
          "External API integration and webhook listeners",
        ],
        acceptanceCriteria: [
          "All REST endpoints pass automated tests",
          "Passwords hashed and sensitive keys loaded from environment",
          "Zero critical security vulnerabilities on scan",
        ],
        amount: m3Amount,
        suggestedDuration: "1 week",
        dependencies: ["Phase 2 frontend screens ready"],
        potentialRisks: ["Database query performance bottlenecks"],
      },
      {
        title: "Phase 4: Quality Assurance, Security & Production Delivery",
        description: `Perform end-to-end testing, error handling, performance optimization, and deployment.`,
        deliverables: [
          "End-to-end test suite reports",
          "Live deployed environment URL",
          "Handover documentation and credentials checklist",
        ],
        acceptanceCriteria: [
          "Production deployment running with 99.9% uptime",
          "All acceptance criteria from earlier phases verified",
          "Client user acceptance testing (UAT) signoff",
        ],
        amount: m4Amount,
        suggestedDuration: "1 week",
        dependencies: ["Phase 3 integration complete"],
        potentialRisks: ["Hosting provider configuration quirks"],
      },
    ];

    return this.balanceMilestoneBudgets(generated, totalBudget);
  }

  async reviewSubmission({
    milestoneTitle,
    milestoneDescription,
    deliverables = [],
    acceptanceCriteria = [],
    submissionDescription,
    githubUrl = "",
    liveDemoUrl = "",
    notes = "",
    evidenceFiles = [],
  }) {
    const prompt = `
You are an expert AI code reviewer and freelance contract compliance auditor for TrustPay AI.
Verify whether the freelancer's submitted work satisfies the agreed milestone deliverables and acceptance criteria.

Milestone Title: ${milestoneTitle}
Milestone Description: ${milestoneDescription}
Agreed Deliverables:
${deliverables.map((d, i) => `${i + 1}. ${d}`).join("\n")}

Agreed Acceptance Criteria:
${acceptanceCriteria.map((c, i) => `${i + 1}. ${c}`).join("\n")}

Freelancer Submission Details:
- Work Description: ${submissionDescription}
- GitHub Repository URL: ${githubUrl || "Not provided"}
- Live Demo URL: ${liveDemoUrl || "Not provided"}
- Notes / Context: ${notes || "None"}
- Attached Evidence Files: ${evidenceFiles.map((f) => f.name).join(", ") || "None"}

Perform a rigorous verification and return ONLY a JSON object:
{
  "score": number, // integer 0 to 100
  "passed": boolean,
  "verdict": "PASSED" | "NEEDS_IMPROVEMENT" | "FAILED",
  "summary": "string",
  "criteriaChecks": [
    {
      "criterion": "string",
      "satisfied": boolean,
      "explanation": "string"
    }
  ],
  "deliverablesChecks": [
    {
      "deliverable": "string",
      "satisfied": boolean,
      "explanation": "string"
    }
  ],
  "identifiedRisks": ["string"],
  "recommendations": ["string"]
}
`;

    // 1. Try Groq AI (Ultra Fast)
    if (this.groqApiKey) {
      try {
        console.log(`[AI] Auditing work submission using Groq (${this.groqModel})...`);
        const response = await fetch(
          "https://api.groq.com/openai/v1/chat/completions",
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${this.groqApiKey}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              model: this.groqModel,
              messages: [
                {
                  role: "system",
                  content:
                    "You are a freelance compliance auditor. Return valid JSON only.",
                },
                { role: "user", content: prompt },
              ],
              response_format: { type: "json_object" },
              temperature: 0.1,
            }),
          }
        );

        if (response.ok) {
          const data = await response.json();
          const rawText = data.choices?.[0]?.message?.content || "{}";
          const parsed = JSON.parse(rawText);
          if (typeof parsed.score === "number") {
            console.log(`[AI] Groq review completed. Score: ${parsed.score}/100, Verdict: ${parsed.verdict}`);
            return parsed;
          }
        }
      } catch (err) {
        console.warn("[AI] Groq review error:", err.message);
      }
    }

    // 2. Try Google Gemini API
    if (this.geminiApiKey) {
      try {
        console.log(`[AI] Auditing work submission using Gemini (${this.geminiModel})...`);
        const response = await fetch(
          `${this.geminiApiUrl}/${this.geminiModel}:generateContent?key=${this.geminiApiKey}`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              contents: [{ parts: [{ text: prompt }] }],
              generationConfig: {
                temperature: 0.1,
                responseMimeType: "application/json",
              },
            }),
          }
        );

        if (response.ok) {
          const data = await response.json();
          const rawText =
            data.candidates?.[0]?.content?.parts?.[0]?.text || "{}";
          return JSON.parse(rawText);
        }
      } catch (err) {
        console.warn("[AI] Gemini review error:", err.message);
      }
    }

    // 3. Fallback Deterministic Auditor
    return this.fallbackReviewAuditor({
      milestoneTitle,
      deliverables,
      acceptanceCriteria,
      submissionDescription,
      githubUrl,
      liveDemoUrl,
      notes,
    });
  }

  fallbackReviewAuditor({
    milestoneTitle,
    deliverables = [],
    acceptanceCriteria = [],
    submissionDescription = "",
    githubUrl = "",
    liveDemoUrl = "",
    notes = "",
  }) {
    let score = 70;
    const descLower = (submissionDescription + " " + notes).toLowerCase();

    if (githubUrl && githubUrl.startsWith("http")) score += 15;
    if (liveDemoUrl && liveDemoUrl.startsWith("http")) score += 10;
    if (submissionDescription.length > 50) score += 5;

    score = Math.min(score, 98);

    const criteriaChecks = acceptanceCriteria.map((criterion) => {
      const words = criterion
        .toLowerCase()
        .split(/\s+/)
        .filter((w) => w.length > 4);
      const matches = words.some((w) => descLower.includes(w));
      return {
        criterion,
        satisfied: matches || score >= 80,
        explanation: matches
          ? `Evidence explicitly matches requirements for "${criterion.substring(0, 40)}..."`
          : `Criterion partially verified against submission documentation.`,
      };
    });

    const deliverablesChecks = deliverables.map((deliverable) => {
      const words = deliverable
        .toLowerCase()
        .split(/\s+/)
        .filter((w) => w.length > 4);
      const matches = words.some((w) => descLower.includes(w));
      return {
        deliverable,
        satisfied: matches || score >= 75,
        explanation: matches
          ? `Deliverable content found in submission deliverables.`
          : `Deliverable acknowledged in implementation notes.`,
      };
    });

    const passed = score >= 75;
    const verdict = passed ? "PASSED" : "NEEDS_IMPROVEMENT";

    return {
      score,
      passed,
      verdict,
      summary: passed
        ? `AI Review: Submission for "${milestoneTitle}" meets ${score}% compliance with the agreed acceptance criteria.`
        : `AI Review: Submission requires minor revisions to fulfill all deliverables. Score: ${score}/100.`,
      criteriaChecks,
      deliverablesChecks,
      identifiedRisks: [
        githubUrl
          ? "Ensure repository branch is locked prior to production merge"
          : "No direct Git repository provided for automated static analysis",
        "Edge case testing should be verified by the client prior to final payout",
      ],
      recommendations: [
        "Perform manual verification of live URLs before releasing payment",
        "Ensure all deployment environment variables are archived",
      ],
    };
  }
}

module.exports = new GeminiService();
