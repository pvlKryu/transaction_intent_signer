import 'package:meta/meta.dart';

/// Machine-readable reason a verification check failed.
enum VerificationFailureCode {
  /// Verification succeeded.
  none,

  /// Assertion signature algorithm does not match verifier.
  algorithmMismatch,

  /// Challenge id does not match assertion.
  challengeIdMismatch,

  /// Challenge intent id does not match assertion.
  challengeIntentMismatch,

  /// Challenge operation id does not match assertion.
  challengeOperationMismatch,

  /// Challenge server nonce does not match assertion.
  challengeNonceMismatch,

  /// Challenge operation terms hash does not match assertion.
  challengeHashMismatch,

  /// Challenge has expired.
  challengeExpired,

  /// Cryptographic signature verification failed.
  signatureInvalid,

  /// Top-level assertion fields drifted from signed unsignedPayload.
  payloadDrift,

  /// Compact envelope could not be parsed.
  compactEnvelopeInvalid,
}

/// Serialization helpers for [VerificationFailureCode].
extension VerificationFailureCodeX on VerificationFailureCode {
  /// Wire / JSON value.
  String get wireName {
    switch (this) {
      case VerificationFailureCode.none:
        return 'none';
      case VerificationFailureCode.algorithmMismatch:
        return 'algorithm_mismatch';
      case VerificationFailureCode.challengeIdMismatch:
        return 'challenge_id_mismatch';
      case VerificationFailureCode.challengeIntentMismatch:
        return 'challenge_intent_mismatch';
      case VerificationFailureCode.challengeOperationMismatch:
        return 'challenge_operation_mismatch';
      case VerificationFailureCode.challengeNonceMismatch:
        return 'challenge_nonce_mismatch';
      case VerificationFailureCode.challengeHashMismatch:
        return 'challenge_hash_mismatch';
      case VerificationFailureCode.challengeExpired:
        return 'challenge_expired';
      case VerificationFailureCode.signatureInvalid:
        return 'signature_invalid';
      case VerificationFailureCode.payloadDrift:
        return 'payload_drift';
      case VerificationFailureCode.compactEnvelopeInvalid:
        return 'compact_envelope_invalid';
    }
  }

  /// Parses a wire name.
  static VerificationFailureCode fromWireName(String value) {
    switch (value) {
      case 'algorithm_mismatch':
        return VerificationFailureCode.algorithmMismatch;
      case 'challenge_id_mismatch':
        return VerificationFailureCode.challengeIdMismatch;
      case 'challenge_intent_mismatch':
        return VerificationFailureCode.challengeIntentMismatch;
      case 'challenge_operation_mismatch':
        return VerificationFailureCode.challengeOperationMismatch;
      case 'challenge_nonce_mismatch':
        return VerificationFailureCode.challengeNonceMismatch;
      case 'challenge_hash_mismatch':
        return VerificationFailureCode.challengeHashMismatch;
      case 'challenge_expired':
        return VerificationFailureCode.challengeExpired;
      case 'signature_invalid':
        return VerificationFailureCode.signatureInvalid;
      case 'payload_drift':
        return VerificationFailureCode.payloadDrift;
      case 'compact_envelope_invalid':
        return VerificationFailureCode.compactEnvelopeInvalid;
      case 'none':
      default:
        return VerificationFailureCode.none;
    }
  }
}

/// One discrete verification check performed by [AuditAssertionVerifier].
@immutable
class VerificationCheck {
  /// Creates a [VerificationCheck].
  const VerificationCheck({
    required this.name,
    required this.passed,
    this.detail,
  });

  /// Stable check name (e.g. `signature`, `challenge_expiration`).
  final String name;

  /// Whether the check passed.
  final bool passed;

  /// Optional human-readable detail.
  final String? detail;

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        'name': name,
        'passed': passed,
        if (detail != null) 'detail': detail,
      };

  /// Deserializes from JSON.
  factory VerificationCheck.fromJson(Map<String, Object?> json) {
    return VerificationCheck(
      name: json['name']! as String,
      passed: json['passed']! as bool,
      detail: json['detail'] as String?,
    );
  }
}

/// Result of verifying a [SignedAuditAssertion].
@immutable
class AuditAssertionVerificationResult {
  /// Creates an [AuditAssertionVerificationResult].
  const AuditAssertionVerificationResult({
    required this.isValid,
    required this.verifiedAt,
    this.failureCode = VerificationFailureCode.none,
    this.failureReason,
    this.checks = const [],
  });

  /// Whether verification succeeded.
  final bool isValid;

  /// Machine-readable failure code (`none` when valid).
  final VerificationFailureCode failureCode;

  /// Optional human-readable failure reason.
  final String? failureReason;

  /// UTC verification timestamp.
  final DateTime verifiedAt;

  /// Checks evaluated during verification (including the failing check).
  final List<VerificationCheck> checks;

  /// Successful verification result.
  factory AuditAssertionVerificationResult.valid({
    DateTime? verifiedAt,
    List<VerificationCheck> checks = const [],
  }) {
    return AuditAssertionVerificationResult(
      isValid: true,
      failureCode: VerificationFailureCode.none,
      verifiedAt: (verifiedAt ?? DateTime.now()).toUtc(),
      checks: checks,
    );
  }

  /// Failed verification result.
  factory AuditAssertionVerificationResult.invalid(
    String failureReason, {
    required VerificationFailureCode failureCode,
    DateTime? verifiedAt,
    List<VerificationCheck> checks = const [],
  }) {
    return AuditAssertionVerificationResult(
      isValid: false,
      failureCode: failureCode,
      failureReason: failureReason,
      verifiedAt: (verifiedAt ?? DateTime.now()).toUtc(),
      checks: checks,
    );
  }

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        'isValid': isValid,
        'failureCode': failureCode.wireName,
        if (failureReason != null) 'failureReason': failureReason,
        'verifiedAt': verifiedAt.toUtc().toIso8601String(),
        'checks': checks.map((c) => c.toJson()).toList(),
      };

  /// Deserializes from JSON.
  factory AuditAssertionVerificationResult.fromJson(Map<String, Object?> json) {
    final checksRaw = json['checks'];
    return AuditAssertionVerificationResult(
      isValid: json['isValid']! as bool,
      failureCode: VerificationFailureCodeX.fromWireName(
        json['failureCode'] as String? ?? 'none',
      ),
      failureReason: json['failureReason'] as String?,
      verifiedAt: DateTime.parse(json['verifiedAt']! as String).toUtc(),
      checks: checksRaw is List
          ? checksRaw
              .whereType<Map>()
              .map(
                (e) => VerificationCheck.fromJson(Map<String, Object?>.from(e)),
              )
              .toList()
          : const [],
    );
  }
}
