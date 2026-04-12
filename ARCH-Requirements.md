# Requirements Extraction: ARCH Developments Sub-Contractor Management System

## Context

This document extracts **system requirements** from the 20-page Obsidian Publish site for "wherewillwevisit.com" (ARCH Developments). The source material is heavily design-oriented — it includes AWS architecture, CDK code, DynamoDB schemas, API designs, and Step Functions workflows. Below, I separate what the system **must do** (requirements) from **how it's been designed to do it** (design/implementation decisions).

---

## REQUIREMENTS (What the system must do)

### 1. Purpose & Scope
A system to manage the full lifecycle of subcontractor work on building projects: from enquiry and quoting through to variations, progress claims, completion, and retention release.

### 2. Actors / Roles
- **Sub-contractor** (brick/stone crew) — primary user, mobile-first
- **Main contractor** (builder) — approvals, site instructions
- **Quantity surveyor (QS)** — claim review, variation approval, final account
- **System admin** — system management

### 3. Functional Requirements

#### 3.1 Job & Scope Management
- FR-01: Create jobs from enquiries
- FR-02: Attach drawings, specs, site details to jobs
- FR-03: Track job status and contract value
- FR-04: Job status lifecycle: Enquiry → Quoted → Contracted → Mobilised → InProgress (↔ VariationPending) → Completed → Closed
- FR-05: Status transitions must follow the state machine (no skipping states)
- FR-06: Contract value must be >= 0
- FR-07: Retention rules immutable after job reaches "Contracted" status (only changeable via approved variation)

#### 3.2 Quoting & Contract Formation
- FR-08: Build quotes from line items (description, quantity, unit, rate)
- FR-09: Track exclusions and assumptions (free text)
- FR-10: Show running total during quote building
- FR-11: Quote status flow: Draft → Submitted → Accepted | Rejected
- FR-12: Only one accepted quote per job (invariant)
- FR-13: Quote total must equal sum of line item amounts (invariant)
- FR-14: Summary/review page before submission with totals, exclusions, notes
- FR-15: Quote card displays status and timeline (created, submitted, accepted)
- FR-16: Select existing job or create new job from enquiry when starting a quote

#### 3.3 Execution Tracking (Daily Logs)
- FR-17: Daily logs capturing: labour hours (per person or total), materials used (optional), progress notes (free text), photos
- FR-18: Date defaults to today when creating a log
- FR-19: Labour hours must be >= 0 (invariant)
- FR-20: Log date must be within job active period (invariant)
- FR-21: Photo upload capability
- FR-22: Backend must aggregate progress from daily logs for use in claims

#### 3.4 Variation Management
- FR-23: Capture variations with: description, reason (dropdown + free text), price
- FR-24: Attach evidence to variations (photos, site instruction PDF) — optional
- FR-25: Variation price must be >= 0 (invariant)
- FR-26: Variation approval workflow: Pending → Approved | Declined
- FR-27: Only approved variations affect contract value (invariant)
- FR-28: Cannot approve variation if job is Closed (invariant)
- FR-29: On approval: price rolled into contract value, variation tagged for next claim
- FR-30: UI shows "Waiting for approval" status while pending

#### 3.5 Billing & Progress Claims
- FR-31: Create progress claims per period (e.g. monthly)
- FR-32: Auto-populate claims with measured progress (from daily logs) and approved variations not yet claimed
- FR-33: Allow manual adjustment of quantities (with warning to user)
- FR-34: Show retention held and net claim amount
- FR-35: Claim status flow: Submitted → Approved | Rejected → Scheduled → Paid
- FR-36: Approved amount must be >= 0 (invariant)
- FR-37: Claim periods cannot overlap for the same job (invariant)
- FR-38: Cannot submit claim if job is not InProgress or Completed (invariant)
- FR-39: Generate PDF/document for submitted claims
- FR-40: Retention calculation rules with tiered thresholds (e.g. 10% to a cap, then 5%, then 2.5%)
- FR-41: Track payment schedules and paid status

