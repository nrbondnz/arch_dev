# ARCH Developments — Infrastructure

## 1. Architecture Overview

Serverless, event-driven on AWS. All business logic runs in Lambda. Step Functions handles the job lifecycle workflow. EventBridge decouples domain events from consumers.

```
Flutter PWA (S3 + CloudFront)
        │
        │ HTTPS / JWT
        ▼
API Gateway (HTTP REST v1)
        │
        │ Cognito authorizer
        ▼
Lambda Functions
        │
        ├──► DynamoDB (SubcontractorCore)
        ├──► S3 (documents, photos, PDFs)
        └──► EventBridge (DomainBus)
                │
                ├──► Step Functions (Job Lifecycle)
                ├──► SNS / SES (email notifications + document sends)
                └──► SQS (PDF generation queue)
                          │
                          ▼
                    Lambda (PDF generator)
                          │
                          ▼
                        S3 (generated PDFs)
```

---

## 2. CDK Stack Organisation

### Stack 1: Core (`CoreStack`)
- DynamoDB table (`SubcontractorCore`) with GSIs
- API Gateway (HTTP REST, `/v1`)
- Lambda functions for all API handlers
- EventBridge bus (`SubcontractorDomainBus`)
- S3 bucket (`subcontractor-documents`) for documents, photos, PDFs
- SQS queue (`PDFGenerationQueue`) + DLQ
- Lambda for PDF generation (SQS consumer)

### Stack 2: Workflows (`WorkflowStack`)
- Step Functions: Job Lifecycle state machine
- Lambda functions used by Step Functions steps
- IAM roles for Step Functions → Lambda invocation

### Stack 3: Identity & Frontend (`FrontendStack`)
- Cognito User Pool with groups: `admin-manager`, `site-manager`
- Cognito App Client (for Flutter)
- CloudFront distribution
- S3 bucket for Flutter web build (`subcontractor-web`)

---

## 3. Cognito Configuration

### User Pool
- Login: email + password
- Password policy: min 8 chars, upper + lower + number
- Self-registration: disabled (Admin creates accounts)
- Custom attribute: `custom:role` (mirrors group)

### Groups
| Group | Description | API access |
|---|---|---|
| `admin-manager` | Business owners, office managers | Full API access |
| `site-manager` | On-site crew leads | Scoped API access (own packages only) |

### API Gateway Authorizer
- Cognito JWT authorizer on all routes
- Lambda middleware inspects `cognito:groups` claim to enforce role checks
- Site manager endpoints additionally filter by `custom:userId` against `siteManagerId` fields

---

## 4. Lambda Functions

| Function | Trigger | Purpose |
|---|---|---|
| `createJob` | POST /jobs | Create job, emit JobCreated |
| `listJobs` | GET /jobs | List jobs (filtered by role) |
| `getJob` | GET /jobs/{id} | Fetch single job |
| `patchJob` | PATCH /jobs/{id} | Update job metadata |
| `createStage` | POST /jobs/{id}/stages | Define a payment stage |
| `listStages` | GET /jobs/{id}/stages | List stages |
| `createWorkPackage` | POST /jobs/{id}/work-packages | Create work package |
| `assignWorkPackage` | POST /work-packages/{id}/assign | Assign site manager, emit WorkPackageAssigned |
| `createQuote` | POST /jobs/{id}/quotes | Build quote |
| `submitQuote` | POST /quotes/{id}/submit | Submit quote |
| `sendQuoteDocument` | POST /quotes/{id}/send-document | Generate PDF → S3 → SES/link |
| `recordQuoteAccepted` | POST /quotes/{id}/record-accepted | Record acceptance, Job → Contracted |
| `createVariation` | POST /jobs/{id}/variations | Log variation |
| `sendVariationDocument` | POST /variations/{id}/send-document | Generate PDF → S3 → SES/link |
| `recordVariationApproved` | POST /variations/{id}/record-approved | Approve, update contract value, create Task |
| `createStageClaim` | POST /stages/{id}/claims | Auto-populate and create claim |
| `sendClaimDocument` | POST /claims/{id}/send-document | Generate PDF → S3 → SES/link |
| `recordClaimPaid` | POST /claims/{id}/record-paid | Record payment, update retention |
| `createDailyLog` | POST /work-packages/{id}/daily-logs | Save log, emit ProgressUpdated |
| `getUploadUrl` | POST /jobs/{id}/upload-url | Return pre-signed S3 PUT URL |
| `listTasks` | GET /tasks | List tasks (filtered by assignee) |
| `patchTask` | PATCH /tasks/{id} | Complete task, check WorkPackage gate |
| `pdfGenerator` | SQS trigger | Generate PDF from template, store in S3 |
| `thumbnailGenerator` | S3 event (photos prefix) | Resize uploaded photos |
| `checkStageTriggers` | EventBridge scheduled rule (daily) | Check date/% triggers, emit StageTriggerReached |

