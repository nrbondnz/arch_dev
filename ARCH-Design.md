# Design Document: ARCH Developments Sub-Contractor Management System

Extracted from the vendor-provided Obsidian Publish site (20 pages). This consolidates all design and implementation decisions into a single reference.

---

## 1. System Architecture Overview

### 1.1 Architecture Style
- **Serverless, event-driven** on AWS
- Static frontend served via S3 + CloudFront
- API Gateway as the public entry point
- Lambda functions for all business logic
- Step Functions for long-running workflows
- EventBridge for domain event bus and cross-service decoupling

### 1.2 High-Level Components

| Layer | Technology | Purpose |
|---|---|---|
| Frontend | S3 + CloudFront | Static web app (React/Vue — not specified) |
| API | API Gateway (HTTP/REST) | Public API for app + integrations |
| Compute | Lambda | Business logic (jobs, quotes, variations, claims, daily logs) |
| Workflows | Step Functions | Long-running workflows (job lifecycle, billing, retention release) |
| Events | EventBridge | Domain events and cross-service decoupling |
| Data | DynamoDB | Operational store (Jobs, Quotes, Variations, Claims, DailyLogs, Users) |
| Storage | S3 | Documents (plans, RAMS, contracts, photos) |
| Search | OpenSearch (optional) | Search across jobs, sites, documents |
| Messaging | SQS | Buffering for heavy tasks (PDF generation, image processing) |
| Notifications | SNS | Email/SMS/push notifications |
| Identity | Cognito | User authentication + roles (sub-contractor, main contractor, QS, admin) |
| Auth | IAM | Service-to-service permissions |
| Observability | CloudWatch + X-Ray | Logs, metrics, alarms, distributed tracing |

### 1.3 Core Flow Examples

**Quote lifecycle:**
1. Frontend → API Gateway → CreateQuote Lambda
2. Lambda writes Quote + updates Job in DynamoDB
3. Lambda emits `QuoteSubmitted` event to EventBridge
4. EventBridge rules:
   - Notify main contractor via SNS/SES
   - Trigger Step Functions workflow for "Quote Review" if needed

**Progress claim:**
1. Frontend → API Gateway → CreateProgressClaim Lambda
2. Lambda reads progress from DailyLogs + Variations, calculates claim
3. Writes ProgressClaim to DynamoDB
4. Emits `ClaimSubmitted` event
5. EventBridge → Step Functions "BillingWorkflow" (approval, schedule, reminders)
6. Optional integration Lambda → Xero/MYOB

---

## 2. End-to-End System Modules

### 2.1 Core Modules
- Job Management
- Quote Engine
- Contract Module
- Scheduling & Mobilisation
- Execution Tracking
- Variation Workflow
- Billing & Claims
- Document Store
- Notifications & Approvals

### 2.2 Data Flows
- Quote → Contract → Job
- Daily Logs → Progress Engine → Billing
- Site Instructions → Variation Engine
- QA → Completion → Final Account

### 2.3 Integration Points
- Email ingestion (RFIs, SIs)
- Document upload (plans, RAMS)
- Accounting system (Xero, MYOB)
- Cloud storage (SharePoint, S3, OneDrive)

---

## 3. API Design (REST, versioned)

### 3.1 Resource Model

Base path: `/v1`

**Jobs**
```
POST   /jobs
GET    /jobs/{jobId}
GET    /jobs?status=InProgress&site=...
PATCH  /jobs/{jobId}                        (limited fields: status, metadata)
```

**Quotes**
```
POST   /jobs/{jobId}/quotes
GET    /jobs/{jobId}/quotes
GET    /quotes/{quoteId}
POST   /quotes/{quoteId}/submit
POST   /quotes/{quoteId}/accept
POST   /quotes/{quoteId}/reject
```

**Variations**
```
POST   /jobs/{jobId}/variations
GET    /jobs/{jobId}/variations
GET    /variations/{variationId}
POST   /variations/{variationId}/approve
POST   /variations/{variationId}/decline
```

