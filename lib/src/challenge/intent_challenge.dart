import 'package:meta/meta.dart';

import '../hashing/operation_terms_hash.dart';
import '../intent/transaction_intent_type.dart';
import 'challenge_expiration_policy.dart';

/// A transaction-specific confirmation challenge.
///
/// The backend creates a challenge that binds the operation hash, session
/// nonce, and intent metadata. An authenticator signs the challenge, and the
/// server verifies the resulting assertion.
@immutable
class IntentChallenge {
  /// Creates an [IntentChallenge].
  const IntentChallenge({
    required this.challengeId,
    required this.intentId,
    required this.operationId,
    required this.operationType,
    required this.operationTermsHash,
    required this.serverNonce,
    required this.issuedAt,
    required this.expiresAt,
    required this.challengePayload,
  });

  /// Unique challenge identifier.
  final String challengeId;

  /// Linked intent session id.
  final String intentId;

  /// Linked operation id.
  final String operationId;

  /// Operation type wire name (or custom label).
  final String operationType;

  /// Hash of the bound operation terms.
  final OperationTermsHash operationTermsHash;

  /// Server-issued nonce bound into the challenge.
  final String serverNonce;

  /// UTC issuance timestamp.
  final DateTime issuedAt;

  /// UTC expiration timestamp.
  final DateTime expiresAt;

  /// Deterministic payload describing the bound challenge fields.
  final Map<String, Object?> challengePayload;

  /// Whether the challenge is expired under [policy].
  bool isExpired({
    DateTime? now,
    ChallengeExpirationPolicy policy = const ChallengeExpirationPolicy(),
  }) {
    return policy.isExpired(expiresAt, now: now);
  }

  /// Deserializes from JSON.
  factory IntentChallenge.fromJson(Map<String, Object?> json) {
    final hashRaw = json['operationTermsHash'];
    final payloadRaw = json['challengePayload'];
    return IntentChallenge(
      challengeId: json['challengeId']! as String,
      intentId: json['intentId']! as String,
      operationId: json['operationId']! as String,
      operationType: json['operationType']! as String,
      operationTermsHash: OperationTermsHash.fromJson(
        Map<String, Object?>.from(hashRaw as Map),
      ),
      serverNonce: json['serverNonce']! as String,
      issuedAt: DateTime.parse(json['issuedAt']! as String).toUtc(),
      expiresAt: DateTime.parse(json['expiresAt']! as String).toUtc(),
      challengePayload: payloadRaw is Map
          ? Map<String, Object?>.from(payloadRaw)
          : <String, Object?>{},
    );
  }

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        'challengeId': challengeId,
        'intentId': intentId,
        'operationId': operationId,
        'operationType': operationType,
        'operationTermsHash': operationTermsHash.toJson(),
        'serverNonce': serverNonce,
        'issuedAt': issuedAt.toUtc().toIso8601String(),
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'challengePayload': challengePayload,
      };

  @override
  String toString() =>
      'IntentChallenge(challengeId: $challengeId, intentId: $intentId)';
}

/// Re-export helper for docs / consumers reading challenge type names.
typedef IntentChallengeOperationType = TransactionIntentType;
