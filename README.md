# TrustPay AI — Smart Milestones. Transparent Payments.

> **PayPal AI Hackathon 2026 Submission**  
> An AI-powered freelance project management and milestone escrow payment application. Connects clients and freelancers, breaks projects into verifiable milestones using Google Gemini AI, validates submitted work against agreed acceptance criteria, and releases payments via PayPal Sandbox (Orders v2).

---

## 🚀 Key Features & Highlights

1. **AI-Powered Project Milestone Decomposition**
   - Decomposes client project scopes into 3–5 structured sequential phases with titles, deliverables, acceptance criteria, duration estimates, dependencies, and risks using **Google Gemini AI**.
   - Backend financial balancing engine enforces that the sum of milestone amounts equals the total project budget with integer minor currency unit precision.

2. **Immutable Agreement System**
   - Mutual freelance contract agreement workflow.
   - Both parties must review and accept. Once mutually accepted, an immutable cryptographic snapshot of terms and milestones is saved.
   - Freelancers can request changes before acceptance.

3. **Gemini AI Work Verification & Audit**
   - When freelancers submit work (with description, GitHub repo, live demo URL, and evidence notes), **Google Gemini AI** conducts an automated compliance audit against agreed acceptance criteria.
   - Generates an AI Audit Report with a compliance score (0–100), verdict (`PASSED`, `NEEDS_IMPROVEMENT`, `FAILED`), checklist matches, and identified risks.

4. **PayPal Sandbox REST API Integration (Orders v2)**
   - Backend-controlled order creation (`/v2/checkout/orders`) and server-side payment capture (`/v2/checkout/orders/{id}/capture`).
   - Client can only release payments for milestones verified and approved.
   - Generates verifiable cryptographic payment receipts (formatted `TP-REC-YYYY-XXXX`) logged permanently in MongoDB.
   - Clear fintech test badges: **PAYPAL SANDBOX MODE • TEST TRANSACTIONS ONLY**.

5. **Fintech Design System**
   - Pure fintech aesthetic: Background `#FFFFFF`, Primary Teal `#008C82`, Secondary background `#F6F8F8`, Dark Charcoal text `#14252B`.
   - Material 3 with rounded cards (16dp), rounded buttons (12dp), high-contrast typography, status badges, and loading skeletons.
   - No unnecessary gradients or distracting animations.

---

## 🛠 Technology Stack

### Mobile Frontend
- **Framework:** Flutter 3 (Dart 3)
- **Design System:** Material 3 Fintech UI (Teal `#008C82`, Charcoal `#14252B`)
- **State Management:** Provider pattern (`AuthProvider`, `ProjectProvider`, `DashboardProvider`)
- **Networking:** HTTP REST client with automatic JWT Bearer token injection
- **Persistence:** Secure local storage with `shared_preferences`
- **Formatting:** `intl` package for currency and date formatting

### Backend Server
- **Runtime:** Node.js (v24+) & Express.js
- **Database:** MongoDB Atlas with Mongoose ODM
- **Authentication:** JWT Access & Refresh Token rotation with `bcryptjs` password hashing
- **Security:** Helmet, CORS, and Express Rate Limiting
- **Validation:** Zod schemas for request validation

### AI & Payments
- **AI Integration:** Google Gemini API (structured JSON output for milestones & work verification)
- **Payment Gateway:** PayPal REST APIs (Orders v2) in PayPal Sandbox environment

---

## 👥 Pre-Seeded Hackathon Demo Accounts

The database is already initialized with active sample data. You can log in with one tap using the **Quick Demo Login** buttons on the login screen, or enter:

| Role | Email | Password | Name | Description |
|---|---|---|---|---|
| **Client** | `client@trustpay.ai` | `Password123!` | Sarah Jenkins | Product Director with created projects & funded milestones |
| **Freelancer** | `freelancer@trustpay.ai` | `Password123!` | Alex Rivera | Senior Fullstack Dev with assigned milestones & receipts |

---

## 📂 Project Structure

