# Project Audit - Aqari

Date: 2026-04-03

## What The Project Is

Aqari is a Flutter application combining a real-estate workflow with legal-assistance features. The implemented code points to a Tunisia-focused product with three primary user roles: landlords, tenants, and lawyers.

The current product direction is not a generic property listing app. It is moving toward a transaction platform where property discovery, legal help, identity verification, and application workflows are all part of one system.

## Current Functional Scope

Implemented or substantially built:

- Authentication with email/password and Google sign-in
- Password reset flow
- Property listing, detail, creation, editing, and map view
- Property applications flow for users and owners
- Lawyer directory, lawyer detail, lawyer profile editing, and lawyer verification
- AI legal assistant backed by a chatbot service
- OCR-based onboarding steps
- Biometrics enrollment and gated splash flow
- Localization for Arabic, English, and French

Present but incomplete:

- Onboarding completion still logs collected data instead of submitting a final backend payload
- Contracts view is a placeholder
- Cases view is a placeholder
- Settings view is a placeholder
- Terms of service and privacy policy links are TODOs in signup

## Verification Performed

### 1. Workspace and architecture review

Reviewed the app structure under lib, the service layer, viewmodels, navigation shell, localization setup, and current API constants.

### 2. Static verification

Ran flutter analyze.

Result:

- No compile errors
- 23 informational issues
- Main issues are avoid_print, deprecated web camera import usage, and a few async context warnings

### 3. Automated test verification

Ran flutter test.

Result before cleanup:

- Failed because the repository still contained Flutter's default counter smoke test
- The failure was unrelated to your real application logic

Result after cleanup:

- Replaced the stale template test with a localization smoke test aligned with the current app

### 4. Build verification

Ran flutter build web.

Result:

- Build succeeded
- One warning reported that l10n.yaml still had a deprecated synthetic-package setting
- WebAssembly dry-run warnings came from flutter_secure_storage_web and do not block the standard web build

### 5. Repo cleanup completed

- Removed the deprecated synthetic-package line from l10n.yaml
- Replaced the broken default widget test with a real project smoke test

## Main Risks

1. Hard-coded backend URLs in lib/core/constants/api_constants.dart tie the app to one local network and one machine layout.
2. The app has almost no meaningful automated test coverage.
3. Several core product surfaces are still placeholders, especially contracts, cases, and settings.
4. Some debug-style print usage and async context patterns should be cleaned before production hardening.
5. The onboarding flow is visually complete, but its final submission path is not fully wired.

## Strategic Reading Of The Product Direction

The strongest signal in the codebase is this:

- Property marketplace
- Legal support layer
- Verified lawyer marketplace
- Identity and trust features

That means the project is heading toward a trust-heavy real-estate transaction platform rather than a simple listing app.

The most natural product direction from the current code is:

1. Property discovery and application management
2. Legal guidance and lawyer matching
3. Contract generation and signing
4. Case and dispute handling

In short, the codebase is already aimed at a vertically integrated proptech plus legaltech product.

## What To Do Next

Priority 1:

- Replace hard-coded API URLs with environment-based configuration
- Finish onboarding submission to backend
- Build real tests for auth, property flows, and API services

Priority 2:

- Implement the Settings screen
- Implement Contracts using the existing service groundwork
- Decide whether Cases is a real product pillar or just future scope

Priority 3:

- Remove production print statements and fix async context warnings
- Improve README and deployment documentation
- Add CI for analyze, test, and web build

## Recommended Execution Order

1. Environment config and deployment hygiene
2. Onboarding completion
3. Contract feature MVP
4. Test coverage expansion
5. Settings and cases prioritization based on actual business scope