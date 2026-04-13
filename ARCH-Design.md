# ARCH Developments — Design Index

This system is built **for and owned by the sub-contracting business**. Every feature manages the sub-contractor's engagement lifecycle — from winning work through to getting paid. The client (main contractor) is an external party who receives documents; they do not log into the system.

See [`docs/ARCH-Overview.md`](docs/ARCH-Overview.md) for the full system context and design principles.

---

## Design Documents

| Document | Description |
|---|---|
| [docs/ARCH-Overview.md](docs/ARCH-Overview.md) | System purpose, design principles, technology stack, component map |
| [docs/ARCH-Roles.md](docs/ARCH-Roles.md) | Internal roles (Admin/Manager, Site Manager), permissions matrix, client as external party |
| [docs/ARCH-Process-Flows.md](docs/ARCH-Process-Flows.md) | 8-stage engagement lifecycle with swimlanes (sub-contractor POV) |
| [docs/ARCH-Data-Model.md](docs/ARCH-Data-Model.md) | Domain entities, state machines, domain events, DynamoDB schema |
| [docs/ARCH-API.md](docs/ARCH-API.md) | REST API endpoint reference (base path `/v1`) |
| [docs/ARCH-Infrastructure.md](docs/ARCH-Infrastructure.md) | AWS CDK stacks, Lambda functions, EventBridge rules, Step Functions, PDF pipeline |
| [docs/ARCH-Frontend.md](docs/ARCH-Frontend.md) | Admin/Manager and Site Manager screen designs and UX flows |

---

## Supporting Documents

| Document | Description |
|---|---|
| [ARCH-Requirements.md](ARCH-Requirements.md) | Functional and non-functional requirements |
| [ARCH-Design-Review.md](ARCH-Design-Review.md) | Gap analysis, risks, phased implementation plan |

---

## Key Concepts at a Glance

**Roles:** Admin/Manager (full access) and Site Manager (scoped to assigned work packages). No external roles.

**Engagement flow:** Enquiry → Quote sent to client → Contract formed with defined stages → Work packages assigned to site managers → Daily execution → Variations logged and priced → Stage claims sent to client → Practical completion → Final account.

**Stages:** A contract is broken into payment stages at contract time. Each stage has a scheduled value, a payment trigger (milestone / date / % complete / manual), and a per-stage retention rate.

**Work packages:** The unit of on-site execution. One site manager per package at a time. Multiple packages can run in parallel within a job.

**Variations:** Logged by the admin after client contact, priced up, document sent to client, outcome recorded by admin. On approval the system updates the contract value and creates an "update work plan" task for the site manager.

**Client communications:** Outbound only — quote documents, variation documents, and stage claim documents are sent by email or shareable link. The client responds outside the system; the admin records the outcome.
