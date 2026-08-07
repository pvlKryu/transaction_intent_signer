# Example: transaction_intent_signer

Runnable integration demos for high-risk mobile banking and remote lending
confirmation flows.

## Quick start

```bash
# from package root
dart pub get
dart run example/main.dart
```

## Scripts

| Command | Description |
| --- | --- |
| `dart run example/main.dart` | Full integration suite |
| `dart run example/mobile_reference_example.dart` | Session / share / dashboard helpers |
| `dart run example/liveness_mapping_example.dart` | flutter_liveness_actions-shaped mapping |
| `dart run example/backend_validator_example.dart` | Reference backend validator |
| `dart run example/flows/remote_lending_flow.dart` | Loan offer confirmation |
| `dart run example/flows/large_transfer_flow.dart` | Large transfer confirmation |
| `dart run example/flows/security_settings_flow.dart` | Security settings confirmation |

See [doc/INTEGRATION_EXAMPLES.md](../doc/INTEGRATION_EXAMPLES.md) and
[doc/MOBILE_REFERENCE.md](../doc/MOBILE_REFERENCE.md).

Demo HMAC signing is for reference and testing only.
