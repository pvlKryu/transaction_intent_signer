import 'package:uuid/uuid.dart';

import '../authenticator/authenticator_confirmation.dart';
import '../challenge/challenge_expiration_policy.dart';
import '../challenge/intent_challenge.dart';
import '../challenge/intent_challenge_builder.dart';
import '../exceptions/transaction_intent_exception.dart';
import '../hashing/canonical_json_encoder.dart';
import '../intent/transaction_intent.dart';
import '../liveness/liveness_interaction_summary.dart';
import '../signing/assertion_signer.dart';
import 'signed_audit_assertion.dart';

/// Builds [SignedAuditAssertion] artifacts from intent confirmation inputs.
class AuditAssertionBuilder {
  /// Creates an [AuditAssertionBuilder].
  AuditAssertionBuilder({
    required this.signer,
    this.uuid = const Uuid(),
    this.encoder = const CanonicalJsonEncoder(),
    this.expirationPolicy = const ChallengeExpirationPolicy(),
  });

  /// Signer used to produce the assertion signature.
  final AssertionSigner signer;

  /// UUID generator for assertion ids.
  final Uuid uuid;

  /// Canonical encoder for the unsigned payload.
  final CanonicalJsonEncoder encoder;

  /// Challenge expiration policy.
  final ChallengeExpirationPolicy expirationPolicy;

  /// Builds a signed audit assertion.
  ///
  /// Validates that [challenge] belongs to [intent] and is not expired, then
  /// signs a deterministic unsigned payload.
  SignedAuditAssertion build({
    required TransactionIntent intent,
    required IntentChallenge challenge,
    required AuthenticatorConfirmation authenticatorConfirmation,
    LivenessInteractionSummary? livenessInteractionSummary,
    DateTime? createdAt,
    String? assertionId,
    Map<String, Object?> metadata = const {},
  }) {
    _ensureChallengeMatchesIntent(intent, challenge);

    final challengeBuilder = IntentChallengeBuilder(
      expirationPolicy: expirationPolicy,
    );
    challengeBuilder.ensureNotExpired(challenge, now: createdAt);

    final now = (createdAt ?? DateTime.now()).toUtc();
    final id = assertionId ?? 'assert_${uuid.v4()}';
    final privacy = AssertionPrivacy.fromLiveness(livenessInteractionSummary);
    const statusFields = AssertionStatusFields();

    final unsignedPayload = <String, Object?>{
      'assertionId': id,
      'intentId': intent.intentId,
      'operationId': intent.operationId,
      'operationType': intent.effectiveOperationType,
      'institutionReference': intent.institutionReference,
      'customerReference': intent.customerReference,
      'operationTermsHash': challenge.operationTermsHash.value,
      'challengeId': challenge.challengeId,
      'serverNonceReference': challenge.serverNonce,
      'authenticatorConfirmation': authenticatorConfirmation.toJson(),
      if (livenessInteractionSummary != null)
        'livenessInteractionSummary': livenessInteractionSummary.toJson(),
      'createdAt': now.toIso8601String(),
      'privacy': privacy.toJson(),
      'identityProofing': statusFields.identityProofing,
      'creditDecision': statusFields.creditDecision,
      'fraudDecision': statusFields.fraudDecision,
      'eSignatureCompliance': statusFields.eSignatureCompliance,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };

    final canonical = encoder.encode(unsignedPayload);
    final signature = signer.sign(canonical);

    return SignedAuditAssertion(
      assertionId: id,
      intentId: intent.intentId,
      operationId: intent.operationId,
      operationType: intent.effectiveOperationType,
      institutionReference: intent.institutionReference,
      customerReference: intent.customerReference,
      operationTermsHash: challenge.operationTermsHash,
      challengeId: challenge.challengeId,
      serverNonceReference: challenge.serverNonce,
      authenticatorConfirmation: authenticatorConfirmation,
      livenessInteractionSummary: livenessInteractionSummary,
      createdAt: now,
      status: AuditAssertionStatus.created,
      privacy: privacy,
      statusFields: statusFields,
      signatureAlgorithm: signer.algorithm,
      signature: signature,
      unsignedPayload: unsignedPayload,
      metadata: metadata,
    );
  }

  void _ensureChallengeMatchesIntent(
    TransactionIntent intent,
    IntentChallenge challenge,
  ) {
    if (challenge.intentId != intent.intentId) {
      throw AuditAssertionException(
        'Challenge intentId (${challenge.intentId}) does not match intent '
        '(${intent.intentId}).',
        code: 'challenge_intent_mismatch',
      );
    }
    if (challenge.operationId != intent.operationId) {
      throw AuditAssertionException(
        'Challenge operationId (${challenge.operationId}) does not match '
        'intent (${intent.operationId}).',
        code: 'challenge_operation_mismatch',
      );
    }
    if (challenge.operationType != intent.effectiveOperationType) {
      throw AuditAssertionException(
        'Challenge operationType (${challenge.operationType}) does not match '
        'intent (${intent.effectiveOperationType}).',
        code: 'challenge_operation_type_mismatch',
      );
    }
  }
}