**Progress Claims**
```
POST   /jobs/{jobId}/claims
GET    /jobs/{jobId}/claims
GET    /claims/{claimId}
POST   /claims/{claimId}/submit
POST   /claims/{claimId}/mark-paid
```

**Daily Logs**
```
POST   /jobs/{jobId}/daily-logs
GET    /jobs/{jobId}/daily-logs?from=...&to=...
```

**Documents**
```
POST   /jobs/{jobId}/documents              (pre-signed URL flow)
GET    /jobs/{jobId}/documents
```

### 3.2 Example: POST /jobs/{jobId}/variations

**Request:**
```json
{
  "description": "Extra brick pier to support lintel",
  "reason": "Site instruction SI-23",
  "price": 450
}
```

**Response:**
```json
{
  "variationId": "V001",
  "jobId": "J456",
  "description": "Extra brick pier to support lintel",
  "reason": "Site instruction SI-23",
  "price": 450,
  "approvalStatus": "Pending",
  "createdAt": "2026-04-10T04:00:00Z"
}
```

---

## 4. Database Design (DynamoDB)

### 4.1 Single-Table Design

**Table:** `SubcontractorCore`
- Partition key: `PK`
- Sort key: `SK`

| Entity | PK | SK |
|---|---|---|
| Job | `JOB#<jobId>` | `META` |
| Quote | `JOB#<jobId>` | `QUOTE#<quoteId>` |
| Variation | `JOB#<jobId>` | `VARIATION#<variationId>` |
| ProgressClaim | `JOB#<jobId>` | `CLAIM#<claimId>` |
| DailyLog | `JOB#<jobId>` | `LOG#<date>#<logId>` |

**Job attributes:** siteAddress, status, contractValue, retentionRules, ...

### 4.2 Secondary Indexes

| Index | Partition Key | Sort Key | Use Case |
|---|---|---|---|
| GSI1 (by status) | `STATUS#<status>` | `JOB#<jobId>` | All InProgress jobs |
| GSI2 (by client) | `CLIENT#<clientId>` | `JOB#<jobId>` | All jobs for a client |

### 4.3 Access Patterns
- Job-centric access: all artefacts for a job in one partition
- Fast queries by status, client, date via GSIs

### 4.4 JSON Schemas

**Quote:**
```json
{
  "quoteId": "Q123",
  "jobId": "J456",
  "lineItems": [
    { "description": "Bricklaying", "quantity": 120, "unit": "m2", "rate": 85 }
  ],
  "exclusions": ["Scaffolding", "Site toilet"],
  "total": 10200,
  "status": "Submitted"
}
```

**Variation:**
```json
{
  "variationId": "V001",
  "jobId": "J456",
  "description": "Extra brick pier",
  "reason": "Site instruction SI-23",
  "price": 450,
  "approvalStatus": "Pending"
}
```

**Progress Claim:**
```json
{
  "claimId": "C789",
  "jobId": "J456",
  "period": "2026-03",
  "measuredWork": [
    { "scopeItem": "Brickwork", "completed": 80, "unit": "m2" }
  ],
  "variationsIncluded": ["V001"],
  "retentionHeld": 510,
  "approvedAmount": 4590,
  "status": "Submitted"
}
```

---

## 5. Domain Model (DDD)

### 5.1 Aggregates

**Job**
- Fields: jobId, clientId, siteAddress, status (Enquiry | Quoted | Contracted | Mobilised | InProgress | VariationPending | Completed | Closed), contractValue, retentionRules, createdAt, updatedAt
- Invariants:
  - contractValue >= 0
  - Status transitions must follow state machine (no skipping)
  - Retention rules immutable after "Contracted" (only via approved variation)

**Quote**
- Fields: quoteId, jobId, lineItems[], exclusions[], total, validityPeriod, status (Draft | Submitted | Accepted | Rejected), submittedAt, acceptedAt
- Invariants:
  - total = sum(lineItems.amount)
  - Only one Accepted quote per job
  - Status flow: Draft → Submitted → Accepted | Rejected

