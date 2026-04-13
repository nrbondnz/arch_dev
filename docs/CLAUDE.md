# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ARCH Developments Sub-Contractor Management System — manages the full lifecycle of subcontractor work on building projects (enquiry, quoting, variations, progress claims, completion, retention release). The primary user is a brick/stone sub-contractor working mobile-first on construction sites.

Three reference docs live in the repo root:
- **ARCH-Requirements.md** — 82 functional requirements + 5 NFRs
- **ARCH-Design.md** — architecture, API, DynamoDB schema, Step Functions, frontend screens
- **ARCH-Design-Review.md** — gap analysis, risk assessment, and 6-phase implementation plan

## Tech Stack

**Frontend:** Flutter (Dart) targeting web primarily, with iOS/Android capability. Uses Material 3 with a blue brand color (`0xFF1A56DB`).

**Backend:** AWS Amplify Gen 2 (TypeScript-based config in `amplify/`):
- Auth: Cognito (email login) — `amplify/auth/resource.ts`
- Data: Amplify Data with `amplify/data/resource.ts` (currently a placeholder Todo schema, needs replacing with domain models)
- The Amplify config generates `lib/amplify_outputs.dart` (gitignored, generated at build time)

**Key dependencies:** `amplify_flutter`, `amplify_auth_cognito`, `amplify_authenticator`, `amplify_api`

## Build & Development Commands

```bash
# Install Dart dependencies
flutter pub get

# Install Amplify/Node dependencies
npm install

# Run the app (web)
flutter run -d chrome

# Run the app (iOS simulator)
flutter run

# Build for web release
flutter build web --release

# Run static analysis
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Amplify sandbox (local backend dev)
npx ampx sandbox
```

## Architecture

### Flutter App Structure

```
lib/
  main.dart                          # App entry, Amplify config, auth wrapper, landing page
  amplify_outputs.dart               # Generated — do not edit
  models/                            # Amplify-generated model classes (currently Todo placeholder)
  screens/
    role_select_screen.dart           # Post-login role picker (Sub-contractor / Main Contractor / QS)
    subcontractor/                    # Sub-contractor flows
      dashboard_screen.dart           # Main dashboard with summary tiles, quick actions, activity feed
      job_list_screen.dart            # Job listing
      job_detail_screen.dart          # Single job view
      quote_builder_screen.dart       # Line-item quote creation
      daily_log_screen.dart           # Daily progress logging
      variation_form_screen.dart      # Variation request form
      progress_claim_screen.dart      # Progress claim builder
    contractor/
      dashboard_screen.dart           # MC/QS approvals view (tabbed: Quotes, Variations, Claims)
  widgets/
    status_badge.dart                 # Shared StatusBadge widget + JobStatus enum
    summary_tile.dart                 # Dashboard summary card widget
```

### Auth Flow
`main.dart` wraps the app in Amplify's `Authenticator` widget with a custom landing page (sign in / create account). After auth, `RoleSelectScreen` lets the user pick their role (sub-contractor, main contractor, or QS). Role selection currently uses client-side navigation — no server-side role enforcement yet.

### Amplify Backend (`amplify/`)
- `backend.ts` — entry point, registers auth + data
- `auth/resource.ts` — Cognito with email login
- `data/resource.ts` — GraphQL data schema (currently Todo placeholder; needs domain model: Job, Quote, Variation, ProgressClaim, DailyLog)

### CI/CD
`amplify.yml` defines the AWS Amplify Hosting build pipeline: installs Flutter, generates `amplify_outputs.dart`, builds web release. Output artifact is `build/web`.

## Current State

The app has UI scaffolding for all major screens with hardcoded sample data. No backend data integration exists yet — all screens render static placeholder content. The Amplify data schema is still the default Todo model and needs to be replaced with the domain schema from ARCH-Design.md.

**Phase 1 goal (current branch):** Jobs + Quotes — CDK/Amplify backend, Jobs CRUD, Quotes CRUD + submit, dashboard with live data, quote builder flow, domain events (JobCreated, QuoteSubmitted).

## Domain Conventions

- **Brand color:** `Color(0xFF1A56DB)` (dark blue). Secondary colors: green `0xFF0E9F6E` (MC), amber `0xFFE3A008` (QS), purple for variations.
- **Status enum:** `JobStatus` in `lib/widgets/status_badge.dart` — used across all approval flows.
- **Currency:** NZD, displayed as `$X,XXX.XX ex. GST`.
- **Measurements:** m² (square metres), lm (linear metres), units.