```text
trustpay_ai/
├── lib/                               # Flutter Mobile Application
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart     # Dynamic backend URL configuration
│   │   │   └── app_colors.dart        # Teal fintech palette
│   │   ├── theme/
│   │   │   └── app_theme.dart         # Material 3 typography & styling
│   │   └── utils/
│   │       ├── currency_formatter.dart# Cents & USD currency formatting
│   │       └── date_formatter.dart    # Human-readable date formatting
│   ├── models/
│   │   ├── user_model.dart            # Client / Freelancer profiles
│   │   ├── project_model.dart         # Project agreements & metadata
│   │   ├── milestone_model.dart       # Milestones & PayPal payment objects
│   │   ├── submission_model.dart      # Work evidence & revisions
│   │   ├── ai_review_model.dart       # Gemini AI verification reports
│   │   └── transaction_model.dart     # Payment receipts & capture history
│   ├── services/
│   │   ├── api_service.dart           # Centralized HTTP request engine
│   │   ├── auth_service.dart          # Login, Register, Profile, Tokens
│   │   ├── project_service.dart       # Projects & agreement actions
│   │   ├── ai_service.dart            # Gemini milestone & review calls
│   │   ├── payment_service.dart       # PayPal Orders v2 & Receipts
│   │   └── storage_service.dart       # Secure token & user caching
│   ├── providers/
│   │   ├── auth_provider.dart         # Authentication state
│   │   ├── project_provider.dart      # Projects & milestone workflows
│   │   └── dashboard_provider.dart    # Real-time metrics & statistics
│   ├── screens/
│   │   ├── auth/                      # Login, Register, Forgot Password
│   │   ├── client/                    # Client Dashboard & Create Project
│   │   ├── freelancer/                # Freelancer Workspace & Deliveries
│   │   ├── projects/                  # Project Details, Milestone Details,
│   │   │                              # Submit Work & PayPal Checkout Modals
│   │   ├── payments/                  # Receipts List & Receipt Invoices
│   │   ├── profile/                   # User Profile & Host Settings
│   │   └── navigation_screen.dart     # Role-based bottom navigation
│   └── widgets/                       # Fintech cards, badges, banners, buttons
│
├── trustpay-backend/                  # Node.js Express REST API Backend
│   ├── models/                        # User, Project, Transaction schemas
│   ├── routes/
│   │   ├── authRoutes.js              # Register, login, refresh, profile
│   │   ├── projectRoutes.js           # CRUD & agreement mutual signing
│   │   ├── milestoneRoutes.js         # Submissions, AI review & client approvals
│   │   ├── aiRoutes.js                # Gemini milestone generation endpoints
│   │   ├── paymentRoutes.js           # PayPal create order & capture endpoints
│   │   └── dashboardRoutes.js         # Client & Freelancer KPI metrics
│   ├── services/
│   │   ├── geminiService.js           # Google Gemini AI structured integration
│   │   └── paypalService.js           # PayPal Orders v2 Sandbox REST client
│   ├── middleware/                    # Auth JWT, rate limiters, Zod validators
│   ├── .env                           # MongoDB URI, JWT keys & Sandbox configs
│   ├── seed.js                        # Database seeder with demo projects
│   ├── test-e2e.js                    # Automated end-to-end integration test suite
│   └── server.js                      # Express startup & MongoDB connection
```

---

## ⚡ Quick Start Guide

### 1. Start the Backend Server

```bash
cd trustpay-backend
npm install
node server.js
```

The backend will connect to MongoDB Atlas and listen on `http://localhost:3000`.

*(Optional: Run `node seed.js` if you want to reset the pre-seeded demo accounts and contracts).*

### 2. Run the Automated Test Suite

To verify all database schemas, Gemini AI generation, work audit, and PayPal Sandbox order creation & capture:

```bash
cd trustpay-backend
node test-e2e.js
```

You will see all 10 verification steps complete with `ALL TRUSTPAY AI CORE SYSTEM TESTS PASSED SUCCESSFULLY!`.

### 3. Run the Flutter Mobile App

In the project root:

```bash
flutter pub get
flutter run
```

#### Connecting from an Android Device or Emulator:
- If testing on the **Android Emulator**, the app automatically communicates with `http://10.0.2.2:3000`.
- If testing on a **Physical Android Device**, tap the **Settings icon** on the login screen or in the Profile tab and enter your computer's local network IP (e.g. `http://192.168.1.160:3000`).

---

## 💳 PayPal Sandbox Workflow Walkthrough

1. **Client** logs in and creates a project:
   - Enters title, description, and budget (e.g., `$1,000`).
   - Clicks **"Generate Milestones with AI"**.
   - Gemini AI generates structured milestones with exact budget balancing.
   - Client reviews and sends agreement to Freelancer.
2. **Freelancer** logs in:
   - Reviews agreement terms and clicks **"Accept Agreement"** (creating an immutable snapshot).
   - Starts work on Milestone 1.
   - Clicks **"Submit Work Evidence"**, entering a description, GitHub URL, and live demo link.
   - Clicks **"Run AI Audit"** — Google Gemini verifies the code and criteria compliance (producing score and breakdown).
3. **Client** reviews submission:
   - Views the submission notes and the Gemini AI verification report.
   - Clicks **"Approve Milestone"**.
4. **Escrow Release via PayPal Sandbox**:
   - Client clicks **"Release Payment via PayPal Sandbox"**.
   - The backend initializes a PayPal Sandbox Order via Orders v2.
   - The backend executes server-side payment capture (`/v2/checkout/orders/{id}/capture`).
   - Milestone status updates to `Paid`, unlocking the next milestone.
   - An immutable receipt `TP-REC-YYYY-XXXX` is issued and saved to MongoDB.

---

## 🛡️ License

Developed for the **PayPal AI Hackathon 2026**.
