# Roadmap

## 0.1.0 — Core intent, hashing, challenge, audit assertion

- `TransactionIntent`
- `TransactionIntentType`
- `CanonicalJsonEncoder`
- `OperationTermsHasher`
- `IntentChallenge`
- `AuthenticatorConfirmation`
- `LivenessInteractionSummary`
- `SignedAuditAssertion`
- `DemoHmacSigner` / `DemoHmacVerifier`
- README, docs, tests, example

## 0.2.0 — Better assertion schema and verifier

- Stronger validation result model (`failureCode`, `checks`)
- More assertion metadata (`AssertionMetadata`, `schemaVersion`)
- JWS-style assertion format exploration (`CompactAssertionEnvelope`)
- More tamper detection tests
- More documentation around audit trails (`doc/AUDIT_TRAILS.md`)

## 0.3.0 — Integration examples

- Example mapping from `flutter_liveness_actions` audit event to
  `LivenessInteractionSummary` (`LivenessSummaryMapper` + example)
- Example backend validator in Dart
- Remote lending demo flow
- Large transfer demo flow
- Security settings demo flow

## 0.4.0 — Mobile reference app support

- Shared models for Flutter demo app (`DemoConfirmationSession`)
- Copy/share assertion helpers (`AssertionShareHelper`)
- Better pretty JSON output (`PrettyJsonOptions`, `prettyCanonicalJson`)
- Demo dashboard schema (`DemoDashboardSnapshot`, `tis_demo_dashboard_v1`)

## 1.0.0 — Stable API

- API review
- SemVer stability docs
- More examples
- CI
- pub.dev release readiness
- external technical review feedback incorporated
