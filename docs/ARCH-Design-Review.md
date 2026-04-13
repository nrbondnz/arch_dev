# Design Review: ARCH Developments Sub-Contractor Management System

Reviewed against ARCH-Requirements.md (82 FRs, 5 NFRs) and ARCH-Design.md (13 sections).

---

## 1. Design Gaps (requirements with no design coverage)

These requirements are defined but have no corresponding design — no API endpoint, no schema field, no workflow step, and no UI.

| Req | Description | What's Missing |
|---|---|---|
| FR-64 | Contract type (lump sum, schedule of rates, cost-plus) | No field in Job schema or DynamoDB design. No UI for selecting contract type. No logic for how contract type affects billing. |
| FR-65 | Payment terms per contract | No field in Job/Contract schema. No enforcement mechanism designed. |
| FR-66 | Payment dispute handling | No API endpoint, no workflow, no UI. The billing Step Function only has Approved/Rejected — no "Disputed" path. |
| FR-67 | Quote validity period | `validityPeriod` is in the domain model but: no validation logic designed to reject acceptance of expired quotes, no UI to display expiry. |
| FR-69 | Mobilisation checklist and gate | Step Functions mentions "MobilisationSubflow" but the checklist items (RAMS, insurance, materials, scaffolding, induction) have no schema, no API to update checklist status, no UI to track completion. |
| FR-70 | Variable workflows per job type | No design for workflow configuration. The Step Functions are hardcoded sequences. |
| FR-71 | Claim submission deadlines | No field in Job/Contract schema. No enforcement or reminder mechanism. |
| FR-72 | Issue/defect logging during execution | No schema for issues/defects separate from daily logs. No API endpoint. No UI. |
| FR-73 | Cross-entity search | OpenSearch marked "optional" with no design for indexing, query API, or search UI. |
| FR-74 | Scope change detection | Listed as a system function in MAP B but no design for how detection works. |
| FR-75 | Insurance/compliance tracking | No schema, no API, no UI for tracking document status per job. |
| FR-76 | Site induction tracking | No schema, no API, no UI. |
| FR-77 | Time impact on variations | No field in Variation schema (only has `price`, not `timeImpactDays` or similar). |
| FR-78 | Evidence attachment to claims | Claims schema has no `attachments[]` or `evidence[]` field. |
| FR-79 | Percentage complete tracking | No field for `percentComplete` on scope items or jobs. Daily logs capture raw quantities but there's no design for calculating/storing percentage. |

**Verdict:** 15 of 82 functional requirements (~18%) have no design coverage. Most of these are from the enriched requirements we extracted from the process flows. The original design was built around a narrower scope.

---

## 2. Design Concerns (things that don't feel right)

### 2.1 DynamoDB Single-Table Design — HIGH RISK

**The concern:** The single-table design with 2 GSIs is the most fragile part of this design. It works for the basic access patterns described (get job, get quotes for job) but will struggle with:

- **Reporting queries** — the QS needs to see all claims across all jobs, filter by date range, status, and value. GSI1 (by status) and GSI2 (by client) won't cover this. Every new query pattern requires a new GSI (max 20 per table, and each adds write cost).
- **Claim period queries** — FR-37 requires checking for overlapping claim periods. This is a range query that's awkward in DynamoDB.
- **Cross-entity search** (FR-73) — DynamoDB can't do full-text search or fuzzy matching.
- **Retention calculations** — require reading all previous claims for a job to determine which tier applies. This works with the current PK design but gets expensive at scale.
- **Schema evolution** — adding fields like `contractType`, `paymentTerms`, `timeImpact`, `percentComplete`, `complianceDocuments[]` means migrating existing items. DynamoDB has no `ALTER TABLE`.

**Recommendation:** Given short timescales and that the implementor knows AWS, I would **not** recommend switching to PostgreSQL at this stage — that would be a major redesign. Instead:

1. **Keep DynamoDB** but acknowledge its limitations in the design
2. **Add a GSI3** for claim queries: `GSI3PK = CLAIM#<status>`, `GSI3SK = <periodEnd>` — enables queries like "all submitted claims" and date-range filtering
3. **Plan for a read-replica pattern** early: DynamoDB Streams → Lambda → a simple reporting store (could even be S3 + Athena for v1) when the QS needs cross-job reporting
4. **Document the GSI budget** — with 3 core GSIs, 17 remain. Map out which future access patterns might consume them

