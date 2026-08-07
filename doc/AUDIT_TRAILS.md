# Audit Trails

## Purpose

This document explains how `transaction_intent_signer` artifacts can support an
**institution-owned technical audit trail** for high-risk mobile banking and
remote lending confirmation flows.

The package creates audit-friendly technical artifacts. It does **not** make
identity, fraud, credit, legal, or compliance decisions.

## What an audit trail entry typically contains

A durable backend record may store:

1. `TransactionIntent` snapshot (or a reference to authoritative terms)
2. `OperationTermsHash` of the terms the customer confirmed
3. `IntentChallenge` (id, nonce, issuance/expiry)
4. Host WebAuthn / passkey verification outcome (outside this package)
5. Optional `LivenessInteractionSummary` (derived signals only by default)
6. `SignedAuditAssertion` JSON and/or compact envelope
7. Host verification result (`AuditAssertionVerificationResult`)

## Suggested retention workflow

```text
confirmation event
  → verify authenticator assertion (institution WebAuthn stack)
  → verify SignedAuditAssertion signature + challenge binding
  → persist assertion JSON + verification result + challenge metadata
  → index by assertionId / intentId / operationId / correlationId
  → retain under institution policy for dispute / QA review
```

Recommended index keys from `AssertionMetadata`:

- `correlationId`
- `producer`
- `channel`
- `packageVersion`
- `schemaVersion`

## Verification result model (0.2.0+)

`AuditAssertionVerificationResult` now includes:

- `isValid`
- `failureCode` (machine-readable)
- `failureReason` (human-readable)
- `verifiedAt`
- `checks` (ordered list of discrete checks)

Example failure codes:

| Code | Meaning |
| --- | --- |
| `signature_invalid` | Payload/signature mismatch or wrong key |
| `payload_drift` | Top-level fields do not match signed payload |
| `challenge_expired` | Bound challenge is past expiry |
| `challenge_nonce_mismatch` | Challenge nonce does not match assertion |
| `algorithm_mismatch` | Assertion alg does not match verifier |

Persist the full result JSON alongside the assertion for later dispute review.

## Compact envelope (exploratory)

`CompactAssertionEnvelope` provides a JWS-**style** three-segment encoding:

```text
base64url(header).base64url(unsignedPayload).base64url(signature)
```

This is **not** a full RFC 7515 / JWT implementation. It is an exploration aid
for transport and storage. Prefer storing the full JSON assertion for audit
clarity; use compact form only when a transport-friendly encoding is needed.

## Language for audit / legal stakeholders

Prefer:

- technical audit trail
- audit-friendly confirmation artifact
- cryptographically signed demo/reference artifact (when using demo HMAC)
- intent confirmation flow evidence for internal review

Avoid:

- proves legal consent
- prevents fraud
- court-proof evidence
- KYC / identity verification substitute

## Related docs

- [ASSERTION_SCHEMA.md](ASSERTION_SCHEMA.md)
- [THREAT_MODEL.md](THREAT_MODEL.md)
- [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)
- [DISCLAIMER.md](../DISCLAIMER.md)
