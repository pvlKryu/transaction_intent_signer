import '../challenge/challenge_expiration_policy.dart';
import '../challenge/intent_challenge.dart';
import '../hashing/canonical_json_encoder.dart';
import '../signing/assertion_verifier.dart';
import 'audit_assertion_verification_result.dart';
import 'signed_audit_assertion.dart';

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
    final checks = <VerificationCheck>[];

    if (assertion.signatureAlgorithm != verifier.algorithm) {
      checks.add(
        VerificationCheck(
          name: 'signature_algorithm',
          passed: false,
          detail:
              'assertion=${assertion.signatureAlgorithm}, verifier=${verifier.algorithm}',
        ),
      );
      return AuditAssertionVerificationResult.invalid(
        'Signature algorithm mismatch: assertion uses '
        '${assertion.signatureAlgorithm}, verifier expects '
        '${verifier.algorithm}.',
        failureCode: VerificationFailureCode.algorithmMismatch,
        verifiedAt: verifiedAt,
        checks: checks,
      );
    }
    checks.add(
        const VerificationCheck(name: 'signature_algorithm', passed: true));

    if (challenge != null) {
      final challengeResult = _verifyChallengeBinding(
        assertion,
        challenge,
        verifiedAt: verifiedAt,
        priorChecks: checks,
      );
      if (challengeResult != null) {
        return challengeResult;
      }
    } else {
      checks.add(
        const VerificationCheck(
          name: 'challenge_binding',
          passed: true,
          detail: 'skipped_no_challenge_supplied',
        ),
      );
    }

    final canonical = encoder.encode(assertion.unsignedPayload);
    final signatureOk = verifier.verify(
      canonicalPayload: canonical,
      signature: assertion.signature,
    );
    if (!signatureOk) {
      checks.add(
        const VerificationCheck(
          name: 'signature',
          passed: false,
          detail: 'cryptographic_verification_failed',
        ),
      );
      return AuditAssertionVerificationResult.invalid(
        'Signature verification failed. Payload may have been altered or the '
        'wrong secret/key was used.',
        failureCode: VerificationFailureCode.signatureInvalid,
        verifiedAt: verifiedAt,
        checks: checks,
      );
    }
    checks.add(const VerificationCheck(name: 'signature', passed: true));

    final drift = _detectPayloadDrift(assertion);
    if (drift != null) {
      checks.add(
        VerificationCheck(
          name: 'payload_drift',
          passed: false,
          detail: drift,
        ),
      );
      return AuditAssertionVerificationResult.invalid(
        drift,
        failureCode: VerificationFailureCode.payloadDrift,
        verifiedAt: verifiedAt,
        checks: checks,
      );
    }
    checks.add(const VerificationCheck(name: 'payload_drift', passed: true));

    return AuditAssertionVerificationResult.valid(
      verifiedAt: verifiedAt,
      checks: checks,
    );
  }

  AuditAssertionVerificationResult? _verifyChallengeBinding(
    SignedAuditAssertion assertion,
    IntentChallenge challenge, {
    required DateTime verifiedAt,
    required List<VerificationCheck> priorChecks,
  }) {
    final checks = priorChecks;

    if (challenge.challengeId != assertion.challengeId) {
      checks.add(
        const VerificationCheck(
          name: 'challenge_id',
          passed: false,
        ),
      );
      return AuditAssertionVerificationResult.invalid(
        'Challenge id does not match assertion.',
        failureCode: VerificationFailureCode.challengeIdMismatch,
        verifiedAt: verifiedAt,
        checks: checks,
      );
    }
    checks.add(const VerificationCheck(name: 'challenge_id', passed: true));

    if (challenge.intentId != assertion.intentId) {
      checks.add(
        const VerificationCheck(
          name: 'challenge_intent_id',
          passed: false,
        ),
      );
      return AuditAssertionVerificationResult.invalid(
        'Challenge intentId does not match assertion.',
        failureCode: VerificationFailureCode.challengeIntentMismatch,
        verifiedAt: verifiedAt,
        checks: checks,
      );
    }
    checks.add(
      const VerificationCheck(name: 'challenge_intent_id', passed: true),
    );

    if (challenge.operationId != assertion.operationId) {
      checks.add(
        const VerificationCheck(
          name: 'challenge_operation_id',
          passed: false,
        ),
      );
      return AuditAssertionVerificationResult.invalid(
        'Challenge operationId does not match assertion.',
        failureCode: VerificationFailureCode.challengeOperationMismatch,
        verifiedAt: verifiedAt,
        checks: checks,
      );
    }
    checks.add(
      const VerificationCheck(name: 'challenge_operation_id', passed: true),
    );

    if (challenge.serverNonce != assertion.serverNonceReference) {
      checks.add(
        const VerificationCheck(
          name: 'challenge_nonce',
          passed: false,
        ),
      );
      return AuditAssertionVerificationResult.invalid(
        'Challenge serverNonce does not match assertion.',
        failureCode: VerificationFailureCode.challengeNonceMismatch,
        verifiedAt: verifiedAt,
        checks: checks,
      );
    }
    checks.add(const VerificationCheck(name: 'challenge_nonce', passed: true));

    if (challenge.operationTermsHash.value !=
        assertion.operationTermsHash.value) {
      checks.add(
        const VerificationCheck(
          name: 'challenge_terms_hash',
          passed: false,
        ),
      );
      return AuditAssertionVerificationResult.invalid(
        'Challenge operationTermsHash does not match assertion.',
        failureCode: VerificationFailureCode.challengeHashMismatch,
        verifiedAt: verifiedAt,
        checks: checks,
      );
    }
    checks.add(
      const VerificationCheck(name: 'challenge_terms_hash', passed: true),
    );

    if (challenge.isExpired(now: verifiedAt, policy: expirationPolicy)) {
      checks.add(
        const VerificationCheck(
          name: 'challenge_expiration',
          passed: false,
        ),
      );
      return AuditAssertionVerificationResult.invalid(
        'Intent challenge has expired.',
        failureCode: VerificationFailureCode.challengeExpired,
        verifiedAt: verifiedAt,
        checks: checks,
      );
    }
    checks.add(
      const VerificationCheck(name: 'challenge_expiration', passed: true),
    );

    return null;
  }

  String? _detectPayloadDrift(SignedAuditAssertion assertion) {
    final payload = assertion.unsignedPayload;

    String? mismatch(String field, Object? expected, Object? actual) {
      if (expected != actual) {
        return 'unsignedPayload.$field does not match assertion.';
      }
      return null;
    }

    return mismatch(
            'assertionId', assertion.assertionId, payload['assertionId']) ??
        mismatch('intentId', assertion.intentId, payload['intentId']) ??
        mismatch(
            'operationId', assertion.operationId, payload['operationId']) ??
        mismatch(
          'operationType',
          assertion.operationType,
          payload['operationType'],
        ) ??
        mismatch(
          'institutionReference',
          assertion.institutionReference,
          payload['institutionReference'],
        ) ??
        mismatch(
          'customerReference',
          assertion.customerReference,
          payload['customerReference'],
        ) ??
        mismatch(
            'challengeId', assertion.challengeId, payload['challengeId']) ??
        mismatch(
          'operationTermsHash',
          assertion.operationTermsHash.value,
          payload['operationTermsHash'],
        ) ??
        mismatch(
          'serverNonceReference',
          assertion.serverNonceReference,
          payload['serverNonceReference'],
        ) ??
        mismatch(
          'identityProofing',
          assertion.identityProofing,
          payload['identityProofing'],
        ) ??
        mismatch(
          'creditDecision',
          assertion.creditDecision,
          payload['creditDecision'],
        ) ??
        mismatch(
          'fraudDecision',
          assertion.fraudDecision,
          payload['fraudDecision'],
        ) ??
        mismatch(
          'eSignatureCompliance',
          assertion.eSignatureCompliance,
          payload['eSignatureCompliance'],
        ) ??
        mismatch(
          'schemaVersion',
          assertion.schemaVersion,
          payload['schemaVersion'],
        );
  }
}