#### 3.6 Completion & Retention
- FR-42: Practical completion workflow (walk-through, defect fixing, sign-off)
- FR-43: Defects liability period tracking
- FR-44: Final account reconciliation
- FR-45: Retention release workflow (partial at practical completion, final after defects period)

#### 3.7 Main Contractor / QS View
- FR-46: View lists of incoming quotes, variations, and claims
- FR-47: Approve/decline with comments (modal interaction)
- FR-48: Read-only view of job progress and documents
- FR-49: Notes/comments field when reviewing claims (e.g. "Looks good, approved for payment")
- FR-50: Reject or Approve actions on claims

#### 3.8 Sub-contractor Dashboard
- FR-51: Dashboard showing: Active jobs (status, site, next action), Quotes waiting on client, Variations pending approval, Claims submitted/awaiting payment
- FR-52: Primary actions from dashboard: New quote, Log daily progress, Create variation, Submit claim

#### 3.9 Notifications & Events
- FR-53: Notify main contractor when quote is submitted
- FR-54: Notify sub-contractor on quote acceptance/rejection
- FR-55: Notify approver when variation is requested
- FR-56: Notify QS when claim is submitted for review
- FR-57: Notify sub-contractor on claim approval/rejection
- FR-58: Payment scheduled notifications

#### 3.10 Document Management
- FR-59: Upload and store documents (plans, RAMS, contracts, photos)
- FR-60: Associate documents with jobs

#### 3.11 Integration Points
- FR-61: Accounting system integration (Xero, MYOB) — optional. Additional integration candidates noted in vendor discussions: Tradify, SiteConnect, Procore, generic ERP systems
- FR-62: Email ingestion for RFIs and site instructions
- FR-63: Cloud storage integration (SharePoint, S3, OneDrive)

#### 3.12 Contract & Compliance
- FR-64: Track contract type per job (lump sum, schedule of rates, cost-plus)
- FR-65: Capture and enforce payment terms per contract (e.g. 20th of month, 10-20 working days)
- FR-66: Payment dispute handling — ability to respond to disputed payment schedules
- FR-67: Quotes must have a configurable validity period; expired quotes cannot be accepted
- FR-68: Job cannot progress past Quoted without an accepted quote (business rule)
- FR-69: Mobilisation checklist generation and completion gate — RAMS, insurance, materials, scaffolding, and induction must be tracked and completed before work starts
- FR-70: System must support variable/configurable workflows per job type (steps change per engagement)
- FR-71: Claim submission deadlines/cut-off dates per contract
- FR-72: Issue/defect logging during execution phase (not just at completion)
- FR-73: Cross-entity search across jobs, sites, and documents
- FR-74: System should detect scope changes that may trigger variations
- FR-75: Track insurance certificates and compliance document status per job
- FR-76: Site induction tracking per job
- FR-77: Capture time impact (not just cost) on variations
- FR-78: Attach supporting evidence (photos, measurements) to progress claims
- FR-79: Track progress by percentage complete per scope item
- FR-80: Retention calculation supports tiered thresholds (e.g. 10% to cap, then 5%, then 2.5%)
- FR-81: Mark claims as paid (explicit action via API)
- FR-82: Job transitions to InProgress when first daily log is created or explicit "Start Work" event occurs

### 4. Non-Functional Requirements
- NFR-01: **Scalability** — auto-scaling, handle variable load
- NFR-02: **Availability** — no single point of failure
- NFR-03: **Security** — authenticated users, role-based access, encrypted data at rest and in transit
- NFR-04: **Auditability** — full audit trail of events and changes
- NFR-05: **Extensibility** — event-driven architecture allowing new consumers

### 5. Domain Model (Data Requirements)

#### Entities & Key Attributes
| Entity | Key Attributes |
|---|---|
| **Job** | jobId, clientId, siteAddress, status, contractValue, retentionRules |
| **Quote** | quoteId, jobId, lineItems[], exclusions[], total, validityPeriod, status, submittedAt, acceptedAt |
| **Variation** | variationId, jobId, description, reason, price, approvalStatus, requestedBy, approvedBy |
| **ProgressClaim** | claimId, jobId, periodStart, periodEnd, measuredWork[], variationsIncluded[], retentionHeld, approvedAmount, status |
| **DailyLog** | logId, jobId, date, labourHours, materialsUsed, progressNotes, photos[] |