**Variation**
- Fields: variationId, jobId, description, reason, price, approvalStatus, requestedBy, approvedBy
- Invariants:
  - price >= 0
  - Only Approved variations affect contractValue
  - Cannot approve if job is Closed

**ProgressClaim**
- Fields: claimId, jobId, periodStart, periodEnd, measuredWork[], variationsIncluded[], retentionHeld, approvedAmount, status (Submitted | Scheduled | Paid)
- Invariants:
  - approvedAmount >= 0
  - Claim periods cannot overlap for same job
  - Cannot submit if job not InProgress or Completed

**DailyLog**
- Fields: logId, jobId, date, labourHours, materialsUsed, progressNotes, photos[]
- Invariants:
  - labourHours >= 0
  - date within job active period

### 5.2 Value Objects
- Measurement (m², lm, units)
- Money (amount, currency)
- DateRange
- ScopeItem
- SiteInstruction

### 5.3 Domain Events
- JobCreated, ContractSigned
- QuoteSubmitted, QuoteAccepted, QuoteRejected
- VariationRequested, VariationApproved, VariationDeclined
- ProgressUpdated
- ClaimSubmitted, ClaimPaid, PaymentScheduled
- PracticalCompletionIssued
- FinalAccountClosed

Each event is a JSON payload published to EventBridge and consumed by:
- Notification service
- Accounting integration
- Analytics/reporting

---

## 6. Event-Driven State Machine

### 6.1 Job Lifecycle States

```
[*] --> Enquiry
Enquiry --> Quoted:              QuoteSubmitted
Quoted --> Contracted:           QuoteAccepted
Contracted --> Mobilised:        ContractSigned
Mobilised --> InProgress:        WorkStarted
InProgress --> InProgress:       ProgressUpdated
InProgress --> VariationPending: VariationRequested
VariationPending --> InProgress:  VariationApproved
InProgress --> Completed:        PracticalCompletionIssued
Completed --> Closed:            FinalAccountClosed
```

---

## 7. Step Functions Workflows

### 7.1 Job Lifecycle Workflow

**Trigger:** `JobCreated` event or manual "Start Job Workflow"

| Step | Type | Action |
|---|---|---|
| ValidateJobData | Lambda | Check client, site, retention rules, contract value |
| CheckQuoteStatus | Lambda | If no accepted quote → end with WAITING_FOR_QUOTE; if accepted → continue |
| SetJobContracted | Lambda | Update Job status = "Contracted" |
| MobilisationSubflow | Nested workflow | Generate mobilisation checklist (RAMS, insurance, materials, scaffolding, induction); send notifications; wait for "MobilisationComplete" flag |
| SetJobReadyToStart | Lambda | Job status = "Mobilised" |
| WaitForWorkStart | EventBridge/Task token | Resume when first DailyLog or "Start Work" event arrives |
| SetJobInProgress | Lambda | Job status = "InProgress" |

Runs once per job. Can be re-entered for corrections via admin actions.

### 7.2 Billing / Progress Claim Workflow

**Trigger:** `ClaimSubmitted` event

| Step | Type | Action |
|---|---|---|
| LoadClaimAndJob | Lambda | Fetch claim + job + variations |
| ValidateClaim | Lambda | Check period overlap, job status, quantities |
| CalculateRetention | Lambda | Apply retention rules (e.g. 10% to cap, then 5%, then 2.5%) |
| GenerateClaimDocument | Lambda + S3 | Build PDF/HTML claim; store in S3 |
| NotifyQSForReview | SNS/SES | Email with link to claim |
| WaitForApproval | Task token/callback | QS approves/rejects via API → Step Functions callback |
| Branch | Choice | If Rejected → mark "Rejected", notify, end. If Approved → mark "Approved" |
| EmitPaymentScheduledEvent | Lambda → EventBridge | Downstream integration to accounting |

