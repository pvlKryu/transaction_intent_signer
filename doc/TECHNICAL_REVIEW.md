# Technical Review Notes (1.0.0)

This document captures the internal technical review incorporated into `1.0.0`.
External reviewers can open GitHub issues/PRs against these findings.

## Review scope

- Public API consistency and documentation
- Security / compliance wording
- Hashing / challenge / assertion integrity behavior
- Test coverage for happy paths and tamper cases
- pub.dev packaging readiness

## Findings incorporated

1. **Conservative positioning retained**  
   README, disclaimer, threat model, and assertion status fields continue to
   state that the package does not perform KYC/AML/identity/fraud/credit/legal
   decisions.

2. **WebAuthn boundaries explicit**  
   Authenticator models are outcome containers only; production RP verification
   remains host-owned.

3. **Non-claim fields are builder defaults**  
   `identityProofing`, `creditDecision`, `fraudDecision`, and
   `eSignatureCompliance` are always set by `AuditAssertionBuilder`.

4. **Tamper detection expanded**  
   Verifier checks signature, challenge binding/expiry, and top-level payload
   drift against signed `unsignedPayload`.

5. **Demo crypto clearly labeled**  
   Demo HMAC utilities warn they are reference/testing only.

6. **Unused dependency removed**  
   `collection` was declared but unused; removed for leaner pub metadata.

7. **CI added**  
   Format, analyze (`--fatal-infos`), and tests run on GitHub Actions.

8. **SemVer policy published**  
   Stability guarantees start at 1.0.0.

## Known limitations (accepted for 1.0.0)

- No production key management / KMS integration
- Compact envelope is not full JWS/JWT
- No official Flutter widget kit (pure Dart helpers only)
- Replay protection beyond challenge expiry is host-owned
- External formal security audit not yet performed

## Requested external feedback

Useful review topics for outside contributors:

- Canonical JSON edge cases for institution term schemas
- Assertion retention / dispute workflow fit
- Alternative production `AssertionSigner` designs (JWS, asymmetric keys)
- Mapping completeness for additional liveness SDK event shapes

Please file feedback via GitHub Issues:
https://github.com/pvlKryu/transaction_intent_signer/issues
