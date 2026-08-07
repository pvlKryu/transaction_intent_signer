/// Pure Dart utilities for transaction intent challenges, operation terms
/// hashing, optional liveness-aware summaries, and audit-friendly signed
/// assertions.
///
/// The package creates audit-friendly technical artifacts that can support
/// transaction intent verification workflows. It does not make identity,
/// fraud, credit, legal, or compliance decisions.
library transaction_intent_signer;

export 'src/audit/audit_assertion_builder.dart';
export 'src/audit/audit_assertion_verifier.dart';
export 'src/audit/signed_audit_assertion.dart';
export 'src/authenticator/authenticator_confirmation.dart';
export 'src/authenticator/authenticator_type.dart';
export 'src/challenge/challenge_expiration_policy.dart';
export 'src/challenge/intent_challenge.dart';
export 'src/challenge/intent_challenge_builder.dart';
export 'src/exceptions/transaction_intent_exception.dart';
export 'src/hashing/canonical_json_encoder.dart';
export 'src/hashing/operation_terms_hash.dart';
export 'src/hashing/operation_terms_hasher.dart';
export 'src/intent/intent_metadata.dart';
export 'src/intent/transaction_intent.dart';
export 'src/intent/transaction_intent_type.dart';
export 'src/liveness/liveness_interaction_summary.dart';
export 'src/signing/assertion_signer.dart';
export 'src/signing/assertion_verifier.dart';
export 'src/signing/demo_hmac_signer.dart';
export 'src/signing/demo_hmac_verifier.dart';
export 'src/util/pretty_json.dart';
