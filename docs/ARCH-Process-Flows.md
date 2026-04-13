# ARCH Developments — Process Flows

All flows are described from the **sub-contractor's perspective**. The client (main contractor) is an external party who receives documents and whose responses are recorded by the Admin.

---

## Overview: Engagement Lifecycle

```
Enquiry
   │
   ▼
Quoting ──────────────────── Quote document sent to client
   │                                   │
   │                          Client responds externally
   │                                   │
   ▼                                   ▼
Contract Formation ◄─────── Admin records acceptance
   │  (define stages, payment triggers, retention per stage)
   ▼
Mobilisation & Work Package Setup
   │  (assign site managers, set resources + timescales)
   ▼
Execution ─────────────────── Daily logs (site manager)
   │  ◄──────────────────────── Issue / defect logging
   │
   ├──► Variation ────────────── Variation doc sent to client
   │       │                             │
   │       │                    Client responds externally
   │       │                             │
   │       ▼                             ▼
   │    Admin records approval ──► Work package task created
   │       │                        (site manager updates plan)
   │       ▼
   │    Contract value updated
   │
   ▼
Stage Claim ────────────────── Claim document sent to client
   │                                    │
   │                           Client pays externally
   │                                    │
   ▼                                    ▼
(repeat per stage)        Admin records payment received
   │
   ▼
Practical Completion
   │  (walk-through, defect resolution, partial retention release)
   ▼
Final Account & Close-Out
   │  (defects liability period, final retention release)
   ▼
 Closed
```

---

## Stage 1: Enquiry & Pre-Contract

**Actor:** Admin / Manager

**Trigger:** Client contacts the business with a potential project.

**Steps:**
1. Admin creates a new **Job** in the system (status: `Enquiry`)
2. Admin attaches client details: name, contact, email
3. Admin uploads drawings, specifications, scope documents to the job
4. Admin reviews scope, identifies assumptions, exclusions, and risks
5. Admin submits RFIs to the client outside the system if scope is unclear
6. Admin builds a **Quote** from line items (description, quantity, unit, rate)
7. Admin adds exclusions and assumptions as free text
8. Admin reviews quote summary (totals, exclusions, notes)
9. Admin submits the quote (status: `Submitted`), which triggers a document send to the client via email or shareable link
10. Job status advances to `Quoted`

**Outcome:** Client holds a formal quote document. Admin awaits client response.

**Domain events:** `JobCreated`, `QuoteSubmitted`, `QuoteDocumentSent`

---

## Stage 2: Contract Formation

**Actor:** Admin / Manager

**Trigger:** Client verbally or by email accepts the quote. Admin records acceptance.

**Steps:**
1. Admin records quote acceptance in the system (status: `Accepted`)
2. Job status advances to `Contracted`
3. Admin defines the **contract structure**:
   - Contract type: lump sum, schedule of rates, or cost-plus
   - Payment terms (e.g. 20th of following month, 10 working days)
   - **Stages**: one or more stages, each with:
     - Description (e.g. "Stage 1 — Block foundation", "Stage 2 — Brickwork")
     - Scheduled value ($NZD ex. GST)
     - Payment trigger type: `milestone`, `date`, `percentComplete`, or `manual`
     - Trigger value (milestone name, specific date, or % complete threshold)
     - Retention rate (e.g. 10%)
   - Total contract value = sum of all stage values
4. Admin uploads signed subcontract agreement and insurance certificates
5. Admin records RAMS and H&S documentation status
6. Contract document sent to client as confirmation
7. Job status advances to `Mobilised` once the mobilisation checklist (RAMS, insurance, induction) is completed

**Outcome:** A structured contract with defined payment stages is recorded in the system.

**Domain events:** `QuoteAcceptedRecorded`, `ContractSigned`, `StagesDefined`, `MobilisationStarted`

---

## Stage 3: Mobilisation & Work Package Setup

**Actor:** Admin / Manager (creates packages); Site Manager (receives assignment)

**Trigger:** Contract signed and mobilisation checklist underway.

**Steps:**
1. Admin creates one or more **Work Packages** for the job
   - Each work package has: description, planned start date, planned end date, resources (crew size, equipment)
   - Work packages may be sequential or parallel
2. Admin assigns a **Site Manager** to each work package
3. Site manager receives a notification of their work package assignment, including:
   - Work scope
   - Planned timescales (start/end dates)
   - Resources available
   - Relevant drawings and documents
4. Admin confirms mobilisation checklist items:
   - RAMS approved
   - Insurance certificates on file
   - Materials ordered / delivery scheduled
   - Scaffolding and site access confirmed
   - Site induction completed
5. On checklist completion, job advances to `InProgress`

**Outcome:** Site managers know their scope, timescales, and resources. Site is ready to start.

**Domain events:** `WorkPackageCreated`, `WorkPackageAssigned`, `MobilisationCompleted`, `WorkStarted`

---

## Stage 4: Execution

**Actor:** Site Manager (primary); Admin (monitoring)

**Trigger:** Work package activated (status: `Active`).

**Steps (daily loop):**
1. Site manager opens daily log for the date (defaults to today)
2. Logs:
   - Labour hours (per person or total)
   - Materials used (optional)
   - Progress notes (free text)
   - Photos (uploaded to S3 via pre-signed URL)
   - Issues or defects encountered (linked to job/work package)
3. Daily log saved; `ProgressUpdated` event emitted
4. Backend aggregates progress against the stage's scope items:
   - Updates quantity completed per scope item (m², lm, units)
   - Calculates % complete per scope item
