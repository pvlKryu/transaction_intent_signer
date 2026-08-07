# Integration Guide

## Overview

Typical integration has four actors:

1. **Host mobile app** — presents the operation, collects confirmation UX
2. **Institution backend** — creates challenges, verifies authenticators, stores
   audit artifacts
3. **Authenticator stack** — platform passkeys / WebAuthn (host-owned)
4. **Optional liveness source** — e.g. `flutter_liveness_actions` derived signals

```text
Mobile app                     Backend
─────────                     ───────
build TransactionIntent  →    validate session / customer refs
hash terms (or backend)  →    store OperationTermsHash
                         ←    IntentChallenge + serverNonce
confirm via passkey      →    verify WebAuthn assertion (host stack)
map liveness summary     →
build/send assertion     →    verify signature + bind challenge
                              persist SignedAuditAssertion JSON
```

## Host mobile app

Suggested responsibilities:

- Construct `TransactionIntent` from the screens the user actually reviewed
- Prefer hashing the same terms the UI displayed
- Receive `IntentChallenge` from the backend
- Perform authenticator UX via the platform / WebAuthn client
- Map the authenticator result into `AuthenticatorConfirmation`
- Optionally map derived liveness signals into `LivenessInteractionSummary`
- Send the resulting models / assertion payload to the backend

Do **not** embed long-lived production HMAC secrets in the mobile app.

## Backend challenge creation

Recommended backend steps:

1. Authenticate the customer session using existing bank controls
2. Load the authoritative operation terms from your system of record
3. Compute `OperationTermsHash` with `OperationTermsHasher`
4. Generate a high-entropy `serverNonce`
5. Build `IntentChallenge` with a short `expiresIn`
6. Persist challenge metadata for later binding checks
7. Return challenge fields needed by the client

Formulation for docs and runbooks:

> The backend creates a transaction-specific challenge that binds the operation
> hash, session nonce, and intent metadata. The authenticator signs the
> challenge, and the server verifies the resulting assertion.

Avoid claiming that this package “injects into WebAuthn `clientDataJSON`”.
How challenge bytes are delivered to an authenticator is host-defined.

## Passkey / WebAuthn result model

Use `AuthenticatorConfirmation` as a **portable model** of the outcome:

- `userPresence` / `userVerification`
- `authenticatorType`
- optional `credentialReference`
- optional opaque `assertionPayload`

Production WebAuthn cryptographic verification remains outside this package.
See [WEB_AUTHN_BOUNDARIES.md](WEB_AUTHN_BOUNDARIES.md).

## Optional liveness summary

In a Flutter host app:

```dart
final summary = LivenessSummaryMapper.fromFlutterLivenessActionsLike(
  faceDetected: event.facePresent,
  faceCount: event.singleFace ? 1 : 2,
  challengePassed: event.challengeCompleted,
  actionType: event.challengeType,
  sessionDurationMs: event.durationMs,
  avgFrameProcessingMs: event.averageProcessingMs?.toDouble(),
);
```

Runnable mapping and backend demos:

```bash
dart run example/liveness_mapping_example.dart
dart run example/backend_validator_example.dart
```

See [INTEGRATION_EXAMPLES.md](INTEGRATION_EXAMPLES.md).

Keep raw media out of this package’s artifacts unless your institution’s
privacy program explicitly requires and governs that data elsewhere.

## Audit backend

On receipt:

1. Re-load the challenge by `challengeId`
2. Confirm challenge is unexpired and unused (replay policy is host-owned)
3. Confirm `operationTermsHash` still matches authoritative terms
4. Verify authenticator assertion with your WebAuthn server
5. Verify `SignedAuditAssertion` signature with server-side keys
6. Store the JSON artifact for audit / dispute review

Use `AuditAssertionVerifier` for the package-level signature/payload checks.
Combine it with your institution’s broader controls.

## Demo signing warning

`DemoHmacSigner` / `DemoHmacVerifier` are for reference and testing only.
Production systems must use secure server-side key management and
institution-specific compliance controls.
