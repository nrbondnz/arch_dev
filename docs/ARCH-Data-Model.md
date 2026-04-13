# ARCH Developments — Data Model

---

## 1. Domain Entities

### 1.1 Job

The top-level aggregate for a client engagement.

| Field | Type | Notes |
|---|---|---|
| `jobId` | String | Unique identifier (UUID) |
| `clientName` | String | Client company name |
| `clientContactName` | String | Primary contact person |
| `clientEmail` | String | For document delivery |
| `clientPhone` | String | Reference only |
| `siteAddress` | String | Physical site location |
| `description` | String | Brief scope description |
| `contractType` | Enum | `LumpSum` \| `ScheduleOfRates` \| `CostPlus` |
| `paymentTerms` | String | e.g. "20th of following month" |
| `totalContractValue` | Decimal | Sum of all stage scheduled values (NZD ex. GST) |
| `status` | Enum | See Job Status Machine below |
| `retentionModel` | String | Description of retention approach (overridden per stage) |
| `documents` | String[] | S3 keys for attached drawings, specs, contracts |
| `createdAt` | DateTime | |
| `updatedAt` | DateTime | |

**Invariants:**
- `totalContractValue >= 0`
- Status transitions must follow the state machine (no skipping)
- `totalContractValue` = sum of all `Stage.scheduledValue` fields

---

### 1.2 Stage

A defined payment milestone within a job. Stages are set at contract time.

| Field | Type | Notes |
|---|---|---|
| `stageId` | String | UUID |
| `jobId` | String | Parent job |
| `sequence` | Integer | Ordering (1, 2, 3...) |
| `description` | String | e.g. "Stage 1 — Block foundation" |
| `scheduledValue` | Decimal | NZD ex. GST, fixed at contract time |
| `triggerType` | Enum | `Milestone` \| `Date` \| `PercentComplete` \| `Manual` |
| `triggerValue` | String | Milestone name, ISO date, or percentage (as string, e.g. "80") |
| `retentionRate` | Decimal | e.g. 0.10 for 10% |
| `retentionHeld` | Decimal | Calculated when claim is submitted |
| `retentionReleased` | Decimal | Cumulative retention released for this stage |
| `status` | Enum | See Stage Status Machine below |
| `claimId` | String? | Set when a claim is raised against this stage |

**Invariants:**
- `scheduledValue >= 0`
- `retentionRate` between 0 and 1
- Only one claim per stage
- Stage cannot be claimed if job is not `InProgress` or `Completed`

---

### 1.3 WorkPackage

A unit of on-site execution assigned to a site manager.

| Field | Type | Notes |
|---|---|---|
| `packageId` | String | UUID |
| `jobId` | String | Parent job |
| `siteManagerId` | String | Cognito userId of assigned site manager |
| `description` | String | Scope of this package |
| `plannedStart` | Date | |
| `plannedEnd` | Date | |
| `resources` | Resource[] | Crew size, equipment list (see Value Objects) |
| `relatedStageIds` | String[] | Stages that this work package contributes to |
| `status` | Enum | `Pending` \| `Active` \| `VariationPending` \| `Completed` |
| `notes` | String? | |
| `createdAt` | DateTime | |
| `updatedAt` | DateTime | |

**Invariants:**
- `plannedEnd >= plannedStart`
- Only one active `siteManagerId` at a time
- Cannot be marked `Completed` while Tasks of type `UpdateWorkPlan` are still `Pending`

---

### 1.4 Quote

A priced offer submitted to the client.

| Field | Type | Notes |
|---|---|---|
| `quoteId` | String | UUID |
| `jobId` | String | Parent job |
| `lineItems` | LineItem[] | See Value Objects |
| `exclusions` | String[] | Free-text list of exclusions |
| `assumptions` | String[] | Free-text assumptions |
| `total` | Decimal | Must equal sum of line item amounts |
| `validUntil` | Date | Quote expiry date |
| `status` | Enum | `Draft` \| `Submitted` \| `DocumentSent` \| `Accepted` \| `Rejected` |
| `documentS3Key` | String? | S3 key of the generated quote PDF |
| `documentSentAt` | DateTime? | When the document was sent to the client |
| `acceptedAt` | DateTime? | When admin recorded client acceptance |
| `rejectedAt` | DateTime? | |
| `notes` | String? | Internal notes |

