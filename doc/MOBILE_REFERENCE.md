# Mobile Reference Support

Version `0.4.0` adds pure-Dart helpers that a Flutter demo app can import
without forcing a Flutter dependency into this package.

## Shared session model

`DemoConfirmationSession` tracks a confirmation flow through phases:

`draft → challenged → confirmed → asserted → verified` (or `failed`)

Host apps can store this object in Riverpod/Bloc/Provider/etc. and render UI
from `toJson()` or typed fields.

## Copy / share helpers

`AssertionShareHelper` builds clipboard-friendly payloads:

| Format | Use |
| --- | --- |
| `json` | Minified assertion JSON |
| `prettyJson` | Human-readable JSON |
| `compact` | Experimental compact envelope |
| `summaryText` | Short plain-text summary with non-claim wording |

Flutter host example (host-side only):

```dart
final payload = const AssertionShareHelper().export(
  assertion,
  format: AssertionShareFormat.prettyJson,
);
await Clipboard.setData(ClipboardData(text: payload.body));
// or Share.share(payload.body);
```

## Pretty JSON

```dart
prettyJson(value); // default 2-space indent
prettyJson(value, options: PrettyJsonOptions.sharePanel); // sorted keys
prettyJson(value, options: PrettyJsonOptions.compactOverlay);
prettyCanonicalJson(value); // canonical key order, then indented
```

## Demo dashboard schema

See [DEMO_DASHBOARD_SCHEMA.md](DEMO_DASHBOARD_SCHEMA.md).

## Runnable example

```bash
dart run example/mobile_reference_example.dart
```

## Boundaries

These helpers support **demo / reference mobile UX**. They do not:

- implement Flutter widgets
- access clipboard/share platform channels
- perform KYC / AML / fraud / credit / legal decisions
- replace production WebAuthn server logic
