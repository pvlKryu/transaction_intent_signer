# Integration Examples

This package ships runnable Dart examples under `example/` for version `0.3.0`.

These examples are **developer infrastructure demos**. They do not perform KYC,
AML, identity verification, fraud scoring, credit decisioning, payment
processing, or legal e-signature compliance.

## Run

From the package root:

```bash
dart pub get
dart run example/main.dart
dart run example/liveness_mapping_example.dart
dart run example/backend_validator_example.dart
dart run example/flows/remote_lending_flow.dart
dart run example/flows/large_transfer_flow.dart
dart run example/flows/security_settings_flow.dart
```

## What each example shows

| Example | Purpose |
| --- | --- |
| `liveness_mapping_example.dart` | Map a flutter_liveness_actions-shaped event → `LivenessInteractionSummary` |
| `backend_validator_example.dart` | Reference backend validation (challenge store + terms re-hash + assertion verify) |
| `flows/remote_lending_flow.dart` | Loan offer confirmation with optional liveness summary |
| `flows/large_transfer_flow.dart` | Large transfer authorization |
| `flows/security_settings_flow.dart` | Security settings / recovery phone confirmation |
| `main.dart` | Runs the integration suite end-to-end |

## Liveness mapping note

`LivenessSummaryMapper` lives in the pure Dart package API. Host Flutter apps
can pass derived signals from `flutter_liveness_actions` (or any other source)
without adding a Flutter dependency to this package.

Default privacy posture:

- `rawImagesStored: false`
- `rawImagesUploaded: false`
- `derivedSignalsOnly: true`

## Backend validator note

`BackendAssertionValidator` in the example is reference code. Production
systems must:

- manage signing keys server-side
- verify real WebAuthn/passkey assertions in their own stack
- apply institution risk / compliance controls

Demo HMAC secrets are for local runs only.

## Related docs

- [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)
- [AUDIT_TRAILS.md](AUDIT_TRAILS.md)
- [WEB_AUTHN_BOUNDARIES.md](WEB_AUTHN_BOUNDARIES.md)
- [DISCLAIMER.md](../DISCLAIMER.md)
