/// Base exception for transaction intent signer failures.
class TransactionIntentException implements Exception {
  /// Creates a [TransactionIntentException].
  const TransactionIntentException(this.message, {this.code});

  /// Human-readable description of the failure.
  final String message;

  /// Optional machine-readable failure code.
  final String? code;

  @override
  String toString() {
    if (code == null) {
      return 'TransactionIntentException: $message';
    }
    return 'TransactionIntentException($code): $message';
  }
}

/// Thrown when canonicalization encounters an unsupported value type.
class CanonicalizationException extends TransactionIntentException {
  /// Creates a [CanonicalizationException].
  const CanonicalizationException(super.message)
      : super(code: 'canonicalization_error');
}

/// Thrown when an intent challenge is expired or otherwise invalid.
class ChallengeException extends TransactionIntentException {
  /// Creates a [ChallengeException].
  const ChallengeException(super.message, {super.code = 'challenge_error'});
}

/// Thrown when audit assertion construction or verification fails.
class AuditAssertionException extends TransactionIntentException {
  /// Creates an [AuditAssertionException].
  const AuditAssertionException(super.message,
      {super.code = 'audit_assertion_error'});
}

/// Thrown when signature creation or verification fails.
class SignatureException extends TransactionIntentException {
  /// Creates a [SignatureException].
  const SignatureException(super.message, {super.code = 'signature_error'});
}
