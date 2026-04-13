# ARCH Developments — Frontend Design

## 1. Approach

- **Framework:** Flutter (Dart), web primary with iOS/Android capability
- **Design system:** Material 3, brand color `Color(0xFF1A56DB)` (dark blue)
- **Responsive:** mobile-first, optimised for phones used on construction sites
- **Offline:** PWA with service worker — daily logs and photo queuing work offline; sync on reconnect
- **Photo uploads:** S3 pre-signed URL flow (direct client-to-S3 upload)

Two distinct experiences share the same app, gated by role after login:
- **Admin / Manager experience** — full business management
- **Site Manager experience** — scoped to assigned work packages

---

## 2. Shared Screens

### 2.1 Login
- Email + password (Cognito)
- "Forgot password" via Cognito hosted flow
- On login, role checked from Cognito group → routed to correct dashboard

### 2.2 Role Select (if user has multiple roles)
- Simple role picker: "Admin / Manager" or "Site Manager"
- Rare edge case for users with both roles

---

## 3. Admin / Manager Screens

### 3.1 Admin Dashboard

**Header:** ARCH Developments logo + user name + hamburger menu

**Summary tiles (top row):**
- Active Jobs (count + status breakdown)
- Outstanding Stage Claims (count + total value)
- Pending Variations (count)
- Tasks Awaiting Completion (count, site managers)

**Sections:**
- **Jobs requiring action** — jobs with status changes needed (e.g. quote not yet sent, stage trigger reached)
- **Stage Triggers Ready** — stages whose trigger condition is met; tap to start claim
- **Variations Pending Document Send** — variations priced but document not yet sent to client
- **Claims Awaiting Payment** — claims in `DocumentSent` state with days elapsed

**Bottom action bar:**
- New Job | New Quote | Log Variation | New Stage Claim

---

### 3.2 Job List Screen

- Filter bar: status dropdown (All / Enquiry / Quoted / Contracted / InProgress / Completed / Closed)
- Job cards showing: site address, client name, status badge, contract value, next action label
- Tap → Job Detail

---

### 3.3 Job Detail Screen

**Header:** Job name / site address + status badge

**Tabs:**
1. **Overview** — client details, contract type, payment terms, total contract value, documents
2. **Stages** — stage list with status badges, scheduled values, retention rates, trigger type/value
3. **Work Packages** — work package list with site manager name, planned dates, status badges
4. **Quote** — current quote status; link to quote builder
5. **Variations** — list of variations with status badges and amounts
6. **Claims** — list of stage claims with status and amounts

**Action bar (context-sensitive):**
- Enquiry: "Build Quote"
- Quoted: "Send Quote Document" / "Record Acceptance"
- Contracted: "Define Stages" / "Create Work Package"
- InProgress: "New Variation" / "Start Stage Claim"

---

### 3.4 Quote Builder Screen

1. **Select or create job** — search existing jobs (Enquiry status) or start a new job
2. **Line items** — add rows: description, quantity, unit picker (m² / lm / units), rate, auto-calculated amount
3. **Exclusions** — add free-text exclusion lines
4. **Assumptions** — add free-text assumption lines
5. **Validity date** — date picker
6. **Running total** — always visible at bottom
7. **Review & Submit** — summary page: all line items, exclusions, assumptions, total; "Submit Quote" button
8. **After submit:** "Send Document to Client" button — select delivery method (email / link / both); confirmation shown with sent timestamp

---

### 3.5 Contract Setup Screen (after quote accepted)

Used to define the stage structure for the contract.

**Fields:**
- Contract type picker (Lump Sum / Schedule of Rates / Cost-Plus)
- Payment terms (free text, e.g. "20th of following month, 20 working days")

**Stages section:**
- Add stage rows: description, scheduled value, trigger type, trigger value, retention rate
- Running total showing sum vs. contract value (must match)
- Warning if sum of stage values ≠ total contract value

**Mobilisation checklist:**
- RAMS approved (checkbox)
- Insurance certificates on file (checkbox)
- Materials ordered (checkbox)
- Scaffolding / site access confirmed (checkbox)
- Site induction scheduled (checkbox)

---

### 3.6 Work Package Management Screen

- List of work packages for a job
- "Add Work Package" button
- Each package: description, planned dates, assigned site manager name, resources summary, status badge
- Tap package → edit details or reassign site manager
- Assign site manager: searchable dropdown of `site-manager` group users

---

### 3.7 Variation Form Screen

1. **Source** — toggle: "Client requested" or "Scope change identified on site"
2. **Client contact name** (if client-initiated)
3. **Affected work package** — dropdown of active packages for this job
4. **Description** — free text
5. **Reason** — dropdown: Client Site Instruction / Design Change / Unexpected Conditions / Other + free text
6. **Cost impact** — NZD ex. GST amount
7. **Time impact** — days (positive = extension, negative = reduction); 0 if no impact
8. **Evidence** — optional photo / PDF upload
9. **Save as Logged** → "Price Up & Send Document" button

**Send Document flow:**
- Preview of variation details
- Delivery method selector (email / link / both)
- Send → status becomes `DocumentSent`

**Record Outcome:**
- "Record Client Approval" button — sets `Approved`, triggers contract value update + site manager task
- "Record Client Decline" button — sets `Declined`

