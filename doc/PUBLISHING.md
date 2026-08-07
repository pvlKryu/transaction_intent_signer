# Release / pub.dev Readiness

Checklist used for the `1.0.0` release candidate. This package is prepared for
publication; maintainers should still run the final publish command intentionally.

## Required local checks

```bash
dart pub get
dart format --set-exit-if-changed .
dart analyze --fatal-infos
dart test
dart pub publish --dry-run
```

Optional quality score:

```bash
dart pub global activate pana
pana .
```

## Package metadata

- [x] `name`, `description`, `version`, `homepage`, `repository`, `issue_tracker`
- [x] `topics`
- [x] `platforms` declared (pure Dart)
- [x] MIT `LICENSE`
- [x] `CHANGELOG.md` entry for `1.0.0`
- [x] README suitable for pub.dev
- [x] `DISCLAIMER.md` / `SECURITY.md` present
- [x] Example entrypoints runnable

## Documentation set

- [x] Architecture / assertion schema / threat model
- [x] Integration guide + examples
- [x] Mobile reference + dashboard schema
- [x] API review + SemVer policy
- [x] Technical review notes

## Do not overclaim on pub.dev

Keep package description and README free of:

- fraud prevention claims
- identity verification claims
- legal consent / E-SIGN certification claims
- “replaces bank compliance” language

Preferred framing: developer infrastructure for audit-friendly technical
artifacts supporting intent confirmation workflows.

## Publish command (manual)

```bash
# Only when intentionally releasing:
dart pub publish
```

Do **not** publish from automated agents unless explicitly requested.
