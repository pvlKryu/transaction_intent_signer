# Changelog

All notable changes to this project will be documented in this file.

## 0.3.0

### Added

- `LivenessSummaryMapper` for flutter_liveness_actions-like derived signals
- Integration examples:
  - `example/liveness_mapping_example.dart`
  - `example/backend_validator_example.dart`
  - `example/flows/remote_lending_flow.dart`
  - `example/flows/large_transfer_flow.dart`
  - `example/flows/security_settings_flow.dart`
- `doc/INTEGRATION_EXAMPLES.md`
- Tests for mapper + lending / transfer / security-settings scenario flows

## 0.2.0

### Added

- Stronger `AuditAssertionVerificationResult` with `failureCode` and `checks`
- `VerificationFailureCode` and `VerificationCheck` models
- Structured `AssertionMetadata` (`producer`, `channel`, `correlationId`, etc.)
- `schemaVersion` (`tis_assertion_v1`) on signed assertions
- `TransactionIntentSignerInfo` package/schema constants
- Experimental `CompactAssertionEnvelope` (JWS-style three-segment encoding)
- `SignedAuditAssertion.fromUnsignedPayload` helper
- Broader payload-drift tamper detection in the verifier
- Documentation: `doc/AUDIT_TRAILS.md` and updated assertion schema notes

### Changed

- `AuditAssertionBuilder` embeds `schemaVersion` + `assertionMetadata` into the
  signed unsigned payload
- Legacy `metadata` map entries are merged into `assertionMetadata.extra`

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
