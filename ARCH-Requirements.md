# Requirements: ARCH Developments Sub-Contractor Management System

---

## 1. Purpose & Scope

A system owned and operated by the **sub-contracting business** to manage the full lifecycle of subcontract work on building projects: from enquiry and quoting through to variations, stage payments, practical completion, and retention release.

---

## 2. Actors / Roles

| Actor | Type | Description |
|---|---|---|
| **Admin / Manager** | Internal system user | Business owner or office manager. Full system access. Manages jobs, contracts, billing, document sends, and variation approvals. |
| **Site Manager** | Internal system user | On-site crew lead. Scoped to assigned work packages. Submits daily logs and completes system-generated tasks. |
| **Client (Main Contractor)** | External party | Receives documents (quotes, variations, claims) by email or link. Does not have a system account. Responses are recorded by the Admin. |

---

## 3. Functional Requirements

### 3.1 Job & Scope Management

- FR-01: Create jobs from client enquiries, capturing client name, contact, email, site address, and contract type
- FR-02: Attach drawings, specifications, and scope documents to jobs
- FR-03: Track job status and total contract value (sum of stage values)
- FR-04: Job status lifecycle: `Enquiry` → `Quoted` → `Contracted` → `Mobilised` → `InProgress` ↔ `VariationPending` → `Completed` → `Closed`
- FR-05: Status transitions must follow the state machine (no skipping states)
- FR-06: Contract value must be >= 0
- FR-07: Total contract value must equal the sum of all stage scheduled values

### 3.2 Quoting

- FR-08: Build quotes from line items (description, quantity, unit, rate); show running total
- FR-09: Track exclusions and assumptions as free text
- FR-10: Quotes must have a configurable validity date; expired quotes cannot be accepted
- FR-11: Quote status flow: `Draft` → `Submitted` → `DocumentSent` → `Accepted` | `Rejected`
- FR-12: Only one accepted quote per job
- FR-13: Quote total must equal sum of line item amounts
- FR-14: Generate a quote PDF document and send to client by email or shareable link
- FR-15: Admin records client acceptance or rejection (response received outside system)
- FR-16: Job advances to `Contracted` when quote acceptance is recorded

### 3.3 Contract Formation & Stages

- FR-17: Define contract type per job: Lump Sum, Schedule of Rates, or Cost-Plus
- FR-18: Capture payment terms per contract (e.g. "20th of following month, 20 working days")
- FR-19: Define one or more **stages** per job at contract time; each stage has:
  - Description
  - Scheduled value (NZD ex. GST)
  - Payment trigger type: `Milestone`, `Date`, `PercentComplete`, or `Manual`
  - Trigger value (milestone name, specific date, or % threshold)
  - Retention rate (per stage)
- FR-20: Sum of stage scheduled values must equal total contract value
- FR-21: Stage schedules are immutable after job reaches `InProgress` (only changeable via approved variation)
- FR-22: Mobilisation checklist must be completed (RAMS, insurance, induction, materials, access) before job advances to `InProgress`

### 3.4 Work Packages

- FR-23: Create one or more work packages per job (sequential or parallel)
- FR-24: Each work package has a description, planned start date, planned end date, and resource list
- FR-25: Assign one site manager per work package; site manager can hold multiple packages
- FR-26: Admin can reassign a work package to a different site manager
- FR-27: A work package enters `VariationPending` status when an approved variation creates an `UpdateWorkPlan` task; it returns to `Active` only when that task is completed
- FR-28: A work package cannot be marked `Completed` while `UpdateWorkPlan` tasks are outstanding

### 3.5 Execution Tracking (Daily Logs)

- FR-29: Site managers submit daily logs per work package: labour hours (per person or total), materials used (optional), progress notes, scope quantities completed, photos, issues/defects
- FR-30: Log date defaults to today; backdating allowed within grace period (within work package active dates)
- FR-31: Labour hours per entry must be >= 0
- FR-32: Photo upload capability via S3 pre-signed URLs
- FR-33: Backend aggregates cumulative quantities completed per scope item for use in stage claims
- FR-34: Percentage complete per scope item calculated from cumulative quantities vs. contract quantities
- FR-35: Issues and defects can be logged against a daily log with description, severity (Minor / Major / Critical), and photos

### 3.6 Variation Management

- FR-36: Admin logs variations with: description, reason, whether client-initiated, client contact name, cost impact, time impact in days
- FR-37: Attach evidence to variations: photos, site instruction PDFs (optional)
- FR-38: Variation cost impact must be >= 0
- FR-39: Variation status flow: `Logged` → `PricedUp` → `DocumentSent` → `Approved` | `Declined`
- FR-40: A variation document must be sent to the client before it can be marked `Approved`
- FR-41: Admin records client approval or rejection (response received outside system)
- FR-42: On approval: `job.totalContractValue += variation.price`; affected work package planned end date updated by `timeImpactDays`
- FR-43: On approval: system creates an `UpdateWorkPlan` task for the assigned site manager
- FR-44: Only approved variations affect contract value
- FR-45: Cannot approve a variation if the job is `Closed`
- FR-46: Capture time impact (days) as well as cost impact on variations

