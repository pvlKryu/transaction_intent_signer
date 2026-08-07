# Threat Model

## Goal

Describe, conservatively, what `transaction_intent_signer` can and cannot help
with when used as developer infrastructure for intent confirmation flows.

## Assets

- Operation terms integrity (amount, APR, recipient, phone number, etc.)
- Binding between terms hash, server nonce, and challenge metadata
- Integrity of the exported signed audit assertion payload (given a trusted key)

## What this package can help with

- Bind operation details to a confirmation artifact via deterministic hashing
- Create a **technical audit trail** that is reviewable by backend systems
- Detect simple tampering of the signed unsigned-payload when verification keys
  are correct and controlled by the institution
- Make package non-claims explicit in exported JSON (`identityProofing`,
  `fraudDecision`, etc.)

## What this package cannot protect against

- It does **not** detect all fraud
- It does **not** replace bank risk engines or case-management systems
- It does **not** prove legal consent by itself
- It does **not** verify identity
- It does **not** prevent compromised devices, social engineering, or insider
  misuse by itself
- It does **not** replace production WebAuthn attestation/assertion validation
- Demo HMAC secrets stored in apps or examples are **not** production-safe

## Trust assumptions

1. The backend generates and stores high-entropy server nonces.
2. Authenticator confirmation is validated by the institution’s real
   WebAuthn / passkey stack (outside this package).
3. Signing keys are managed server-side in production.
4. Host apps map only intended derived signals into
   `LivenessInteractionSummary`.
5. Audit retention and dispute processes are owned by the institution.

## Abuse cases (illustrative, not exhaustive)

| Abuse case | Package role |
| --- | --- |
| Terms changed after customer review | Hash mismatch can surface inconsistency if compared |
| Replay of an old challenge | Expiration + nonce checks can help; full anti-replay is host-owned |
| Altered audit JSON in transit | Signature verification can fail if keys are correct |
| Stolen device + real passkey use | Out of scope — risk engines / step-up policies needed |
| Fake KYC claims via this package | Explicitly non-claimed in assertion status fields |

## Language guidance for implementers

Prefer:

- “audit-friendly technical artifact”
- “intent confirmation flow”
- “technical audit trail”
- “reference / demo signing”

Avoid:

- “prevents fraud”
- “proves identity”
- “guarantees consent”
- “court-proof evidence”
