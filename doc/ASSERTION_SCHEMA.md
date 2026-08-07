# Assertion Schema

This document describes the JSON shape of `SignedAuditAssertion` as exported by
`toJson()` in version `0.1.0`.

## Top-level fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `assertionId` | string | yes | Unique artifact id |
| `intentId` | string | yes | Linked intent session |
| `operationId` | string | yes | Host operation id |
| `operationType` | string | yes | Wire name or custom label |
| `institutionReference` | string | yes | Opaque institution id |
| `customerReference` | string | yes | Opaque customer id (not identity proof) |
| `operationTermsHash` | object | yes | See below |
| `challengeId` | string | yes | Bound challenge id |
| `serverNonceReference` | string | yes | Server nonce from challenge |
| `authenticatorConfirmation` | object | yes | Modeled confirmation result |
| `livenessInteractionSummary` | object | no | Host-supplied derived signals |
| `createdAt` | string (ISO-8601 UTC) | yes | Artifact creation time |
| `status` | string | yes | `created` / `verified` / `verification_failed` |
| `privacy` | object | yes | Privacy flags |
| `identityProofing` | string | yes | Always `not_performed_by_this_package` when built by this package |
| `creditDecision` | string | yes | Always `not_performed` when built by this package |
| `fraudDecision` | string | yes | Always `not_performed` when built by this package |
| `eSignatureCompliance` | string | yes | Always `not_claimed` when built by this package |
| `signatureAlgorithm` | string | yes | e.g. `demo_hmac_sha256` |
| `signature` | string | yes | Opaque signature string |
| `unsignedPayload` | object | yes | Canonical payload that was signed |
| `metadata` | object | no | Host extensions |

## `operationTermsHash`

```json
{
  "algorithm": "sha256",
  "canonicalization": "canonical_json_v1",
  "value": "sha256:<hex>"
}
```

Optional debug field `canonicalPayload` may appear when hashing was performed
with `includeCanonicalPayload: true`, but builders typically persist only the
digest value inside `unsignedPayload`.

## `privacy`

```json
{
  "rawImagesStored": false,
  "rawImagesUploaded": false,
  "derivedSignalsOnly": true,
  "mediaStoredByThisPackage": false
}
```

`mediaStoredByThisPackage` is always `false` for artifacts produced by this
package.

## Required status field values (builder defaults)

```json
{
  "identityProofing": "not_performed_by_this_package",
  "creditDecision": "not_performed",
  "fraudDecision": "not_performed",
  "eSignatureCompliance": "not_claimed"
}
```

These fields exist to make package non-claims explicit in exported JSON.

## Signature coverage

`AuditAssertionBuilder` signs the canonical JSON encoding of `unsignedPayload`.
`AuditAssertionVerifier` re-encodes `unsignedPayload`, verifies the signature,
and optionally checks an accompanying `IntentChallenge` for id/nonce/hash
binding and expiration.

## Compatibility note

The `0.1.0` schema is intentionally simple. Future versions may explore
JWS-style envelopes while preserving the semantic fields above.