#### Value Objects
- Measurement (m², lm, units)
- Money (amount, currency)
- DateRange
- ScopeItem
- SiteInstruction

#### Domain Events
- JobCreated, QuoteSubmitted, QuoteAccepted, QuoteRejected, ContractSigned
- VariationRequested, VariationApproved, VariationDeclined
- ProgressUpdated, ClaimSubmitted, ClaimPaid, PaymentScheduled
- PracticalCompletionIssued, FinalAccountClosed

#### Event-to-State Transition Mappings
| Event | State Transition |
|---|---|
| QuoteSubmitted | Enquiry → Quoted |
| QuoteAccepted | Quoted → Contracted |
| ContractSigned | Contracted → Mobilised |
| WorkStarted (or first DailyLog) | Mobilised → InProgress |
| ProgressUpdated | InProgress → InProgress (self-transition) |
| VariationRequested | InProgress → VariationPending |
| VariationApproved | VariationPending → InProgress |
| PracticalCompletionIssued | InProgress → Completed |
| FinalAccountClosed | Completed → Closed |

### 6. Business Process (8 stages)

1. **Enquiry & Pre-Contract**
   - Inputs: project drawings (architectural + structural), scope of works, specifications (materials, mortar type, tolerances, seismic requirements), programme/timeline expectations, site conditions (access, scaffolding, storage), health & safety requirements, contract type (lump sum, schedule of rates, cost-plus)
   - Activities: review drawings and scope, identify assumptions/exclusions/risks, submit RFIs if unclear, site visit (optional), prepare estimate or schedule of rates
   - Outputs: quote/tender submission, clarifications & exclusions list, provisional sums (if needed), draft programme

2. **Contract Formation**
   - Inputs: accepted quote, main contractor's subcontract agreement, insurance requirements (public liability, contract works), payment terms (often 20th of month, 10-20 working days)
   - Activities: review subcontract terms (retentions, liquidated damages, variations process), negotiate unfair clauses, provide insurance certificates, provide H&S documentation (Site Safe, RAMS)
   - Outputs: signed subcontract agreement, approved RAMS, programme slot confirmed, site induction scheduled

3. **Mobilisation & Planning**
   - Inputs: final IFC (Issued for Construction) drawings, site access instructions, material supply responsibilities (sub-contractor vs main contractor), scaffolding plan
   - Activities: order materials (if sub-contractor supplies), confirm labour availability, prepare daily/weekly work plans, attend pre-start meeting
   - Outputs: material delivery schedule, labour schedule, site induction completed, workface planning documents, mobilisation checklist completed

4. **Execution**
   - Inputs: approved drawings, materials on site, site instructions from main contractor, daily coordination with other trades
   - Activities: perform work (brick/stone laying), quality checks (plumb, level, mortar joints), recording progress (photos, daily logs), managing delays or access issues, identifying variations early, issue/defect logging
   - Outputs: completed work sections, daily site reports, quality assurance records, variation notices (if scope changes)

5. **Variations**
   - Inputs: change in design, site instruction (SI), RFI response altering scope, unexpected conditions (e.g. foundation misalignment)
   - Activities: assess cost + time impact, submit Variation Request (VR) or Variation Quotation (VQ), negotiate with main contractor, get written approval before proceeding (ideal)
   - Outputs: approved variation, updated programme, updated cost schedule, variation added to next invoice

6. **Progress Claims**
   - Inputs: contract payment schedule, measured progress (m² laid, % complete), approved variations, retention rules (typically 10% → 5% → 2.5%)
   - Activities: prepare monthly progress claim, attach supporting evidence (photos, measurements), submit before cut-off date (often 20th), respond to Payment Schedule (if disputed)
   - Outputs: progress claim, payment schedule from main contractor, invoice issued, payment received

7. **Practical Completion**
   - Inputs: completed scope, QA documentation, site inspection
   - Activities: walk-through with main contractor, fix defects/snags, provide warranties (if required), provide as-built documentation (if relevant)
   - Outputs: Practical Completion Certificate, release of part of retention, final claim for remaining work

