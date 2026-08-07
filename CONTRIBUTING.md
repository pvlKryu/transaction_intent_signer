# Contributing

Thanks for contributing to `transaction_intent_signer`.

## Development setup

```bash
dart pub get
dart format .
dart analyze --fatal-infos
dart test
```

## Guidelines

- Keep claims conservative — this is developer infrastructure, not a compliance product.
- Do not add Flutter dependencies to the core package.
- Prefer additive, documented API changes.
- Update `CHANGELOG.md` for user-visible changes.
- Add/adjust tests for behavior changes.

## Docs to read first

- [DISCLAIMER.md](DISCLAIMER.md)
- [doc/SEMVER.md](doc/SEMVER.md)
- [doc/API.md](doc/API.md)
- [doc/TECHNICAL_REVIEW.md](doc/TECHNICAL_REVIEW.md)

## Pull requests

1. Keep PRs focused.
2. Ensure CI is green.
3. Describe the motivation and any SemVer impact.
