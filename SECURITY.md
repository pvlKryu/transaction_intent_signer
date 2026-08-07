# Security Policy

## Supported versions

| Version | Supported |
| --- | --- |
| 0.1.x | Best-effort while in early development |

## Reporting a vulnerability

Please report suspected security issues privately to the repository maintainers
via GitHub Security Advisories (preferred) or by opening a private contact
channel listed on the repository homepage:

https://github.com/pvlKryu/transaction_intent_signer

Include:

- a clear description of the issue
- steps to reproduce
- affected versions / commit hashes
- impact assessment if known

Please allow reasonable time for assessment before public disclosure.

## Scope and non-guarantees

This package is developer infrastructure for constructing audit-friendly
technical artifacts. It does **not** guarantee:

- fraud prevention
- identity verification
- legal consent proof
- regulatory compliance
- production cryptographic key management

Demo HMAC signing utilities are for reference and testing only. Production
deployments must use secure server-side key management and institution-specific
controls.

Responsible disclosure is appreciated. There is no bounty program at this time.
