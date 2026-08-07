# Architecture

## Purpose

`transaction_intent_signer` is a pure Dart developer-infrastructure package for
building **audit-friendly transaction intent confirmation flows**.

It helps host applications and backends:

1. model a high-risk operation as a `TransactionIntent`
2. hash operation terms with deterministic canonical JSON
3. bind those terms to a server nonce via `IntentChallenge`
4. capture an `AuthenticatorConfirmation` outcome
5. optionally attach a `LivenessInteractionSummary`
6. produce a `SignedAuditAssertion` technical artifact

## Package boundaries

In scope:

- deterministic hashing / canonicalization
- challenge construction and expiration checks
- modeling confirmation and optional liveness summaries
- building and verifying signed audit assertion payloads (including demo HMAC)

Out of scope:

- KYC / AML / identity proofing
- biometric capture or matching
- fraud scoring / prevention engines
- credit decisioning / loan origination
- payment rails
- legal e-signature compliance certification
- production WebAuthn server implementation
- Flutter UI or direct dependency on `flutter_liveness_actions`

## Layering

```text
intent/        TransactionIntent session models
hashing/       Canonical JSON + operation terms digest
challenge/     Server-nonce-bound confirmation challenge
authenticator/ Modeled passkey / WebAuthn confirmation result
liveness/      Optional host-supplied interaction summary
signing/       Signer/verifier interfaces + demo HMAC
audit/         Signed assertion builder + verifier
exceptions/    Typed package errors
```

## Fit in mobile lending / mobile banking

### Remote lending (reference)

```text
Loan offer UI
  → TransactionIntent(confirmLoanOffer)
  → OperationTermsHash(loanAmount, apr, term, ...)
  → Backend issues IntentChallenge + serverNonce
  → Passkey / authenticator confirmation in app
  → Optional liveness-derived summary from host SDK
  → SignedAuditAssertion stored for audit / dispute review
```

### Broader high-risk banking actions

The same pipeline applies to:

- large transfers
- recovery phone changes
- security settings changes
- adding a new payee
- custom institution-defined operations

## Design principles

- **Conservative claims** — artifacts support verification workflows; they do
  not assert legal consent, identity, or fraud outcomes.
- **Determinism** — identical terms with different map key order produce the
  same hash.
- **Host-owned integrations** — WebAuthn and liveness are mapped in by the
  host; this package stays pure Dart.
- **Explicit non-claims** — every assertion embeds status fields such as
  `identityProofing: not_performed_by_this_package`.