### 2.2 Step Functions — MEDIUM RISK (over-engineering)

**The concern:** Three Step Functions workflows are defined, but two of them (Variation and Billing) are essentially linear flows with one branch point. The overhead of Step Functions (state management, IAM roles, logging, debugging, cost) is significant for what could be:

```
Receive event → Validate → Notify → Wait for callback → Update status → Emit event
```

**Recommendation:** Keep the **Job Lifecycle** workflow in Step Functions — it genuinely has multiple states, long waits, and a nested sub-workflow. But consider implementing the **Variation** and **Billing** workflows as simpler Lambda-driven flows:

- Variation: a single Lambda handles validate → notify. A second Lambda handles the callback (approve/decline → update → emit). No state machine needed.
- Billing: the main value of Step Functions here is the "WaitForApproval" step. This could use a simpler pattern: EventBridge Scheduler for reminders + a callback API endpoint.

However, if the implementor is comfortable with Step Functions and the visual debugging is valued, keeping all three is acceptable — it's not wrong, just heavier than necessary. **Don't change this if it would slow delivery.**

### 2.3 Missing Authentication/Authorisation Design — HIGH GAP

**The concern:** Cognito is listed as the identity provider and roles are mentioned (sub-contractor, main contractor, QS, admin), but there is no design for:

- How users are provisioned (self-registration? Admin creates accounts?)
- How roles are assigned and what each role can access
- Multi-tenancy — can a sub-contractor see other sub-contractors' data? The PK design (JOB#) doesn't partition by tenant
- API authorisation — which endpoints each role can call (e.g., only QS/MC can approve claims)

**Recommendation:** Add a `USER#<userId>` item in DynamoDB linking users to their role and associated jobs. Add a Cognito custom attribute for role. Use API Gateway authorizers or Lambda middleware to enforce role-based access. This needs to be designed before implementation starts.

### 2.4 No Error Handling or Retry Design

**The concern:** The design describes happy paths only. No mention of:
- What happens when a Lambda fails mid-write (DynamoDB write succeeds, EventBridge publish fails)
- Dead letter queues for failed events
- Idempotency keys on API endpoints
- Conflict handling (two users updating the same claim simultaneously)

**Recommendation:** Add DLQs on all SQS queues and EventBridge rules. Use DynamoDB conditional writes for optimistic concurrency. Add idempotency middleware to Lambda functions (AWS Powertools has this built in).

### 2.5 No Offline / Poor Connectivity Story — MEDIUM RISK

**The concern:** Sub-contractors work on building sites with unreliable mobile signal. The daily log flow (photos + form data) will fail silently if the connection drops. FR-17 through FR-22 are the most-used features and the most likely to be used in poor connectivity.

**Recommendation:** The frontend should be a PWA (Progressive Web App) with:
- Service worker for offline form caching
- IndexedDB for queuing daily logs when offline
- Background sync to upload when connectivity returns
- Optimistic UI (show the log as saved locally, sync later)

This doesn't change the backend design but needs to be in the frontend design.

### 2.6 Photo Upload Flow — Incomplete

**The concern:** "S3 pre-signed URLs" is mentioned but the flow isn't designed:
- Who generates the pre-signed URL? (A dedicated Lambda endpoint?)
- What's the max file size?
- Is there image compression/resizing? (SQS mentions "image processing" but nothing specific)
- How are photos linked to the daily log / variation / claim record?

**Recommendation:** Add a `POST /jobs/{jobId}/upload-url` endpoint that returns a pre-signed S3 PUT URL + a document ID. The client uploads directly to S3. An S3 event triggers a Lambda for thumbnail generation. The document ID is included in the daily log / variation / claim payload.

### 2.7 PDF Generation — Not Designed

**The concern:** FR-39 requires generating PDF documents for claims. SQS is listed for "PDF generation" but there's no design for:
- What template/library generates the PDF
- Where the template is stored
- How the PDF is linked back to the claim record

**Recommendation:** The billing Step Function's "GenerateClaimDocument" step should put a message on SQS. A Lambda consumer generates the PDF (using a library like `@react-pdf/renderer` or `puppeteer` for HTML-to-PDF), stores it in S3, and updates the claim record with the S3 key.

### 2.8 No CI/CD or Deployment Design

**The concern:** CDK stacks are defined but there's no design for:
- Pipeline (CodePipeline, GitHub Actions, etc.)
- Environments (dev, staging, prod)
- Database migration strategy (DynamoDB schema changes)
- Feature flags for phased rollout