---

## 5. EventBridge Rules

**Bus:** `SubcontractorDomainBus`

| Rule | Pattern | Target | Action |
|---|---|---|---|
| `OnWorkPackageAssigned` | `detailType = WorkPackageAssigned` | SNS → SES | Email site manager their work package details |
| `OnVariationApproved` | `detailType = VariationApproved` | Lambda `createTask` | Create UpdateWorkPlan task for site manager |
| `OnTaskCompleted` | `detailType = TaskCompleted` AND `detail.type = UpdateWorkPlan` | Lambda `checkWorkPackageGate` | If no pending tasks → WorkPackage → Active, Job → InProgress |
| `OnStageTriggerReached` | `detailType = StageTriggerReached` | SNS → SES | Email admin: "Stage X is ready to claim" |
| `OnQuoteDocumentSent` | `detailType = QuoteDocumentSent` | SNS → SES | Email admin confirmation of send |
| `OnStageClaimPaid` | `detailType = StageClaimPaid` | Lambda `updateRetentionBalance` | Recalculate retention balance |

---

## 6. Step Functions: Job Lifecycle Workflow

**Trigger:** `JobCreated` event or manual "Start Job Workflow" from admin.

Simplified to reflect the sub-contractor-centric model — no external approval waits.

| Step | Type | Action |
|---|---|---|
| `ValidateJobData` | Lambda | Check client details, site address |
| `WaitForQuoteAccepted` | EventBridge wait (task token) | Resume when `QuoteAcceptedRecorded` event fires |
| `ValidateStages` | Lambda | Confirm stages defined and sum = contract value |
| `SetJobContracted` | Lambda | `job.status = Contracted` |
| `MobilisationSubflow` | Nested SFN | Track mobilisation checklist (RAMS, insurance, induction, materials); wait for all items complete |
| `SetJobInProgress` | Lambda | `job.status = InProgress` |
| `MonitorToCompletion` | EventBridge wait (task token) | Resume when `PracticalCompletionIssued` fires |
| `SetJobCompleted` | Lambda | `job.status = Completed` |
| `WaitForFinalAccount` | EventBridge wait (task token) | Resume when `FinalAccountClosed` fires |
| `SetJobClosed` | Lambda | `job.status = Closed` |

---

## 7. PDF Generation Pipeline

**Trigger:** Any `send-document` Lambda puts a message on `PDFGenerationQueue`.

```
send-document Lambda
        │
        ▼
SQS: PDFGenerationQueue
        │
        ▼
Lambda: pdfGenerator
  1. Load template (Handlebars HTML template from S3)
  2. Populate with entity data
  3. Render HTML → PDF (via Puppeteer/html-pdf)
  4. Store PDF in S3: documents/{type}/{id}/{filename}.pdf
  5. Update entity record with documentS3Key
  6. Return shareable pre-signed GET URL or trigger SES send
        │
        ▼
SES (if delivery method = email or both)
  → Email to job.clientEmail with PDF attachment or link
```

**Templates stored in:** `s3://subcontractor-documents/templates/`
- `quote-template.html`
- `variation-template.html`
- `stage-claim-template.html`

---

## 8. S3 Bucket Structure

```
subcontractor-documents/
  templates/              # PDF templates
  jobs/{jobId}/
    documents/            # Drawings, specs, signed contracts
    quotes/{quoteId}/     # Generated quote PDFs
    variations/{variationId}/  # Generated variation PDFs + evidence
    claims/{claimId}/     # Generated claim PDFs + evidence
  photos/{packageId}/     # Daily log photos (original + thumbnails)
```

---

## 9. Notifications (SES / SNS)

All notifications are outbound only. Recipients:
- **Admin / Manager** — job updates, stage trigger alerts, task completions
- **Site Manager** — work package assignments, task notifications
- **Client (external)** — documents (quotes, variation docs, claims) only; no operational notifications

No inbound email parsing in scope for this phase.

---

## 10. Observability

- **CloudWatch Logs** — all Lambda functions log structured JSON
- **CloudWatch Metrics + Alarms** — Lambda error rate, DynamoDB throttling, SQS DLQ depth
- **X-Ray** — distributed tracing across API Gateway → Lambda → DynamoDB
- **CloudWatch Dashboard** — key business metrics: jobs by status, claims outstanding, payment lag

---

## 11. Error Handling

- **DLQ on PDFGenerationQueue** — failed PDF generation messages go to `PDFGenerationDLQ`, alarm fires, admin is notified
- **DLQ on EventBridge targets** — failed rule targets retry 3 times then go to DLQ
- **DynamoDB conditional writes** — optimistic concurrency on status transitions (e.g. `condition: status = InProgress`)
- **Idempotency** — all write Lambdas use AWS Lambda Powertools idempotency with a `idempotencyKey` header
- **Lambda retries** — synchronous API calls do not retry (client handles); async EventBridge consumers retry up to 3 times with backoff