**Invariants:**
- `total` = sum of `lineItems[].amount`
- Only one `Accepted` quote per job
- An `Accepted` quote cannot be accepted after `validUntil`
- Quote cannot advance past `Submitted` without a document being sent

---

### 1.5 Variation

A formal record of a scope change request and its resolution.

| Field | Type | Notes |
|---|---|---|
| `variationId` | String | UUID (e.g. "V001") |
| `jobId` | String | Parent job |
| `workPackageId` | String? | Affected work package |
| `description` | String | What changed |
| `reason` | String | Source of change (e.g. "Client site instruction", "Design change", "Unexpected conditions") |
| `clientInitiated` | Boolean | True if the client requested this change |
| `clientContactName` | String? | Name of client contact who requested the change |
| `price` | Decimal | Cost impact (NZD ex. GST) |
| `timeImpactDays` | Integer | Time impact in days (positive = extension, negative = reduction) |
| `status` | Enum | `Logged` \| `PricedUp` \| `DocumentSent` \| `Approved` \| `Declined` |
| `approvedByUserId` | String? | Admin userId who recorded approval |
| `documentS3Key` | String? | S3 key of the generated variation PDF |
| `documentSentAt` | DateTime? | |
| `approvedAt` | DateTime? | |
| `declinedAt` | DateTime? | |
| `evidence` | String[] | S3 keys of supporting photos, site instruction PDFs |

**Invariants:**
- `price >= 0`
- `status` cannot reach `Approved` without having been `DocumentSent` first (ensures client was informed)
- Only `Approved` variations affect `Job.totalContractValue`
- Cannot approve if job is `Closed`

---

### 1.6 StageClaim

A payment claim submitted against a specific stage.

| Field | Type | Notes |
|---|---|---|
| `claimId` | String | UUID |
| `stageId` | String | The stage being claimed |
| `jobId` | String | Parent job |
| `periodDescription` | String | Human label e.g. "March 2026" or "Stage 2 Milestone" |
| `measuredWork` | MeasuredItem[] | Quantities completed per scope item |
| `variationsIncluded` | String[] | variationIds included in this claim |
| `stageValue` | Decimal | Scheduled value of the stage |
| `workCompletedValue` | Decimal | Calculated from measured work |
| `variationsValue` | Decimal | Sum of included approved variation prices |
| `grossClaimValue` | Decimal | `workCompletedValue + variationsValue` |
| `retentionHeld` | Decimal | `grossClaimValue * stage.retentionRate` |
| `claimTotal` | Decimal | `grossClaimValue - retentionHeld` |
| `status` | Enum | `Draft` \| `DocumentSent` \| `Paid` |
| `documentS3Key` | String? | S3 key of generated PDF |
| `documentSentAt` | DateTime? | |
| `paidAt` | DateTime? | |
| `paidAmount` | Decimal? | Actual amount received |
| `evidence` | String[] | S3 keys of supporting photos, measurements |
| `notes` | String? | |

**Invariants:**
- `claimTotal >= 0`
- Only one claim per stage
- Cannot submit if job is not `InProgress` or `Completed`
- `claimTotal` = `grossClaimValue - retentionHeld`

---

### 1.7 DailyLog

A site manager's daily progress report.

| Field | Type | Notes |
|---|---|---|
| `logId` | String | UUID |
| `workPackageId` | String | Parent work package |
| `jobId` | String | Denormalised for query convenience |
| `siteManagerId` | String | Who submitted the log |
| `date` | Date | Defaults to today; must be within work package active period |
| `labourEntries` | LabourEntry[] | Per-person hours or total (see Value Objects) |
| `materialsUsed` | MaterialEntry[] | Optional |
| `progressNotes` | String | Free text |
| `scopeProgress` | ScopeProgress[] | Quantities completed today per scope item |
| `photos` | String[] | S3 keys |
| `issues` | Issue[] | Any defects or issues logged today |
| `weatherConditions` | String? | Optional |
| `createdAt` | DateTime | |

