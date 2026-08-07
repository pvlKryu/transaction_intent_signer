import 'package:meta/meta.dart';

import '../challenge/challenge_expiration_policy.dart';
import '../challenge/intent_challenge.dart';
import '../hashing/canonical_json_encoder.dart';
import '../signing/assertion_verifier.dart';
import 'signed_audit_assertion.dart';

/// Result of verifying a [SignedAuditAssertion].
@immutable
class AuditAssertionVerificationResult {
  /// Creates an [AuditAssertionVerificationResult].
  const AuditAssertionVerificationResult({
    required this.isValid,
    required this.verifiedAt,
    this.failureReason,
  });

  /// Whether verification succeeded.
  final bool isValid;

  /// Optional machine-readable / human-readable failure reason.
  final String? failureReason;

  /// UTC verification timestamp.
  final DateTime verifiedAt;

  /// Successful verification result.
  factory AuditAssertionVerificationResult.valid({DateTime? verifiedAt}) {
    return AuditAssertionVerificationResult(
      isValid: true,
      verifiedAt: (verifiedAt ?? DateTime.now()).toUtc(),
    );
  }

  /// Failed verification result.
  factory AuditAssertionVerificationResult.invalid(
    String failureReason, {
    DateTime? verifiedAt,
  }) {
    return AuditAssertionVerificationResult(
      isValid: false,
      failureReason: failureReason,
      verifiedAt: (verifiedAt ?? DateTime.now()).toUtc(),
    );
  }

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        'isValid': isValid,
        if (failureReason != null) 'failureReason': failureReason,
        'verifiedAt': verifiedAt.toUtc().toIso8601String(),
      };
}

/// Verifies signed audit assertions.
class AuditAssertionVerifier {
  /// Creates an [AuditAssertionVerifier].
  const AuditAssertionVerifier({
    required this.verifier,
    this.encoder = const CanonicalJsonEncoder(),
    this.expirationPolicy = const ChallengeExpirationPolicy(),
  });

  /// Cryptographic verifier for the assertion signature.
  final AssertionVerifier verifier;

  /// Canonical encoder used to recompute the signed payload.
  final CanonicalJsonEncoder encoder;

  /// Policy used when an accompanying challenge is supplied.
  final ChallengeExpirationPolicy expirationPolicy;

  /// Verifies [assertion].
  ///
  /// When [challenge] is provided, also checks challenge identity binding and
  /// expiration.
  AuditAssertionVerificationResult verify(
    SignedAuditAssertion assertion, {
    IntentChallenge? challenge,
    DateTime? now,
  }) {
    final verifiedAt = (now ?? DateTime.now()).toUtc();

    if (assertion.signatureAlgorithm != verifier.algorithm) {
      return AuditAssertionVerificationResult.invalid(
        'Signature algorithm mismatch: assertion uses '
        '${assertion.signatureAlgorithm}, verifier expects '
        '${verifier.algorithm}.',
        verifiedAt: verifiedAt,
      );
    }

    if (challenge != null) {
      if (challenge.challengeId != assertion.challengeId) {
        return AuditAssertionVerificationResult.invalid(
          'Challenge id does not match assertion.',
          verifiedAt: verifiedAt,
        );
      }
      if (challenge.intentId != assertion.intentId) {
        return AuditAssertionVerificationResult.invalid(
          'Challenge intentId does not match assertion.',
          verifiedAt: verifiedAt,
        );
      }
      if (challenge.serverNonce != assertion.serverNonceReference) {
        return AuditAssertionVerificationResult.invalid(
          'Challenge serverNonce does not match assertion.',
          verifiedAt: verifiedAt,
        );
      }
      if (challenge.operationTermsHash.value !=
          assertion.operationTermsHash.value) {
        return AuditAssertionVerificationResult.invalid(
          'Challenge operationTermsHash does not match assertion.',
          verifiedAt: verifiedAt,
        );
      }
      if (challenge.isExpired(now: verifiedAt, policy: expirationPolicy)) {
        return AuditAssertionVerificationResult.invalid(
          'Intent challenge has expired.',
          verifiedAt: verifiedAt,
        );
      }
    }

    final canonical = encoder.encode(assertion.unsignedPayload);
    final signatureOk = verifier.verify(
      canonicalPayload: canonical,
      signature: assertion.signature,
    );
    if (!signatureOk) {
      return AuditAssertionVerificationResult.invalid(
        'Signature verification failed. Payload may have been altered or the '
        'wrong secret/key was used.',
        verifiedAt: verifiedAt,
      );
    }

    // Detect field drift between top-level assertion and unsigned payload.
    final drift = _detectPayloadDrift(assertion);
    if (drift != null) {
      return AuditAssertionVerificationResult.invalid(
        drift,
        verifiedAt: verifiedAt,
      );
    }

    return AuditAssertionVerificationResult.valid(verifiedAt: verifiedAt);
  }

  String? _detectPayloadDrift(SignedAuditAssertion assertion) {
    final payload = assertion.unsignedPayload;
    if (payload['assertionId'] != assertion.assertionId) {
      return 'unsignedPayload.assertionId does not match assertion.';
    }
    if (payload['intentId'] != assertion.intentId) {
      return 'unsignedPayload.intentId does not match assertion.';
    }
    if (payload['operationId'] != assertion.operationId) {
      return 'unsignedPayload.operationId does not match assertion.';
    }
    if (payload['challengeId'] != assertion.challengeId) {
      return 'unsignedPayload.challengeId does not match assertion.';
    }
    if (payload['operationTermsHash'] != assertion.operationTermsHash.value) {
      return 'unsignedPayload.operationTermsHash does not match assertion.';
    }
    if (payload['serverNonceReference'] != assertion.serverNonceReference) {
      return 'unsignedPayload.serverNonceReference does not match assertion.';
    }
    return null;
  }
}
