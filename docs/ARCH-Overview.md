# ARCH Developments — System Overview

## 1. Purpose

ARCH is a sub-contractor management system built for and owned by the **sub-contracting business**. Every feature, workflow, and data model exists to serve the sub-contractor's business operations: winning work, executing it, managing change, and getting paid.

The system does **not** provide portals or accounts for main contractors or quantity surveyors. Clients (main contractors) interact with the business through documents and notifications sent from the system — quotes, variation documents, stage claims — but they do not log in.

---

## 2. Core Design Principles

1. **Sub-contractor-centric** — all flows are viewed from the sub-contractor's perspective. "Job status" means *our* status on the engagement, not the client's view.
2. **Client is external** — the client (main contractor) is an entity in the data model, not a user. Communication is outbound: the system sends documents (email or shareable link). Negotiation and verbal agreements happen outside the system; outcomes are recorded by the admin.
3. **Stage-based work** — a contract is broken into stages defined at contract time. Each stage has a payment trigger, a scheduled value, and a retention rate. Progress claims are made against stages.
4. **Work packages are the unit of site execution** — a job's stages are delivered through one or more work packages. Each work package is assigned to a single site manager at any given time. Multiple work packages can run in parallel.
5. **Task enforcement** — when an event requires action (e.g. a variation is approved → work plan must be updated), the system creates a task for the responsible user. It does not silently allow the next step until the task is resolved.

---

## 3. User Roles

| Role | Who | Scope |
|---|---|---|
| **Admin / Manager** | Business owner, office manager | Full system access |
| **Site Manager** | On-site crew lead | Scoped to assigned work packages |

See [ARCH-Roles.md](ARCH-Roles.md) for full permissions.

---

## 4. High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Sub-contractor Staff                       │
│        Admin / Manager          Site Manager                 │
└───────────────┬─────────────────────────┬────────────────────┘
                │                         │
        ┌───────▼─────────────────────────▼───────┐
        │           Flutter Web App (PWA)          │
        │   Mobile-first · Offline-capable         │
        └───────────────────┬─────────────────────┘
                            │ HTTPS
        ┌───────────────────▼─────────────────────┐
        │         API Gateway (REST v1)            │
        │         Cognito JWT auth                 │
        └───────────────────┬─────────────────────┘
                            │
        ┌───────────────────▼─────────────────────┐
        │              Lambda Functions            │
        │  Jobs · Stages · WorkPackages · Quotes   │
        │  Variations · Claims · DailyLogs · Tasks │
        └──────┬──────────────────────┬────────────┘
               │                      │
    ┌──────────▼──────┐    ┌──────────▼──────────┐
    │   DynamoDB      │    │   EventBridge        │
    │   (SubcontractorCore)│   (DomainBus)         │
    └─────────────────┘    └──────────┬───────────┘
                                      │
               ┌──────────────────────┤
               │                      │
    ┌──────────▼──────┐    ┌──────────▼──────────┐
    │  Step Functions │    │  SNS / SES           │
    │  (job lifecycle)│    │  (document sends,    │
    │                 │    │   notifications to   │
    └─────────────────┘    │   client + staff)    │
                           └─────────────────────┘
```

### Client (External)

```
Client (main contractor)
        │
        │  receives email / shared link
        ▼
  Quote document
  Variation document
  Stage claim document
        │
        │  responds outside system (phone / email)
        ▼
  Admin records outcome in app
```

---

## 5. Technology Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) — web primary, iOS/Android capable |
| Hosting | S3 + CloudFront |
| Auth | AWS Cognito (email login, role groups) |
| API | API Gateway (HTTP REST, versioned `/v1`) |
| Compute | AWS Lambda (Node.js 20.x) |
| Workflows | AWS Step Functions (job lifecycle) |
| Events | AWS EventBridge (domain event bus) |
| Data | DynamoDB (single-table, PAY_PER_REQUEST) |
| Storage | S3 (documents, photos, generated PDFs) |
| Notifications | SNS + SES (email to staff and clients) |
| IaC | AWS CDK (TypeScript) |
| Observability | CloudWatch + X-Ray |

---

## 6. Document Index

| Document | Contents |
|---|---|
| [ARCH-Roles.md](ARCH-Roles.md) | Role definitions, permissions matrix |
| [ARCH-Process-Flows.md](ARCH-Process-Flows.md) | 8-stage engagement lifecycle |
| [ARCH-Data-Model.md](ARCH-Data-Model.md) | Domain entities, state machines, domain events |
| [ARCH-API.md](ARCH-API.md) | REST API endpoint reference |
| [ARCH-Infrastructure.md](ARCH-Infrastructure.md) | AWS architecture, CDK stacks, EventBridge rules |
| [ARCH-Frontend.md](ARCH-Frontend.md) | Screen designs and UX flows |
| [../ARCH-Requirements.md](../ARCH-Requirements.md) | Functional and non-functional requirements |
| [../ARCH-Design-Review.md](../ARCH-Design-Review.md) | Gap analysis, risks, phased implementation plan |