### 7.3 Variation Workflow

**Trigger:** `VariationRequested` event

| Step | Type | Action |
|---|---|---|
| ValidateVariation | Lambda | Check job not Closed, price >= 0 |
| NotifyApprover | SNS/SES | Send to main contractor/QS |
| WaitForDecision | Task token/callback | Approve/Decline via API |
| Branch | Choice | If Declined → set "Declined", end. If Approved → update variation status + Job contractValue += variation.price |
| EmitVariationApprovedEvent | EventBridge | For analytics, billing, etc. |

---

## 8. CDK Infrastructure Shape

### 8.1 Stack Organisation
- **Stack 1:** Core API + DynamoDB + EventBridge
- **Stack 2:** Workflows (Step Functions)
- **Stack 3:** Frontend hosting + Cognito

### 8.2 Core CDK Example

```typescript
// DynamoDB Table
const table = new dynamodb.Table(this, 'SubcontractorCore', {
  partitionKey: { name: 'PK', type: dynamodb.AttributeType.STRING },
  sortKey: { name: 'SK', type: dynamodb.AttributeType.STRING },
  billingMode: dynamodb.BillingMode.PAY_PER_REQUEST
});

// API Gateway
const jobApi = new apigw.RestApi(this, 'JobApi', {
  restApiName: 'Subcontractor API',
  deployOptions: { stageName: 'v1' }
});

// Lambda Function
const createJobFn = new lambda.Function(this, 'CreateJobFn', {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: 'createJob.handler',
  code: lambda.Code.fromAsset('dist/functions/createJob'),
  environment: { TABLE_NAME: table.tableName }
});

table.grantReadWriteData(createJobFn);

const jobs = jobApi.root.addResource('jobs');
jobs.addMethod('POST', new apigw.LambdaIntegration(createJobFn), {
  authorizationType: apigw.AuthorizationType.COGNITO
});

// Event Bus
const bus = new events.EventBus(this, 'DomainBus', {
  eventBusName: 'SubcontractorDomainBus'
});

// Example rule: on ClaimSubmitted → start billing workflow
new events.Rule(this, 'ClaimSubmittedRule', {
  eventBus: bus,
  eventPattern: {
    detailType: ['ClaimSubmitted']
  },
  targets: [new targets.SfnStateMachine(billingStateMachine)]
});
```

---

## 9. Frontend Design

### 9.1 Approach
- Mobile-first responsive web app
- Hosted on S3 + CloudFront
- Framework: React or Vue (not specified)
- Photo uploads via S3 pre-signed URLs

### 9.2 Sub-Contractor Dashboard
- Welcome message with user name
- **Active Jobs** section: tiles showing job name, site, status badges (In Progress, Mobilising)
- **Quotes Awaiting Response** section: numbered list with chevron navigation
- **Variations Pending Approval** section: with tick marks for items
- **Recent Progress Claims** section: showing claim IDs, statuses (Under Review, Submitted)
- **Bottom action bar**: New Quote, Log Daily Progress, Create Variation, Submit Claim

### 9.3 Create Progress Claim Screen & Flow
- Header: "Create Progress Claim"
- Job reference and claim period displayed (user selects period, e.g. March 2026)
- **Auto-populate from data**: measured progress auto-populated from daily logs; approved variations not yet claimed are shown automatically
- **Measured Work Completed**: checkboxes with quantity, unit, rate (e.g. Brickwork 80 m² @ $85/m²)
- **Approved Variations**: checkboxes with amount (e.g. Extra Block Wall $1,200)
- **Adjust & confirm**: allow manual tweak of quantities (with warning indicator to user)
- **Financial summary**: Retention Held, Work Value, Variations, Retention deduction, Claim Total (show retention and net claim)
- **Submit Claim** button
- Post-submission: status shows "Submitted", waiting for QS review; link to generated PDF provided

