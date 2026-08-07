# transaction_intent_signer

[![pub package](https://img.shields.io/pub/v/transaction_intent_signer.svg)](https://pub.dev/packages/transaction_intent_signer)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Pure Dart package for building **audit-friendly transaction intent confirmation flows**.

It helps developers create intent sessions, hash transaction or loan terms, bind them to a server nonce and confirmation challenge, attach optional liveness-aware interaction summaries, and produce signed audit assertions for high-risk mobile banking and remote lending workflows.

> The package creates audit-friendly technical artifacts that can support transaction intent verification workflows. It does **not** make identity, fraud, credit, legal, or compliance decisions.

## What this package does

- Creates transaction intent models
- Hashes operation / loan terms using deterministic canonical JSON
- Builds transaction-specific confirmation challenges
- Models authenticator confirmation results
- Attaches optional liveness-aware interaction summaries
- Produces signed audit assertions
- Provides demo signing and verification utilities
- Exports audit-friendly JSON artifacts

## What this package does not do

- KYC / AML
- Identity verification
- Biometric authentication
- Fraud prevention or fraud scoring
- Credit decisioning
- Loan origination
- Payment processing
- Legal e-signature compliance
- Production WebAuthn server implementation

## Why transaction intent confirmation matters

High-risk mobile actions — confirming a loan offer, authorizing a large transfer, changing a recovery phone, or adding a new payee — benefit from a clear technical trail that binds:

1. the exact operation terms,
2. a server-issued challenge / nonce,
3. an authenticator confirmation outcome,
4. optional interaction-derived signals,

into a reviewable artifact for backend audit and dispute workflows.

This package is **developer infrastructure**. It helps you construct and verify those technical artifacts. It does not replace bank risk engines, compliance programs, or legal review.

## Primary reference use case: remote lending

The primary reference use case for README examples is **remote lending / mobile lending infrastructure** for smaller financial organizations:

- community banks
- credit unions
- CDFIs
- small fintech lenders

Typical lending confirmation scenarios:

| Scenario | `TransactionIntentType` |
| --- | --- |
| Confirm loan offer | `confirmLoanOffer` |
| Confirm disbursement | `confirmDisbursement` |
| Provide e-consent | `provideEConsent` |

The same architecture also supports broader high-risk mobile banking actions:

| Scenario | `TransactionIntentType` |
| --- | --- |
| Authorize large transfer | `authorizeLargeTransfer` |
| Change recovery phone | `changeRecoveryPhone` |
| Change security settings | `changeSecuritySettings` |
| Add new payee | `addNewPayee` |
| Institution-defined action | `custom` (+ metadata) |

## Architecture overview

```text
Host App / Bank App
    ↓
TransactionIntent
    ↓
Canonical operation terms hash
    ↓
IntentChallenge + server nonce
    ↓
AuthenticatorConfirmation
    ↓
Optional LivenessInteractionSummary
    ↓
SignedAuditAssertion
    ↓
Bank backend / audit trail / dispute review
```

The backend creates a transaction-specific challenge that binds the operation hash, session nonce, and intent metadata. The authenticator signs the challenge, and the server verifies the resulting assertion. This package models those artifacts in pure Dart; it does not implement production WebAuthn server logic.

## Installation

```yaml
dependencies:
  transaction_intent_signer: ^0.1.0
```

```bash
dart pub get
```

This is a **pure Dart** package. There is no Flutter dependency.

## Quick start

```dart
import 'package:transaction_intent_signer/transaction_intent_signer.dart';

final intent = TransactionIntent(
  intentId: 'intent_123',
  operationId: 'loan_offer_789',
  operationType: TransactionIntentType.confirmLoanOffer,
  customerReference: 'customer_456',
  institutionReference: 'community_bank_demo',
  operationTerms: {
    'loanAmount': 15000,
    'currency': 'USD',
    'apr': 12.5,
    'termMonths': 36,
    'monthlyPayment': 501.23,
  },
  createdAt: DateTime.now().toUtc(),
);

const hasher = OperationTermsHasher();
final termsHash = hasher.sha256Canonical(intent.operationTerms);

final challenge = IntentChallengeBuilder().build(
  intent: intent,
  operationTermsHash: termsHash,
  serverNonce: 'server_nonce_abc',
  expiresIn: const Duration(minutes: 10),
);

final confirmation = AuthenticatorConfirmation.simulated();

final assertion = AuditAssertionBuilder(
  signer: DemoHmacSigner('demo-only-secret'),
).build(
  intent: intent,
  challenge: challenge,
  authenticatorConfirmation: confirmation,
);

final result = AuditAssertionVerifier(
  verifier: DemoHmacVerifier('demo-only-secret'),
).verify(assertion, challenge: challenge);

print(result.isValid);
print(prettyJson(assertion.toJson()));
```

> **Demo signing is provided for reference and testing only.** Production systems must use secure server-side key management and institution-specific compliance controls.

## Loan offer confirmation example

```dart
final intent = TransactionIntent(
  intentId: 'intent_loan_001',
  operationId: 'loan_offer_789',
  operationType: TransactionIntentType.confirmLoanOffer,
  customerReference: 'customer_456',
  institutionReference: 'credit_union_demo',
  operationTerms: const {
    'loanAmount': 15000,
    'currency': 'USD',
    'apr': 12.5,
    'termMonths': 36,
    'monthlyPayment': 501.23,
    'productCode': 'PERSONAL_INSTALLMENT',
  },
  createdAt: DateTime.now().toUtc(),
  metadata: const IntentMetadata(channel: 'mobile_app'),
);
```

Any change to hashed terms (amount, APR, schedule, disclosures hash, etc.) changes `operationTermsHash`.

## Large transfer confirmation example

```dart
final intent = TransactionIntent(
  intentId: 'intent_xfer_001',
  operationId: 'transfer_551',
  operationType: TransactionIntentType.authorizeLargeTransfer,
  customerReference: 'customer_789',
  institutionReference: 'community_bank_demo',
  operationTerms: const {
    'amount': 25000,
    'currency': 'USD',
    'fromAccount': 'checking_1001',
    'toAccount': 'external_9988',
    'recipientName': 'Vendor LLC',
  },
  createdAt: DateTime.now().toUtc(),
);
```

## Optional liveness-aware summary

`LivenessInteractionSummary` is a plain Dart model. The host app can populate it from any source, including derived signals from [`flutter_liveness_actions`](https://pub.dev/packages/flutter_liveness_actions) or another vendor SDK.

This package does **not** depend on Flutter or on `flutter_liveness_actions`.

```dart
const liveness = LivenessInteractionSummary(
  facePresent: true,
  singleFace: true,
  challengeCompleted: true,
  challengeType: 'turn_head_left',
  durationMs: 4200,
  averageProcessingMs: 38,
  // Safe defaults:
  // rawImagesStored: false
  // rawImagesUploaded: false
  // derivedSignalsOnly: true
);

final assertion = AuditAssertionBuilder(
  signer: DemoHmacSigner('demo-only-secret'),
).build(
  intent: intent,
  challenge: challenge,
  authenticatorConfirmation: confirmation,
  livenessInteractionSummary: liveness,
);
```

Default privacy flags are intentionally conservative:

- `rawImagesStored: false`
- `rawImagesUploaded: false`
- `derivedSignalsOnly: true`
- `mediaStoredByThisPackage: false` (always, in the assertion privacy block)

## Signed audit assertion example JSON

```json
{
  "assertionId": "assert_demo_001",
  "intentId": "intent_loan_demo_001",
  "operationId": "loan_offer_789",
  "operationType": "confirm_loan_offer",
  "institutionReference": "community_bank_demo",
  "customerReference": "customer_456",
  "operationTermsHash": {
    "algorithm": "sha256",
    "canonicalization": "canonical_json_v1",
    "value": "sha256:…"
  },
  "challengeId": "chal_demo_001",
  "serverNonceReference": "srv_nonce_demo_9f3a",
  "authenticatorConfirmation": {
    "userPresence": true,
    "userVerification": true,
    "authenticatorType": "simulated_passkey",
    "confirmedAt": "2026-08-07T12:02:00.000Z"
  },
  "livenessInteractionSummary": {
    "facePresent": true,
    "singleFace": true,
    "challengeCompleted": true,
    "rawImagesStored": false,
    "rawImagesUploaded": false,
    "derivedSignalsOnly": true
  },
  "createdAt": "2026-08-07T12:02:30.000Z",
  "status": "created",
  "privacy": {
    "rawImagesStored": false,
    "rawImagesUploaded": false,
    "derivedSignalsOnly": true,
    "mediaStoredByThisPackage": false
  },
  "identityProofing": "not_performed_by_this_package",
  "creditDecision": "not_performed",
  "fraudDecision": "not_performed",
  "eSignatureCompliance": "not_claimed",
  "signatureAlgorithm": "demo_hmac_sha256",
  "signature": "hmac-sha256:…"
}
```

## Security and compliance boundaries

Please read:

- [DISCLAIMER.md](DISCLAIMER.md)
- [SECURITY.md](SECURITY.md)
- [doc/THREAT_MODEL.md](doc/THREAT_MODEL.md)
- [doc/WEB_AUTHN_BOUNDARIES.md](doc/WEB_AUTHN_BOUNDARIES.md)

Conservative summary:

- This package helps bind operation details to a confirmation artifact and build a technical audit trail.
- It does **not** detect all fraud, replace bank risk engines, prove legal consent by itself, or verify identity.
- Demo HMAC signing is for reference/testing only.

## Integration with flutter_liveness_actions

Host Flutter apps can map derived liveness signals into `LivenessInteractionSummary` without coupling this package to Flutter:

```dart
// Pseudocode in the host Flutter app — not part of this package.
final summary = LivenessInteractionSummary(
  facePresent: livenessEvent.facePresent,
  singleFace: livenessEvent.singleFace,
  challengeCompleted: livenessEvent.challengeCompleted,
  challengeType: livenessEvent.challengeType,
  durationMs: livenessEvent.durationMs,
  averageProcessingMs: livenessEvent.averageProcessingMs,
  rawImagesStored: false,
  rawImagesUploaded: false,
  derivedSignalsOnly: true,
  metrics: {
    'source': 'flutter_liveness_actions',
  },
);
```

See [doc/INTEGRATION_GUIDE.md](doc/INTEGRATION_GUIDE.md) for backend and mobile integration notes.

## Documentation

- [Architecture](doc/ARCHITECTURE.md)
- [Assertion schema](doc/ASSERTION_SCHEMA.md)
- [Threat model](doc/THREAT_MODEL.md)
- [Integration guide](doc/INTEGRATION_GUIDE.md)
- [WebAuthn boundaries](doc/WEB_AUTHN_BOUNDARIES.md)
- [Roadmap](doc/ROADMAP.md)

## Roadmap

See [doc/ROADMAP.md](doc/ROADMAP.md) for the full plan. Short version:

- **0.1.0** — Core intent, hashing, challenge, audit assertion
- **0.2.0** — Stronger verification / schema exploration
- **0.3.0** — Integration examples
- **0.4.0** — Mobile reference app support
- **1.0.0** — Stable API and pub.dev release readiness

## License

MIT License. See [LICENSE](LICENSE).
