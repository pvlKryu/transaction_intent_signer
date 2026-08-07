# Public API Review (1.0.0)

This document records the public API surface stabilized in `1.0.0`.

## Stability statement

The symbols exported from `package:transaction_intent_signer/transaction_intent_signer.dart`
are the **supported public API**.

Breaking changes to those symbols require a new major version (`2.0.0+`), except
where noted under [Experimental / demo-only](#experimental--demo-only).

See [SEMVER.md](SEMVER.md).

## API modules

### Intent

| Symbol | Role |
| --- | --- |
| `TransactionIntent` | High-risk operation session model |
| `TransactionIntentType` | Built-in operation categories + `custom` |
| `IntentMetadata` | Channel / custom operation labels / extras |

### Hashing

| Symbol | Role |
| --- | --- |
| `CanonicalJsonEncoder` | Deterministic JSON (`canonical_json_v1`) |
| `OperationTermsHasher` | SHA-256 over canonical terms |
| `OperationTermsHash` | Digest descriptor |

### Challenge

| Symbol | Role |
| --- | --- |
| `IntentChallenge` | Bound challenge artifact |
| `IntentChallengeBuilder` | Challenge construction + expiry checks |
| `ChallengeExpirationPolicy` | Clock-skew-aware expiry policy |

### Authenticator / liveness

| Symbol | Role |
| --- | --- |
| `AuthenticatorConfirmation` | Modeled confirmation outcome |
| `AuthenticatorType` | Confirmation category |
| `LivenessInteractionSummary` | Optional derived-signal summary |
| `LivenessSummaryMapper` | Host SDK → summary mapping helpers |

### Audit / signing

| Symbol | Role |
| --- | --- |
| `SignedAuditAssertion` | Signed technical audit artifact |
| `AssertionMetadata` | Structured assertion metadata |
| `AssertionPrivacy` / `AssertionStatusFields` | Privacy + non-claim fields |
| `AuditAssertionBuilder` | Build + sign assertions |
| `AuditAssertionVerifier` | Verify signature / binding / drift |
| `AuditAssertionVerificationResult` | Structured verification outcome |
| `VerificationFailureCode` / `VerificationCheck` | Machine-readable check model |
| `AssertionSigner` / `AssertionVerifier` | Extension points |
| `DemoHmacSigner` / `DemoHmacVerifier` | Demo-only HMAC implementations |
| `CompactAssertionEnvelope` | JWS-style compact transport encoding |
| `TransactionIntentSignerInfo` | Package / schema constants |

### Demo / mobile reference helpers

| Symbol | Role |
| --- | --- |
| `DemoConfirmationSession` | Host demo session state machine |
| `AssertionShareHelper` | Copy/share payload builder |
| `DemoDashboardSnapshot` (+ entry/summary) | Demo dashboard schema |

### Utilities / errors

| Symbol | Role |
| --- | --- |
| `prettyJson` / `PrettyJsonOptions` / `prettyCanonicalJson` / `encodeJson` | JSON rendering |
| `TransactionIntentException` (+ subclasses) | Typed failures |

## Design decisions retained for 1.0.0

1. **Pure Dart only** — no Flutter dependency.
2. **Conservative claims** — assertions embed explicit non-claim status fields.
3. **Host-owned WebAuthn** — package models outcomes; does not implement RP server.
4. **Optional liveness** — plain Dart summary; host maps any SDK.
5. **Canonical JSON v1** — key-sorted maps; lists preserve order.
6. **Demo HMAC is not production crypto** — institutions must supply real signers.

## Experimental / demo-only

These are part of the 1.0 public API for discoverability, but carry extra caveats:

| Symbol | Caveat |
| --- | --- |
| `DemoHmacSigner` / `DemoHmacVerifier` | Reference/testing only |
| `CompactAssertionEnvelope` | JWS-**style**; not full RFC 7515 |
| Demo dashboard / session helpers | Reference UI infrastructure only |

Wire formats for core assertion JSON (`tis_assertion_v1`) remain stable under SemVer.

## API review checklist (completed for 1.0.0)

- [x] Barrel export reviewed
- [x] Public types documented (`public_member_api_docs`)
- [x] JSON round-trips covered for primary models
- [x] Verification failure codes documented
- [x] Non-claim fields always set by builder
- [x] Unused dependency (`collection`) removed
- [x] Boundaries documented (disclaimer / threat model / WebAuthn)