### 3.7 Stage Claims & Billing

- FR-47: System detects when a stage's trigger condition is met and notifies the Admin
- FR-48: Admin creates a stage claim for a triggered stage; claim auto-populated from:
  - Measured progress quantities (from daily logs for associated work packages)
  - Approved variations not yet included in a prior claim
- FR-49: Admin can manually adjust quantities in the claim (with a warning indicator)
- FR-50: Financial summary shows: scheduled stage value, work completed value, variations included, gross claim value, retention held (per stage rate), and net claim total
- FR-51: Claim total = gross claim value − retention held; must be >= 0
- FR-52: Only one claim per stage
- FR-53: Cannot submit a stage claim if the job is not `InProgress` or `Completed`
- FR-54: Generate a stage claim PDF document and send to client by email or shareable link
- FR-55: Admin records payment received (date, amount, notes)
- FR-56: Approved variations included in a claim cannot be double-claimed in a future stage
- FR-57: Support tiered retention (e.g. 10% per stage up to a cap, then 5%, then 2.5%) — configurable per stage

### 3.8 Practical Completion & Retention Release

- FR-58: Site manager marks work package as `Completed`
- FR-59: Admin records issuance of Practical Completion Certificate; job advances to `Completed`
- FR-60: Defects and snags logged during or after execution can be tracked and resolved
- FR-61: Partial retention release at practical completion (typically 50% of held retention)
- FR-62: Defects liability period tracked per contract (configurable duration, e.g. 12 months)
- FR-63: Admin records final completion and full retention release; job advances to `Closed`
- FR-64: Final account reconciliation: total contracted vs. total claimed vs. total paid

### 3.9 Admin Dashboard

- FR-65: Dashboard shows: active jobs (status, site, next action), stages with triggered payment conditions, variations pending document send, claims awaiting payment, outstanding site manager tasks
- FR-66: Primary quick actions from dashboard: New Job, New Quote, Log Variation, Start Stage Claim

### 3.10 Site Manager Dashboard

- FR-67: Dashboard shows: assigned work packages (status, site, dates), pending tasks, shortcut to add today's log
- FR-68: Site manager only sees jobs and work packages they are assigned to

### 3.11 Task Management

- FR-69: System creates tasks for site managers when variations are approved (`UpdateWorkPlan`)
- FR-70: System creates tasks for mobilisation checklist completion
- FR-71: System creates tasks for defect resolution during completion phase
- FR-72: Site managers can mark tasks `InProgress` and `Completed`; provide completion notes
- FR-73: Work package cannot exit `VariationPending` until all related `UpdateWorkPlan` tasks are complete

### 3.12 Client Communications (Outbound)

- FR-74: Quote documents can be sent to client by email (SES) or shareable link
- FR-75: Variation documents can be sent to client by email or shareable link
- FR-76: Stage claim documents can be sent to client by email or shareable link
- FR-77: Admin records client responses (quote acceptance/rejection, variation approval/decline, payment) — responses occur outside the system
- FR-78: No inbound client portal or client account provisioning in scope

### 3.13 Document Management

- FR-79: Upload and store documents per job: drawings, RAMS, insurance certificates, signed contracts, photos
- FR-80: Documents attached to jobs are accessible to Admin; site managers can view documents for their assigned jobs

### 3.14 Integration Points

- FR-81: Accounting system integration (Xero, MYOB) — optional
- FR-82: Cloud storage integration (SharePoint, S3, OneDrive) — optional
- FR-83: No email ingestion in scope for this phase

---

## 4. Non-Functional Requirements

- NFR-01: **Scalability** — serverless auto-scaling; handle variable construction-season load spikes
- NFR-02: **Availability** — no single point of failure; multi-AZ Lambda and DynamoDB
- NFR-03: **Security** — Cognito auth; role-scoped API access; encrypted S3 and DynamoDB at rest; HTTPS only
- NFR-04: **Auditability** — full audit trail: DynamoDB event records + EventBridge events + CloudWatch logs
- NFR-05: **Extensibility** — event-driven architecture; new consumers can subscribe to domain events without modifying existing services
- NFR-06: **Offline capability** — daily log submission and photo upload must work offline on-site (PWA service worker + IndexedDB queue + background sync)
- NFR-07: **Mobile-first** — all screens optimised for phone use on construction sites

---

## 5. Out of Scope (This Phase)

- Client portal / client login
- QS (Quantity Surveyor) as a system user
- Inbound email parsing
- Payment dispute workflow
- Cross-entity full-text search
- Scope change auto-detection
- Variable workflow configuration per job type
- CI/CD pipeline (deferred to Phase 6)