**Recommendation:** At minimum, design a GitHub Actions pipeline with: lint → test → CDK synth → deploy to staging → manual approval → deploy to prod. Use CDK `Stage` constructs to manage environments.

---

## 3. Alternative Approaches Worth Considering

### 3.1 API Gateway → AppSync (GraphQL)

**Why:** The frontend has multiple screens that need different subsets of job data (dashboard needs summary, claim screen needs details + variations + logs). REST requires multiple round-trips or custom endpoints. GraphQL lets the frontend request exactly what it needs.

**Trade-off:** More complex backend setup. If the implementor doesn't know AppSync/GraphQL, this adds learning curve and risk. **Skip if timescales are tight.**

### 3.2 EventBridge → SNS+SQS Fan-out

**Why:** EventBridge is powerful but adds complexity. For a system with <15 event types, a simpler SNS topic per domain event with SQS subscriptions per consumer would be easier to debug and monitor.

**Trade-off:** Less flexible filtering. EventBridge's content-based routing is genuinely useful when you have many consumers. **Keep EventBridge — it's the right choice here.**

### 3.3 Cognito → Auth0 / Clerk

**Why:** Cognito's hosted UI and customisation options are limited. If the app needs a polished login experience, Cognito can be frustrating.

**Trade-off:** External service cost and dependency. **Keep Cognito for v1** — it integrates natively with API Gateway and the login flow is not the priority.

---

## 4. Phased Implementation Plan

### Phase 1: Core Foundation (Weeks 1-3)
**Goal:** Sub-contractor can create jobs, build and submit quotes.

**Deliver:**
- Infrastructure: CDK Stack 1 (DynamoDB, API Gateway, EventBridge, Cognito)
- Auth: Cognito user pool with role-based groups (sub-contractor, main-contractor, QS)
- API: Jobs CRUD, Quotes CRUD + submit
- Domain events: JobCreated, QuoteSubmitted
- Frontend: Login, dashboard (jobs list only), quote builder flow
- Data: Job and Quote entities in DynamoDB

**User value:** Sub-contractors can register, create jobs, and submit quotes digitally instead of via email/paper. Main contractors receive notification of submitted quotes.

**FRs covered:** FR-01, FR-02, FR-03, FR-04 (partial), FR-05 (partial), FR-06, FR-08, FR-09, FR-10, FR-11, FR-12, FR-13, FR-14, FR-15, FR-16, FR-51 (partial), FR-52 (partial), FR-53, FR-67 (partial), FR-68

---

### Phase 2: Daily Logs & Execution (Weeks 4-5)
**Goal:** Sub-contractor can log daily progress with photos.

**Deliver:**
- API: Daily logs CRUD, document upload (pre-signed URLs)
- Photo upload flow: pre-signed URL endpoint, S3 storage, thumbnail Lambda
- Frontend: daily log form, photo capture/upload, log history view
- Domain events: ProgressUpdated
- PWA: service worker for offline daily log caching + background sync

**User value:** Daily site progress is captured digitally with photos. Replaces paper site diaries. Works offline on-site.

**FRs covered:** FR-17, FR-18, FR-19, FR-20, FR-21, FR-22, FR-59, FR-60, FR-79 (partial)

---

### Phase 3: Variations (Weeks 6-7)
**Goal:** Full variation request and approval workflow.

**Deliver:**
- API: Variations CRUD + approve/decline
- Workflow: Variation approval (Lambda-based or Step Functions)
- Frontend: variation form (reason dropdown + free text), evidence upload, approval UI for MC/QS
- Domain events: VariationRequested, VariationApproved, VariationDeclined
- Contract value auto-update on approval

**User value:** Variations are tracked formally with evidence. No more verbal agreements or lost site instructions. Contract value updates automatically.

**FRs covered:** FR-23, FR-24, FR-25, FR-26, FR-27, FR-28, FR-29, FR-30, FR-47 (partial), FR-55, FR-77

---

### Phase 4: Progress Claims & Billing (Weeks 8-10)
**Goal:** Full claim creation, submission, review, and approval.

**Deliver:**
- API: Claims CRUD + submit + mark-paid
- Billing logic: auto-populate from logs + approved variations, retention calculation (tiered)
- PDF generation: claim document via SQS + Lambda
- Step Functions: billing workflow (validate → generate PDF → notify QS → wait for approval → payment event)
- Frontend: create claim screen (auto-populate, adjust, submit), QS review screen (approve/reject with notes)
- Domain events: ClaimSubmitted, ClaimPaid, PaymentScheduled

