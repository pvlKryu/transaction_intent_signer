# Assertion Schema

This document describes the JSON shape of `SignedAuditAssertion` as exported by
`toJson()` in version `1.0.0`.

Semantic schema label: `tis_assertion_v1`.

## Top-level fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `schemaVersion` | string | yes | `tis_assertion_v1` |
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
| `assertionMetadata` | object | yes | Structured metadata (see below) |
| `signatureAlgorithm` | string | yes | e.g. `demo_hmac_sha256` |
| `signature` | string | yes | Opaque signature string |
| `unsignedPayload` | object | yes | Canonical payload that was signed |
| `metadata` | object | no | Legacy opaque map; also merged into `assertionMetadata.extra` |

## `assertionMetadata`

```json
{
  "schemaVersion": "tis_assertion_v1",
  "packageName": "transaction_intent_signer",
  "packageVersion": "1.0.0",
  "producer": "backend",
  "channel": "mobile_app",
  "correlationId": "corr_123",
  "appVersion": "1.2.3",
  "locale": "en-US",
  "extra": {}
}
```

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

`AuditAssertionBuilder` signs the canonical JSON encoding of `unsignedPayload`
(including `schemaVersion` and `assertionMetadata`).

`AuditAssertionVerifier` re-encodes `unsignedPayload`, verifies the signature,
checks top-level field drift against the signed payload, and optionally checks
an accompanying `IntentChallenge` for id/nonce/hash binding and expiration.

Verification results include `failureCode` and a `checks` list. See
[AUDIT_TRAILS.md](AUDIT_TRAILS.md).

## Compact envelope (exploratory)

`CompactAssertionEnvelope` encodes:

```text
base64url(header).base64url(unsignedPayload).base64url(signature)
```

This is JWS-**style** and is **not** a complete RFC 7515 implementation.

## Compatibility note

- `0.1.x` consumers that only read core fields remain compatible.
- `0.2.0` adds `schemaVersion`, `assertionMetadata`, stronger verification
  results, and optional compact encoding.
- Future versions may refine envelope formats while preserving semantic fields.
