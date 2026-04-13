# ARCH Developments — API Design

Base path: `/v1`

All endpoints require a valid Cognito JWT in the `Authorization: Bearer <token>` header. Role-based access is enforced per endpoint (see notes).

---

## Jobs

```
POST   /jobs                              # Admin only
GET    /jobs                              # Admin: all jobs; Site manager: own assigned jobs only
GET    /jobs/{jobId}                      # Admin: any; Site manager: assigned only
PATCH  /jobs/{jobId}                      # Admin only (status, client details, contract terms)
```

### POST /jobs — Create Job

**Request:**
```json
{
  "clientName": "Apex Construction Ltd",
  "clientContactName": "Dave Wilson",
  "clientEmail": "dave@apexconstruction.co.nz",
  "clientPhone": "+64 9 555 0100",
  "siteAddress": "14 Hillcrest Road, Auckland",
  "description": "Blockwork and brickwork — residential development",
  "contractType": "LumpSum"
}
```

**Response:** `201 Created` with full Job object. Job `status` set to `Enquiry`.

---

## Stages

```
POST   /jobs/{jobId}/stages               # Admin only
GET    /jobs/{jobId}/stages               # Admin + Site manager (assigned jobs)
GET    /stages/{stageId}                  # Admin + Site manager (assigned)
PATCH  /stages/{stageId}                  # Admin only (before job reaches Contracted)
```

### POST /jobs/{jobId}/stages — Define Stage

**Request:**
```json
{
  "sequence": 1,
  "description": "Stage 1 — Block foundation",
  "scheduledValue": 18500,
  "triggerType": "Milestone",
  "triggerValue": "Foundation inspection passed",
  "retentionRate": 0.10
}
```

**Response:** `201 Created` with Stage object.

---

## Work Packages

```
POST   /jobs/{jobId}/work-packages        # Admin only
GET    /jobs/{jobId}/work-packages        # Admin: all; Site manager: own only
GET    /work-packages/{packageId}         # Admin: any; Site manager: own only
PATCH  /work-packages/{packageId}         # Admin: all fields; Site manager: status only (complete)
POST   /work-packages/{packageId}/assign  # Admin only — assign/reassign site manager
```

### POST /jobs/{jobId}/work-packages — Create Work Package

**Request:**
```json
{
  "description": "Block foundation work — north wing",
  "plannedStart": "2026-05-01",
  "plannedEnd": "2026-05-20",
  "resources": [
    { "type": "Labour", "description": "Blocklayers", "quantity": 3 },
    { "type": "Equipment", "description": "Mixer", "quantity": 1 }
  ],
  "relatedStageIds": ["STAGE-001"]
}
```

### POST /work-packages/{packageId}/assign — Assign Site Manager

**Request:**
```json
{
  "siteManagerId": "cognito-user-id-123"
}
```

---

## Quotes

```
POST   /jobs/{jobId}/quotes               # Admin only
GET    /jobs/{jobId}/quotes               # Admin only
GET    /quotes/{quoteId}                  # Admin only
PATCH  /quotes/{quoteId}                  # Admin only (while Draft)
POST   /quotes/{quoteId}/submit           # Admin only — sets status Submitted
POST   /quotes/{quoteId}/send-document    # Admin only — generates PDF, emails client
POST   /quotes/{quoteId}/record-accepted  # Admin only — records client acceptance
POST   /quotes/{quoteId}/record-rejected  # Admin only — records client rejection
```

### POST /jobs/{jobId}/quotes — Create Quote

**Request:**
```json
{
  "lineItems": [
    { "description": "Bricklaying", "quantity": 120, "unit": "m2", "rate": 85 }
  ],
  "exclusions": ["Scaffolding", "Site toilet"],
  "assumptions": ["Materials supplied by main contractor"],
  "validUntil": "2026-05-01"
}
```

### POST /quotes/{quoteId}/send-document

Generates the quote PDF, stores in S3, and sends to `job.clientEmail` via SES (or returns a shareable link).

**Request:**
```json
{
  "deliveryMethod": "email"
}
```

**Response:**
```json
{
  "documentS3Key": "quotes/Q123/quote-v1.pdf",
  "shareableLink": "https://...",
  "sentAt": "2026-04-12T09:00:00Z"
}
```

### POST /quotes/{quoteId}/record-accepted

**Request:**
```json
{
  "acceptedAt": "2026-04-14T14:00:00Z",
  "notes": "Client confirmed via email"
}
```

---

## Variations

```
POST   /jobs/{jobId}/variations           # Admin only
GET    /jobs/{jobId}/variations           # Admin: all; Site manager: assigned job only
GET    /variations/{variationId}          # Admin + Site manager (assigned job)
PATCH  /variations/{variationId}          # Admin only (while Logged or PricedUp)
POST   /variations/{variationId}/send-document   # Admin only
POST   /variations/{variationId}/record-approved # Admin only
POST   /variations/{variationId}/record-declined # Admin only
```

### POST /jobs/{jobId}/variations — Log Variation

**Request:**
```json
{
  "workPackageId": "PKG-001",
  "description": "Extra brick pier to support relocated lintel",
  "reason": "Client site instruction",
  "clientInitiated": true,
  "clientContactName": "Dave Wilson",
  "price": 450,
  "timeImpactDays": 1
}
```