**User value:** Monthly progress claims are generated from real data, not manual spreadsheets. QS can review and approve digitally. PDF claims are generated automatically.

**FRs covered:** FR-31, FR-32, FR-33, FR-34, FR-35, FR-36, FR-37, FR-38, FR-39, FR-40, FR-41, FR-46, FR-47, FR-48, FR-49, FR-50, FR-56, FR-57, FR-58, FR-78, FR-80, FR-81

---

### Phase 5: Job Lifecycle & Completion (Weeks 11-12)
**Goal:** Full job lifecycle from enquiry to close-out.

**Deliver:**
- Step Functions: job lifecycle workflow (validate → check quote → contract → mobilisation → execution → completion → close)
- Mobilisation checklist: schema, API, UI for tracking readiness items
- Completion workflow: practical completion, defect tracking, retention release
- Frontend: full dashboard with all sections populated, job lifecycle status view
- Domain events: ContractSigned, PracticalCompletionIssued, FinalAccountClosed
- State machine: all transitions enforced including VariationPending

**User value:** Complete job lifecycle management. Mobilisation readiness is tracked. Practical completion and retention release are managed digitally.

**FRs covered:** FR-04, FR-05, FR-07, FR-42, FR-43, FR-44, FR-45, FR-51, FR-52, FR-64, FR-65, FR-69, FR-71, FR-72, FR-75, FR-76, FR-82

---

### Phase 6: Polish & Integrations (Weeks 13-14)
**Goal:** Search, notifications, integrations, and production hardening.

**Deliver:**
- Search: OpenSearch indexing via DynamoDB Streams, search API + UI
- Notifications: SNS topics for email/SMS/push across all events
- Accounting integration: optional Xero/MYOB Lambda connector
- Error handling: DLQs, retry policies, idempotency
- CI/CD pipeline: GitHub Actions → staging → prod
- Monitoring: CloudWatch dashboards, alarms, X-Ray tracing

**User value:** Search across all jobs. Email/push notifications. Optional accounting system sync. Production-ready reliability.

**FRs covered:** FR-54, FR-61, FR-62, FR-63, FR-66, FR-70, FR-73, FR-74, NFR-01 through NFR-05

---

## 5. Phase Summary

| Phase | Weeks | Key Deliverable | Cumulative FR Coverage |
|---|---|---|---|
| 1 — Foundation | 1-3 | Jobs + Quotes | 20 FRs (24%) |
| 2 — Daily Logs | 4-5 | Execution tracking + photos | 30 FRs (37%) |
| 3 — Variations | 6-7 | Variation workflow | 40 FRs (49%) |
| 4 — Billing | 8-10 | Claims + PDF + QS review | 62 FRs (76%) |
| 5 — Lifecycle | 11-12 | Full job lifecycle + completion | 79 FRs (96%) |
| 6 — Polish | 13-14 | Search, integrations, hardening | 82 FRs (100%) |

**Phases 1-4 deliver the core value proposition** (jobs, quotes, daily logs, variations, billing) in 10 weeks. A sub-contractor could realistically use the system day-to-day after Phase 4.

---

## 6. Summary of Recommendations

| # | Recommendation | Priority | Effort |
|---|---|---|---|
| 1 | Design auth/authorisation model (roles, multi-tenancy, API access) before starting | Critical | 2-3 days |
| 2 | Add GSI3 for claim queries (by status + date range) | High | Trivial |
| 3 | Add DLQs and idempotency from Phase 1 | High | 1 day |
| 4 | Build frontend as a PWA with offline daily log support | High | 2-3 days |
| 5 | Design photo upload flow end-to-end (pre-signed URL → S3 → thumbnail → link) | High | 1 day |
| 6 | Design PDF generation pipeline (SQS → Lambda → S3) | Medium | 1 day |
| 7 | Add missing schema fields (contractType, paymentTerms, timeImpact, percentComplete, complianceStatus) | Medium | Trivial |
| 8 | Consider simplifying Variation/Billing workflows to Lambda-only (skip Step Functions) | Low | Saves time |
| 9 | Plan DynamoDB Streams → reporting store for QS cross-job queries | Low (Phase 6) | 2-3 days |
| 10 | Design CI/CD pipeline | Low (Phase 6) | 1-2 days |
