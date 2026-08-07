# Demo Dashboard Schema

Schema label: `tis_demo_dashboard_v1`

This schema describes a **demo / reference UI snapshot** that a Flutter (or
any) host app can render. It is not a regulated reporting format and does not
claim identity, fraud, credit, or legal compliance outcomes.

## Snapshot

```json
{
  "schemaVersion": "tis_demo_dashboard_v1",
  "packageName": "transaction_intent_signer",
  "packageVersion": "1.0.0",
  "generatedAt": "2026-08-07T20:00:00.000Z",
  "summary": {
    "total": 1,
    "verified": 1,
    "failed": 0,
    "withLiveness": 1
  },
  "entries": [
    {
      "assertionId": "assert_demo",
      "intentId": "intent_demo",
      "operationId": "op_demo",
      "operationType": "confirm_loan_offer",
      "institutionReference": "bank_demo",
      "customerReference": "customer_1",
      "status": "created",
      "createdAt": "2026-08-07T20:00:00.000Z",
      "termsHashShort": "sha256:abcdef…",
      "hasLiveness": true,
      "verificationValid": true,
      "failureCode": "none",
      "correlationId": "corr_demo",
      "flowLabel": "remote_lending",
      "channel": "mobile_app"
    }
  ]
}
```

## Models

| Model | Purpose |
| --- | --- |
| `DemoDashboardSnapshot` | Full dashboard JSON document |
| `DemoDashboardEntry` | One list/card row |
| `DemoDashboardSummary` | Aggregate counters |
| `DemoDashboardSchema` | Constants (`version`, package name) |

Build with:

```dart
final snapshot = DemoDashboardSnapshot.fromAssertions(
  assertions,
  verificationByAssertionId: {
    assertion.assertionId: verificationResult,
  },
);
```

## Suggested Flutter usage

1. Keep `DemoConfirmationSession` in app state while the user confirms.
2. On completion, append `SignedAuditAssertion` to an in-memory list.
3. Build `DemoDashboardSnapshot` for a results screen.
4. Use `AssertionShareHelper` for copy/share actions.

No Flutter dependency is required in this package.