---

### 3.8 Stage Claim Builder Screen

**Header:** "Create Stage Claim — [Stage description]"

**Auto-populated sections:**
- **Measured Work Completed** — scope items with quantity completed (from daily logs), unit, rate, calculated value. Admin can adjust quantities (warning indicator shown if adjusted)
- **Approved Variations Included** — tick list of variations not yet claimed; each shows description and amount
- **Retention** — retention rate (from stage config), calculated hold amount

**Financial summary:**
- Stage Scheduled Value
- Work Completed Value
- Variations Included
- Gross Claim Value
- Retention Held
- **Claim Total** (prominent)

**Evidence** — optional: add supporting photos or measurement records

**Action:** "Generate & Send Claim Document" → delivery method selector → sends PDF to client

**After send:** status card shows "Document Sent", with sent date. "Record Payment Received" button when paid.

---

### 3.9 Record Payment Screen

Simple confirmation form:
- Payment date (date picker, defaults today)
- Amount received (NZD, pre-filled with claim total)
- Notes (e.g. "Received via bank transfer, ref 1234")
- "Mark as Paid" → updates stage to `Paid`, updates retention balance

---

### 3.10 Document Send Confirmation Screen

Shared pattern used after any document send (quote, variation, claim):
- Animated confirmation tick
- "Document sent to [client email]" (or "Shareable link created")
- Copy link button (if link delivery)
- "Back to [Job/Variation/Claim]" navigation

---

## 4. Site Manager Screens

### 4.1 Site Manager Dashboard

**Header:** ARCH Developments logo + "Hi [name]" + hamburger menu

**Pending Tasks tile** — count of outstanding tasks (highlighted if > 0, amber badge)

**My Work Packages section:**
- Card per assigned package showing: site address, job name, planned dates, status badge (Active / Variation Pending)
- Tap → Work Package Detail

**Today's Logs:**
- Indicator: "You have [n] active packages — tap to log today's progress"
- Quick-add daily log shortcut

---

### 4.2 Work Package Detail Screen

**Header:** Package description + job site address

**Tabs:**
1. **Overview** — planned dates, resources, related stages, site manager notes
2. **Daily Logs** — log history in reverse-chronological order; "Add Today's Log" button
3. **Variations** — read-only list of variations affecting this package
4. **Tasks** — outstanding tasks for this package (e.g. UpdateWorkPlan tasks)

---

### 4.3 Daily Log Screen

**Header:** "Daily Log — [date]" (date defaults to today, can backdate within grace period)

**Sections:**
- **Labour** — add person name (optional) + hours per person; or total-hours toggle
- **Materials** — optional; add description + quantity + unit
- **Progress** — scope item picker with quantity-today input (e.g. Brickwork: 18 m²); cumulative shown
- **Progress Notes** — free-text field
- **Photos** — camera/gallery upload; multiple photos; shows offline queue count if no connection
- **Issues / Defects** — "Add Issue" button → description, severity picker (Minor / Major / Critical), photo

**Save** — optimistic save (stores locally if offline, syncs when connected); confirmation toast

---

### 4.4 Task Detail Screen

Shown when a site manager taps an `UpdateWorkPlan` task (created after a variation is approved).

**Shows:**
- Variation description and approved price
- Time impact (e.g. "+1 day")
- Current work package planned end date
- "What needs updating" — instruction text

**Fields for site manager to fill:**
- Updated planned end date (date picker, pre-populated with original + time impact)
- Resources adjustment (optional free text, e.g. "Adding one extra blocklayer for 3 days")
- Notes

**Complete Task** button → task status → `Completed`; work package → `Active`

---

## 5. Shared Widgets

| Widget | Purpose |
|---|---|
| `StatusBadge` | Colour-coded pill for job, variation, claim, task status |
| `SummaryTile` | Dashboard metric card (count, label, optional trend) |
| `DocumentSendButton` | Standardised "Send to Client" button with delivery method modal |
| `RecordOutcomeButton` | Standardised "Record Approval / Record Decline" button pair |
| `OfflineBanner` | Top banner shown when device has no connectivity |
| `PhotoUploadTile` | Photo grid with camera/gallery picker and offline queue indicator |
| `LineItemRow` | Quote line item with quantity, unit, rate, auto-amount |
| `FinancialSummaryCard` | Breakdown of claim totals, retention, net claim |
| `TaskCard` | Task summary card with type icon, description, due date |

---

## 6. Status Badge Colour Scheme

| Status | Colour |
|---|---|
| Enquiry | Grey |
| Quoted / DocumentSent | Blue |
| Contracted | Teal |
| Mobilised | Cyan |
| InProgress / Active | Green |
| VariationPending | Amber |
| Completed | Dark Green |
| Closed | Grey (muted) |
| Rejected / Declined | Red |
| Paid | Green |
| Pending (task) | Amber |

---

## 7. Offline Strategy (PWA)

- **Service worker** caches app shell and static assets
- **IndexedDB** queues daily log submissions and photo uploads when offline
- **Background sync** API — uploads queued items when connectivity returns
- **Optimistic UI** — daily log appears saved immediately; sync status indicator shown
- **Offline banner** — displayed when `navigator.onLine = false`
- All other operations (creating jobs, sending documents) require connectivity and show an informative error if offline