**Response:** `201 Created`. Status set to `Logged`.

### POST /variations/{variationId}/record-approved

Records that the client approved the variation (communicated outside the system). This:
- Sets `variation.status = Approved`
- Updates `job.totalContractValue += variation.price`
- Updates `workPackage.plannedEnd += variation.timeImpactDays` (if `workPackageId` set)
- Creates a `Task` of type `UpdateWorkPlan` for the assigned site manager

**Request:**
```json
{
  "approvedAt": "2026-04-15T10:00:00Z",
  "notes": "Client approved by email"
}
```

---

## Stage Claims

```
POST   /stages/{stageId}/claims           # Admin only
GET    /stages/{stageId}/claims           # Admin only
GET    /claims/{claimId}                  # Admin only
PATCH  /claims/{claimId}                  # Admin only (while Draft)
POST   /claims/{claimId}/send-document    # Admin only — generates PDF, sends to client
POST   /claims/{claimId}/record-paid      # Admin only — records payment received
```

### POST /stages/{stageId}/claims — Create Stage Claim

**Request:**
```json
{
  "periodDescription": "Stage 1 — May 2026",
  "variationsIncluded": ["V001", "V002"]
}
```

Backend auto-populates `measuredWork` from daily logs for the associated work packages and stage. Returns draft claim with pre-calculated financial summary.

### POST /claims/{claimId}/send-document

Generates claim PDF, stores in S3, emails to client or returns shareable link.

### POST /claims/{claimId}/record-paid

**Request:**
```json
{
  "paidAt": "2026-05-20T00:00:00Z",
  "paidAmount": 14850,
  "notes": "Payment received via bank transfer"
}
```

---

## Daily Logs

```
POST   /work-packages/{packageId}/daily-logs   # Site manager (own packages)
GET    /work-packages/{packageId}/daily-logs   # Admin + Site manager (own packages)
GET    /daily-logs/{logId}                     # Admin + Site manager (own packages)
```

### POST /work-packages/{packageId}/daily-logs — Submit Daily Log

**Request:**
```json
{
  "date": "2026-05-03",
  "labourEntries": [
    { "personName": "Craig", "hours": 8 },
    { "personName": "Sam", "hours": 8 }
  ],
  "materialsUsed": [
    { "description": "Bricks", "quantity": 500, "unit": "units" }
  ],
  "progressNotes": "Completed east wall to plate height. Minor alignment issue on NE corner resolved.",
  "scopeProgress": [
    { "scopeItem": "Brickwork", "quantityToday": 18, "cumulativeQuantity": 62, "unit": "m2" }
  ],
  "photos": ["photos/PKG-001/20260503-001.jpg"],
  "issues": []
}
```

---

## Documents (Upload)

```
POST   /jobs/{jobId}/upload-url           # Admin + Site manager (own jobs)
```

### POST /jobs/{jobId}/upload-url — Get Pre-signed Upload URL

Returns a pre-signed S3 PUT URL. Client uploads file directly to S3. The returned `documentId` is used in subsequent requests (daily logs, variations, claims) to link the document.

**Request:**
```json
{
  "filename": "site-photo-001.jpg",
  "contentType": "image/jpeg",
  "context": "dailylog"
}
```

**Response:**
```json
{
  "uploadUrl": "https://s3.amazonaws.com/...",
  "documentId": "photos/PKG-001/site-photo-001.jpg",
  "expiresAt": "2026-05-03T10:15:00Z"
}
```

---

## Tasks

```
GET    /tasks                             # Filtered by assigneeId (own tasks) or admin sees all
PATCH  /tasks/{taskId}                    # Assignee marks in-progress or complete
```

### GET /tasks

Query parameters:
- `status=Pending|InProgress|Completed`
- `assigneeId=<userId>` (admin only — view another user's tasks)
- `type=UpdateWorkPlan|CompleteMobilisationChecklist|ResolveDefect`

### PATCH /tasks/{taskId}

**Request:**
```json
{
  "status": "Completed",
  "notes": "Revised work plan updated — end date moved to 22 May, added one extra blocklayer"
}
```

---

## Notifications (Document Sends)

All document-send endpoints (`/send-document`) accept an optional `deliveryMethod` field:

| Value | Behaviour |
|---|---|
| `email` | Send PDF to `job.clientEmail` via SES (default) |
| `link` | Return a time-limited shareable URL; do not email |
| `both` | Email and return link |

---

## Error Responses

All errors return:
```json
{
  "error": "VARIATION_NOT_PRICED",
  "message": "Variation must be priced before a document can be sent",
  "statusCode": 422
}
```

Common error codes:
- `JOB_NOT_FOUND` — 404
- `INVALID_STATUS_TRANSITION` — 422
- `QUOTE_EXPIRED` — 422
- `CLAIM_PERIOD_OVERLAP` — 422
- `VARIATION_JOB_CLOSED` — 422
- `TASK_OUTSTANDING` — 422 (e.g. cannot complete work package while tasks are pending)
- `UNAUTHORIZED_ROLE` — 403
- `PACKAGE_NOT_ASSIGNED` — 403 (site manager accessing unassigned package)