8. **Final Account & Close-Out**
   - Inputs: defects liability period (often 12 months, configurable per job), final inspection
   - Activities: attend to any defects, submit final invoice, reconcile accounts (materials, labour, variations)
   - Outputs: Final Completion Certificate, release of final retention, project financial close-out report

### 7. Interaction Between Parties (from Swimlane)
| Stage | Sub-contractor | Main Contractor | QS | System |
|---|---|---|---|---|
| Enquiry | — | Send drawings + scope | — | Create Job |
| Quoting | Review, measure, price, submit quote | — | — | Store quote, update status |
| Contract | Provide insurance + RAMS | Accept quote, send subcontract | Review contract value | Update status |
| Mobilisation | Order materials, schedule labour | Confirm scaffolding + access | — | Track readiness |
| Execution | Perform work, daily logs | Issue site instructions | — | Detect scope changes |
| Variations | Submit variation price | Issue SI | Approve/decline | Update contract value |
| Billing | Submit progress claim | Payment schedule | Validate quantities | Generate invoice |
| Completion | Fix defects | Issue PC certificate | — | Update status |
| Final Account | — | Release retentions | Reconcile final amounts | Close job |

---

## DESIGN DECISIONS (How it's been designed — NOT requirements)

The following are implementation/architecture choices from the document that should be evaluated separately from requirements:

### Technology Stack (from aws-system-view, cdk-shape)
- AWS serverless architecture (Lambda, API Gateway, DynamoDB, S3, EventBridge, Step Functions, SQS, SNS, Cognito)
- S3 + CloudFront for static web app hosting
- React/Vue frontend (not specified which)
- CDK for infrastructure as code
- DynamoDB single-table design with GSIs

### API Design (from api-design)
- REST API with versioning (base path /v1)
- Specific endpoint structure (e.g. POST /jobs/{jobId}/quotes)
- Resource-oriented URL patterns

### Data Storage Design (from db-schema-dynamo-db)
- DynamoDB single-table design (SubcontractorCore)
- Partition key (PK) / Sort key (SK) patterns
- GSI1 by status, GSI2 by client

### Workflow Design (from step-functions)
- AWS Step Functions for job lifecycle, billing, and variation workflows
- Specific Lambda function names and state machine structure
- Task token pattern for human approvals

### Event Architecture (from event-model, event-driven-state-machine)
- EventBridge as event bus
- Specific event JSON payloads
- Event-driven decoupling between services

### Infrastructure Patterns (from cdk-shape)
- Separate CDK stacks for Core API, Workflows, Frontend
- Cognito authorization on API methods
- PAY_PER_REQUEST billing mode for DynamoDB

### Frontend Design (from front-end-ux-flows + mockups)
- Mobile-first responsive design
- "ARCH Developments" branding with dark blue header
- Specific tile/card layout for dashboard
- Bottom action bar with 4 buttons
- S3 pre-signed URLs for photo upload

### Observability (from aws-system-view)
- CloudWatch Logs + Metrics + Alarms
- X-Ray tracing
- OpenSearch for cross-system search (optional)

---

## Key Observations

1. **The document is heavily design-forward** — it jumps straight to AWS services, DynamoDB schemas, and CDK code without a formal requirements document. The requirements are implicitly embedded in the process flows and DDD model.

2. **The invariants in the DDD model are the closest thing to formal requirements** — these are business rules that must be enforced regardless of implementation.

3. **The vendor discussion notes reveal concerns**: the vendor has no domain knowledge, is using AI to generate the entire design, and there are questions about change management and whether existing solutions (Tradify, Procore, SiteConnect) were evaluated.

4. **Missing requirements**: No mention of user authentication flows, password policies, data retention policies, reporting/analytics, multi-tenancy, mobile offline support, or performance targets (response times, concurrent users).

5. **The 3 UI mockups** show: (a) Sub-contractor dashboard with active jobs, quotes, variations, claims sections + action buttons, (b) Create Progress Claim form with measured work, approved variations, retention calculation, (c) QS Review Progress Claim with approve/reject actions and notes field.