5. Admin can view live progress against each stage and work package

**Outcome:** Ongoing evidence of work completed. Auto-populates future stage claims.

**Domain events:** `ProgressUpdated`, `IssueLogged`

---

## Stage 5: Variations

**Actor:** Admin / Manager (primary); Site Manager (receives task)

**Trigger:** Client requests a change in scope, or scope change is identified on-site.

**Steps:**
1. Client contacts the Admin or Site Manager (phone, email, or site visit) — this happens outside the system
2. Admin logs a new **Variation** in the system:
   - Description of the change
   - Reason / source (client instruction, design change, unexpected conditions)
   - Whether it was client-initiated (flag)
   - Client contact name who requested it
3. Admin prices up the variation:
   - Cost impact ($NZD ex. GST)
   - Time impact (days added or removed from work package)
4. Admin generates a **Variation Document** and sends it to the client via email or shareable link (status: `DocumentSent`)
5. Client reviews and responds outside the system
6. Admin records the outcome:
   - **Approved**: variation status → `Approved`
     - Contract value updated: `contractValue += variation.price`
     - Work package time updated: `plannedEnd += variation.timeImpactDays`
     - A **Task** is created for the assigned site manager: "Update site work plan for approved variation [V001]"
     - Job status briefly enters `VariationPending` while the task is outstanding
   - **Declined**: variation status → `Declined`. No changes to contract or work package.
7. Site manager completes the task (updates their daily work plan, resources if needed)
8. On task completion, job status returns to `InProgress`

**Outcome:** Every scope change is formally documented with a pricing paper trail. Work packages stay current.

**Domain events:** `VariationLogged`, `VariationDocumentSent`, `VariationApproved`, `VariationDeclined`, `WorkPackageTaskCreated`

---

## Stage 6: Stage Claims

**Actor:** Admin / Manager

**Trigger:** A stage payment trigger is reached: milestone achieved, scheduled date, % complete threshold, or Admin manually initiates.

**Steps:**
1. System detects (or Admin triggers) that a stage payment condition is met
2. Admin creates a **Stage Claim** for the triggered stage:
   - Claim auto-populated from:
     - Measured progress (quantities from daily logs, % complete per scope item)
     - Approved variations not yet claimed in a prior stage
   - Admin can manually adjust quantities (with a warning indicator)
3. Admin reviews financial summary:
   - Scheduled stage value
   - Work completed value
   - Approved variations included
   - Retention held (per stage retention rate)
   - **Claim total** (net amount to be paid)
4. Admin generates a **Stage Claim Document** (PDF) and sends it to the client via email or shareable link (status: `DocumentSent`)
5. Client reviews and pays externally
6. Admin records payment received (status: `Paid`, records payment date and amount)
7. Retention balance updated; stage is closed

**Outcome:** Formal progress claim with supporting evidence sent to client. Payment tracked against each stage.

**Domain events:** `StageClaimCreated`, `StageClaimDocumentSent`, `StageClaimPaid`, `RetentionUpdated`

---

## Stage 7: Practical Completion

**Actor:** Admin / Manager; Site Manager

**Trigger:** All work is substantially complete. Site manager signals completion.

**Steps:**
1. Site manager marks their work package(s) as `Completed`
2. Admin schedules and attends a walk-through with the client
3. Defects and snags are logged in the system
4. Site manager attends to defects; logs resolution for each
5. Admin records issuance of **Practical Completion Certificate** from client
6. Job status advances to `Completed`
7. Admin creates the final main-contract stage claim:
   - Remaining work value
   - Outstanding approved variations
   - First retention release (typically 50% of held retention at practical completion)
8. Claim document sent to client; payment recorded

**Outcome:** Job is practically complete. First tranche of retention is released.

**Domain events:** `PracticalCompletionIssued`, `RetentionReleased`

---

## Stage 8: Final Account & Close-Out

**Actor:** Admin / Manager

**Trigger:** Defects liability period expires (configured per contract, typically 12 months).

**Steps:**
1. Admin attends to any defects raised during the liability period
2. Admin confirms all scope items are fully complete and documented
3. Admin creates the **Final Account** claim:
   - Any remaining balance
   - Final retention release (remaining held retention)
4. Final account document sent to client; payment recorded
5. Job status advances to `Closed`
6. Final financial report generated (contract value vs. claimed vs. paid)

**Outcome:** The engagement is fully closed. All retention is released. Financial records are reconciled.

**Domain events:** `FinalAccountClosed`, `RetentionFullyReleased`

---

## Swimlane Summary

| Stage | Admin / Manager | Site Manager | System | Client (External) |
|---|---|---|---|---|
| Enquiry | Create job, build quote | — | Store job + quote | — |
| Contract Formation | Record acceptance, define stages | — | Update status, store stages | Receives quote doc |
| Mobilisation | Create work packages, assign SMs | Receive assignment, confirm readiness | Track checklist | — |
| Execution | Monitor progress | Daily logs, photo uploads | Aggregate progress | — |
| Variations | Log, price, send doc, record approval | Receive task, update work plan | Create task, update contract value | Receives variation doc |
| Stage Claims | Create claim, send doc, record payment | — | Generate PDF, update retention | Receives claim doc |
| Practical Completion | Walk-through, record PC | Complete packages, fix defects | Update job status, trigger retention release | Receives PC claim |
| Final Account | Final claim, record payment | Fix defects | Close job, release retention | Receives final account doc |
