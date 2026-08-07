# Changelog

All notable changes to this project will be documented in this file.

## 0.1.0

### Added

- `TransactionIntent`, `TransactionIntentType`, and `IntentMetadata`
- Deterministic `CanonicalJsonEncoder` (`canonical_json_v1`)
- `OperationTermsHasher` / `OperationTermsHash` (SHA-256 over canonical JSON)
- `IntentChallenge` and `IntentChallengeBuilder` with expiration checks
- `AuthenticatorConfirmation` and `AuthenticatorType`, including `.simulated()`
- Optional `LivenessInteractionSummary` with conservative privacy defaults
- `SignedAuditAssertion`, `AuditAssertionBuilder`, and `AuditAssertionVerifier`
- Demo-only `DemoHmacSigner` / `DemoHmacVerifier`
- Example loan-offer confirmation flow
- Documentation: architecture, assertion schema, threat model, integration guide,
  WebAuthn boundaries, security policy, and disclaimer