### 9.4 QS Review Progress Claim Screen
- Header: "Review Progress Claim"
- Claim reference, job, site, period
- **Work Completed**: with quantities, rates, and calculated amounts
- **Variation Included**: listed with amounts
- **Retention Held**: amount displayed
- **Claim Total**: prominent display
- **Notes**: free text field for reviewer comments
- **Action buttons**: Reject Claim (red), Approve Claim (green)

### 9.6 Quote Builder Flow
- Start from job or "New Quote" action
- Select existing job or create new job from enquiry
- **Quote builder**: add line items (description, quantity, unit, rate), add exclusions (free text), show running total
- **Review & submit**: summary page with totals, exclusions, notes; "Submit quote" calls `POST /quotes/{id}/submit`
- **Status feedback**: quote card shows Draft / Submitted / Accepted / Rejected; timeline shows created, submitted, accepted dates

### 9.7 Daily Log Flow
- Select job → "Add daily log"
- Date defaults to today
- **Form fields**: labour hours (per person or total), materials used (optional), progress notes (free text), photos upload (S3 pre-signed URLs)
- Save triggers `ProgressUpdated` event
- Backend aggregates progress for use in claims

### 9.8 Variation Flow
- From job → "New variation"
- **Short form**: description, reason (dropdown + free text combo), price
- **Attach evidence** (optional): photos, site instruction PDF
- Submit → status set to "Pending", UI shows "Waiting for approval"
- On approval: badge changes to "Approved", price rolled into contract value, variation tagged to appear in next claim builder

### 9.9 Main Contractor / QS View
- Lists of incoming quotes, variations, and claims
- Simple approve/decline modals with comments field
- Read-only view of job progress and documents

### 9.10 Branding
- "ARCH Developments — Building Excellence" logo
- Dark blue (#1a3a5c approximate) header bar
- Hamburger menu icon

---

## 10. Non-Functional Requirements (Design Implications)

- **Scalability**: serverless, auto-scaling via Lambda and DynamoDB on-demand (PAY_PER_REQUEST)
- **Availability**: Multi-AZ deployment; no single point of failure across availability zones
- **Security**: Cognito auth, IAM-scoped Lambdas, encrypted S3/DynamoDB at rest
- **Auditability**: DynamoDB history records maintained alongside operational data; EventBridge events + CloudWatch logs provide additional audit trail
- **Extensibility**: event-driven architecture; new consumers can subscribe to domain events without modifying existing services

---

## 11. Internal System Functions (from Technical Process Map)

The Technical/System View (MAP B) defines internal system functions at each stage:

| Stage | System Functions |
|---|---|
| Estimation | Quantify (m², lm, units); Costing engine (labour, materials, margins); Risk/exclusion tagging |
| Contract | Contract generation; Compliance checks (insurance, H&S); Document storage |
| Mobilisation | Resource scheduling; Material ordering workflow; Site induction tracking |
| Execution | Progress tracking (quantities, % complete); Issue/defect logging; Variation detection (scope delta) |
| Variation | Variation pricing; Approval workflow; Budget update |
| Billing | Claim generation; Retention calculation; Payment schedule reconciliation |
| Completion | Inspection workflow; Defect resolution tracking |
| Final Account | Final reconciliation; Retention release workflow |

---

## 12. Observability

- CloudWatch Logs + Metrics + Alarms
- X-Ray for distributed tracing
- OpenSearch (optional) for cross-system search

---

## 13. Vendor Context Notes

From the "ARCH project discussions with vendor" page:

- Vendor has **no domain knowledge** of the construction/subcontracting industry
- Using **AI to generate the entire build** — not based on any existing domain expertise
- Problem domain centers around **flow of information through the system** — framed as a "system flow issue between core system and 3rd party systems"
- Different use cases apply to different jobs; steps change per engagement
- Existing solutions in the market were noted but not evaluated in depth:
  - Tradify, Procore, SiteConnect, Xero (accounting), ERP systems
- Change management was raised as a concern
- Suggestion was made to get a BA to document the current process
