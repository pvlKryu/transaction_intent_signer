# Semantic Versioning Policy

`transaction_intent_signer` follows [SemVer 2.0.0](https://semver.org/).

Starting with **1.0.0**, the package treats the documented public API as stable.

## What is covered

- Symbols exported from
  `package:transaction_intent_signer/transaction_intent_signer.dart`
- Documented JSON field names for `tis_assertion_v1` assertion artifacts
- Documented demo dashboard schema `tis_demo_dashboard_v1`

## Version bumps

| Change | Version impact |
| --- | --- |
| Bug fix / docs / CI / non-API internal cleanup | `PATCH` (`1.0.x`) |
| Additive API, optional fields, new helpers, new examples | `MINOR` (`1.x.0`) |
| Removing/renaming public symbols, changing required fields, changing canonicalization in a incompatible way | `MAJOR` (`2.0.0`) |

## Compatibility notes

- Adding optional JSON fields is a **minor** change when old readers can ignore them.
- Changing `canonical_json_v1` encoding rules is a **major** change because hashes change.
- Changing default non-claim status string values is a **major** change.
- Renaming wire names for enums (`TransactionIntentType`, etc.) is a **major** change.

## Demo and exploratory utilities

`DemoHmacSigner`, `DemoHmacVerifier`, and `CompactAssertionEnvelope` remain in the
public API for discoverability. Their **security/compliance meaning** is explicitly
limited:

- Demo HMAC is for reference/testing only.
- Compact envelope is JWS-style, not a full RFC 7515 implementation.

Behavioral bug fixes in those helpers may ship as patch/minor releases. Removing
them would be a major release.

## Pre-1.0 history

Versions `0.1.0`–`0.4.0` were development releases and may contain breaking
changes between minors. From `1.0.0` onward, SemVer stability applies.