**Invariants:**
- `labourEntries[].hours >= 0`
- `date` must be within `workPackage.plannedStart` to `workPackage.plannedEnd` (or within a grace period if work extends)
- One log per `workPackageId` per `date` per `siteManagerId`

---

### 1.8 Task

A system-generated action required from a staff member.

| Field | Type | Notes |
|---|---|---|
| `taskId` | String | UUID |
| `assigneeId` | String | Cognito userId (site manager or admin) |
| `type` | Enum | `UpdateWorkPlan` \| `CompleteMobilisationChecklist` \| `ResolveDefect` \| `ReviewVariation` |
| `referenceId` | String | ID of the triggering entity (e.g. `variationId`, `defectId`) |
| `description` | String | Human-readable instruction |
| `status` | Enum | `Pending` \| `InProgress` \| `Completed` |
| `dueDate` | Date? | Optional deadline |
| `completedAt` | DateTime? | |
| `notes` | String? | Completion notes from assignee |
| `createdAt` | DateTime | |

**Invariants:**
- A `WorkPackage` with status `VariationPending` cannot return to `Active` until all `UpdateWorkPlan` tasks for that variation are `Completed`

---

## 2. Value Objects

| Value Object | Fields |
|---|---|
| `LineItem` | description, quantity, unit (m²\|lm\|units), rate, amount |
| `MeasuredItem` | scopeItem, completedToDate, unit, rate, value |
| `LabourEntry` | personName (optional), hours |
| `MaterialEntry` | description, quantity, unit |
| `ScopeProgress` | scopeItem, quantityToday, cumulativeQuantity, unit |
| `Resource` | type (Labour\|Equipment\|Material), description, quantity |
| `Issue` | description, severity (Minor\|Major\|Critical), photos[], resolvedAt |
| `Money` | amount (Decimal), currency (NZD) |
| `DateRange` | start (Date), end (Date) |

---

## 3. State Machines

### 3.1 Job Status

```
[*] --> Enquiry
Enquiry --> Quoted:             QuoteDocumentSent
Quoted --> Contracted:          QuoteAcceptedRecorded
Contracted --> Mobilised:       MobilisationCompleted
Mobilised --> InProgress:       WorkStarted (first DailyLog or manual trigger)
InProgress --> VariationPending: VariationApproved (while UpdateWorkPlan task outstanding)
VariationPending --> InProgress: UpdateWorkPlan task Completed
InProgress --> Completed:       PracticalCompletionIssued
Completed --> Closed:           FinalAccountClosed
```

---

### 3.2 Stage Status

```
[*] --> Pending
Pending --> Active:        Job reaches InProgress + this stage's sequence is next
Active --> ClaimDraft:     Trigger condition met (milestone / date / % / manual)
ClaimDraft --> DocumentSent: Claim document sent to client
DocumentSent --> Paid:     Admin records payment received
```

---

### 3.3 WorkPackage Status

```
[*] --> Pending
Pending --> Active:           WorkPackageAssigned + mobilisation complete
Active --> VariationPending:  VariationApproved (UpdateWorkPlan task created)
VariationPending --> Active:  UpdateWorkPlan task Completed
Active --> Completed:         Site manager marks complete (no outstanding tasks)
```

---

### 3.4 Quote Status

```
[*] --> Draft
Draft --> Submitted:       Admin submits
Submitted --> DocumentSent: Quote document sent to client
DocumentSent --> Accepted: Admin records client acceptance
DocumentSent --> Rejected: Admin records client rejection
```

---

### 3.5 Variation Status

```
[*] --> Logged
Logged --> PricedUp:       Admin prices the variation
PricedUp --> DocumentSent: Variation document sent to client
DocumentSent --> Approved: Admin records client approval
DocumentSent --> Declined: Admin records client decline
```

