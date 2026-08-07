# WebAuthn Boundaries

## What this package models

`AuthenticatorConfirmation` is a portable Dart model for recording that an
authenticator confirmation occurred in a host flow. It can represent outcomes
from:

- platform passkeys
- WebAuthn ceremonies
- simulated / demo confirmations
- custom institution authenticators

Fields such as `userPresence`, `userVerification`, `credentialReference`, and
`assertionPayload` exist so host apps can attach relevant metadata to the
audit artifact.

## What this package does not implement

This package does **not** implement production WebAuthn server logic, including:

- relying party configuration
- attestation statement validation
- assertion signature verification over authenticator data
- origin / RP ID binding checks
- credential lifecycle / store management
- anomaly detection for authenticator usage

Those responsibilities belong to the institution’s WebAuthn / passkey stack.

## Recommended wording

Prefer:

> The backend creates a transaction-specific challenge that binds the operation
> hash, session nonce, and intent metadata. The authenticator signs the
> challenge, and the server verifies the resulting assertion.

Avoid:

> This package injects values into WebAuthn `clientDataJSON`.

Challenge transport into an authenticator ceremony is host-defined and may vary
by platform SDK.

## Simulated confirmations

`AuthenticatorConfirmation.simulated()` exists for examples and automated
tests. It is not a substitute for a real passkey / WebAuthn confirmation in
production workflows.
