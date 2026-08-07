import 'package:uuid/uuid.dart';

import '../exceptions/transaction_intent_exception.dart';
import '../hashing/operation_terms_hash.dart';
import '../intent/transaction_intent.dart';
import 'challenge_expiration_policy.dart';
import 'intent_challenge.dart';

/// Builds [IntentChallenge] instances bound to a [TransactionIntent].
class IntentChallengeBuilder {
  /// Creates an [IntentChallengeBuilder].
  IntentChallengeBuilder({
    this.uuid = const Uuid(),
    this.expirationPolicy = const ChallengeExpirationPolicy(),
  });

  /// UUID generator used for challenge ids.
  final Uuid uuid;

  /// Policy used when validating challenge expiration.
  final ChallengeExpirationPolicy expirationPolicy;

  /// Builds a challenge for [intent] using [operationTermsHash] and
  /// [serverNonce].
  ///
  /// Throws [ChallengeException] when [intent] is already expired or when
  /// [expiresIn] is non-positive.
  IntentChallenge build({
    required TransactionIntent intent,
    required OperationTermsHash operationTermsHash,
    required String serverNonce,
    required Duration expiresIn,
    DateTime? issuedAt,
    String? challengeId,
  }) {
    if (expiresIn <= Duration.zero) {
      throw const ChallengeException(
        'expiresIn must be a positive duration.',
        code: 'invalid_expires_in',
      );
    }
    if (serverNonce.trim().isEmpty) {
      throw const ChallengeException(
        'serverNonce must be a non-empty string.',
        code: 'invalid_server_nonce',
      );
    }

    final now = (issuedAt ?? DateTime.now()).toUtc();
    if (intent.isExpired(now: now)) {
      throw const ChallengeException(
        'Cannot build a challenge for an expired transaction intent.',
        code: 'intent_expired',
      );
    }

    final id = challengeId ?? 'chal_${uuid.v4()}';
    final expiresAt = now.add(expiresIn);
    final operationType = intent.effectiveOperationType;

    final payload = <String, Object?>{
      'challengeId': id,
      'intentId': intent.intentId,
      'operationId': intent.operationId,
      'operationType': operationType,
      'operationTermsHash': operationTermsHash.value,
      'serverNonce': serverNonce,
      'issuedAt': now.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };

    return IntentChallenge(
      challengeId: id,
      intentId: intent.intentId,
      operationId: intent.operationId,
      operationType: operationType,
      operationTermsHash: operationTermsHash,
      serverNonce: serverNonce,
      issuedAt: now,
      expiresAt: expiresAt,
      challengePayload: payload,
    );
  }

  /// Ensures [challenge] is still valid at [now].
  ///
  /// Throws [ChallengeException] when expired.
  void ensureNotExpired(IntentChallenge challenge, {DateTime? now}) {
    if (challenge.isExpired(now: now, policy: expirationPolicy)) {
      throw ChallengeException(
        'Intent challenge ${challenge.challengeId} has expired.',
        code: 'challenge_expired',
      );
    }
  }
}