---

### 3.6 StageClaim Status

```
[*] --> Draft
Draft --> DocumentSent:  Claim document sent to client
DocumentSent --> Paid:   Admin records payment received
```

---

### 3.7 Task Status

```
[*] --> Pending
Pending --> InProgress:   Assignee starts the task
InProgress --> Completed: Assignee marks complete
Pending --> Completed:    (direct completion for simple tasks)
```

---

## 4. Domain Events

Each event is a JSON payload published to the EventBridge domain bus (`SubcontractorDomainBus`).

| Event | Trigger | Consumers |
|---|---|---|
| `JobCreated` | Admin creates a job | Dashboard refresh |
| `QuoteSubmitted` | Admin submits quote | — |
| `QuoteDocumentSent` | Quote PDF sent to client | Notification to admin confirming send |
| `QuoteAcceptedRecorded` | Admin records acceptance | Job → Contracted |
| `QuoteRejectedRecorded` | Admin records rejection | Job stays Quoted (admin action required) |
| `ContractSigned` | Admin uploads signed contract | Job → Contracted |
| `StagesDefined` | Admin saves stage structure | — |
| `WorkPackageCreated` | Admin creates work package | — |
| `WorkPackageAssigned` | Admin assigns site manager | Email notification to site manager |
| `MobilisationCompleted` | Checklist complete | Job → InProgress eligible |
| `WorkStarted` | First daily log or manual trigger | Job → InProgress |
| `ProgressUpdated` | Daily log saved | Stage % complete recalculated |
| `IssueLogged` | Issue added to daily log | Notification to admin |
| `VariationLogged` | Admin logs variation | — |
| `VariationDocumentSent` | Variation PDF sent to client | Notification to admin confirming send |
| `VariationApproved` | Admin records approval | Contract value updated; WorkPackageTaskCreated |
| `VariationDeclined` | Admin records decline | Variation closed |
| `WorkPackageTaskCreated` | System creates task | Notification to site manager |
| `TaskCompleted` | Site manager completes task | WorkPackage back to Active |
| `StageTriggerReached` | Trigger condition met | Notification to admin: "Stage X ready to claim" |
| `StageClaimCreated` | Admin creates claim | — |
| `StageClaimDocumentSent` | Claim PDF sent to client | Notification to admin confirming send |
| `StageClaimPaid` | Admin records payment | Retention updated; stage closed |
| `RetentionReleased` | Partial or full retention release recorded | Financial report updated |
| `PracticalCompletionIssued` | Admin records PC | Job → Completed |
| `FinalAccountClosed` | Admin closes final account | Job → Closed |

---

## 5. DynamoDB Single-Table Design

**Table:** `SubcontractorCore`

| Entity | PK | SK |
|---|---|---|
| Job | `JOB#<jobId>` | `META` |
| Stage | `JOB#<jobId>` | `STAGE#<sequence>#<stageId>` |
| WorkPackage | `JOB#<jobId>` | `PACKAGE#<packageId>` |
| Quote | `JOB#<jobId>` | `QUOTE#<quoteId>` |
| Variation | `JOB#<jobId>` | `VARIATION#<variationId>` |
| StageClaim | `JOB#<jobId>` | `CLAIM#<stageId>#<claimId>` |
| DailyLog | `PKG#<packageId>` | `LOG#<date>#<logId>` |
| Task | `USER#<userId>` | `TASK#<taskId>` |

**Secondary Indexes:**

| Index | PK | SK | Use Case |
|---|---|---|---|
| GSI1 (by status) | `STATUS#<status>` | `JOB#<jobId>` | All jobs by status |
| GSI2 (by client) | `CLIENT#<clientName>` | `JOB#<jobId>` | All jobs for a client |
| GSI3 (by claim status + date) | `CLAIMSTATUS#<status>` | `SENT#<sentAt>` | All outstanding/paid claims |
| GSI4 (by site manager) | `SM#<siteManagerId>` | `PKG#<packageId>` | All packages for a site manager |
