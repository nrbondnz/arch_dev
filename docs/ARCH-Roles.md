# ARCH Developments — Roles

## 1. Internal Roles (System Users)

### 1.1 Admin / Manager

The Admin/Manager role represents the sub-contracting business owner or office manager. This role has full system access and is the primary decision-maker for all business transactions.

**Responsibilities:**
- Create and manage jobs
- Build and submit quotes to clients
- Define contract terms, stages, and stage payment triggers at contract time
- Create and assign work packages to site managers
- Log and price variation requests received from clients
- Send variation documents to clients and record their approval or rejection
- Review and submit stage payment claims
- Send claim documents to clients and record payments received
- Manage mobilisation checklists
- Oversee practical completion and final account close-out
- Review all documents (insurance certificates, RAMS, contracts)

**System access:**
- Full read/write on all jobs, stages, work packages, quotes, variations, claims, daily logs
- Can create and deactivate site manager accounts
- Can send documents (quotes, variations, claims) to clients via email or shareable link
- Can record client responses (quote accepted/rejected, variation approved/declined, payment received)
- Can approve variations internally
- Can view all tasks assigned to any site manager
- Can reassign a work package to a different site manager

**Future extensions:**
- **Document Manager** sub-role: manages RAMS, insurance certificates, contracts, plan uploads (subset of Admin permissions focused on document management)
- **Payments Manager** sub-role: manages stage claims, tracks payments, handles retention (subset of Admin permissions focused on billing)

---

### 1.2 Site Manager

The Site Manager is a sub-contractor employee responsible for one or more work packages on site. Their view is scoped to what they are assigned to.

**Responsibilities:**
- Execute work according to the work package plan (timescales, resources)
- Submit daily log reports (labour, materials, progress, photos)
- Log issues and defects encountered during execution
- Complete tasks assigned by the system (e.g. update work plan after a variation is approved)
- Attend to defects during the defects liability period

**System access:**
- Read-only on job summary and contract details for their assigned jobs
- Read/write on daily logs for their assigned work packages
- Read on stage progress for their assigned work packages
- Read/write on their own assigned tasks
- Read on variations affecting their work packages
- Upload documents (photos, site evidence) attached to daily logs or variations
- Cannot create jobs, quotes, variations, or claims
- Cannot send documents to clients
- Cannot record client responses

**Work package assignment:**
- A site manager can be assigned to multiple work packages (sequential or parallel)
- Only one site manager is assigned to a given work package at any time
- The Admin reassigns a work package by updating the `siteManagerId` field; the previous site manager loses write access

---

## 2. External Party (Not a System User)

### 2.1 Client (Main Contractor)

The client is an external entity in the data model. They do not have a login or any system access.

**How the client interacts with the system:**
- Receives documents sent by the Admin: quotes, variation pricing documents, stage claim documents
- Documents are delivered by email (SES) or a read-only shareable link (time-limited, pre-signed)
- Responds via phone, email, or in-person — the Admin records the outcome in the app
- Has no ability to approve, reject, or modify anything directly in the system

**Client data stored per job:**
- `clientName` — company name
- `clientContactName` — primary contact person
- `clientEmail` — for document delivery
- `clientPhone` — for reference

---

## 3. Role Summary Matrix

| Capability | Admin / Manager | Site Manager |
|---|---|---|
| Create / edit jobs | Yes | No |
| Define stages and payment triggers | Yes | No |
| Create work packages | Yes | No |
| Assign site managers to work packages | Yes | No |
| Build and submit quotes | Yes | No |
| Send documents to client | Yes | No |
| Record client responses | Yes | No |
| Log variation requests | Yes | No |
| Price and approve variations | Yes | No |
| Create stage claims | Yes | No |
| Mark stage payments received | Yes | No |
| Submit daily logs | No (can view) | Yes (own packages) |
| Upload site photos / evidence | No (can view) | Yes (own packages) |
| Complete work plan update tasks | No (assigns) | Yes (own tasks) |
| View all jobs | Yes | Own assigned only |
| View all work packages | Yes | Own assigned only |
| Manage user accounts | Yes | No |

---

## 4. Authentication

- All users authenticate via AWS Cognito (email + password)
- Cognito user pool groups: `admin-manager`, `site-manager`
- API Gateway uses a Cognito authorizer; Lambda functions inspect the `cognito:groups` claim to enforce role-based access
- A site manager's access is further filtered by their `userId` — they can only read/write records where `siteManagerId = their userId`
