import 'package:meta/meta.dart';

import 'intent_metadata.dart';
import 'transaction_intent_type.dart';

/// A session describing a high-risk financial operation pending confirmation.
///
/// The intent binds opaque customer/institution references and the
/// operation terms that must be hashed before challenge creation.
@immutable
class TransactionIntent {
  /// Creates a [TransactionIntent].
  TransactionIntent({
    required this.intentId,
    required this.operationId,
    required this.operationType,
    required this.customerReference,
    required this.institutionReference,
    required this.operationTerms,
    required this.createdAt,
    this.expiresAt,
    this.metadata = const IntentMetadata(),
  });

  /// Unique id for this intent session.
  final String intentId;

  /// Host-system operation / offer / transfer id.
  final String operationId;

  /// High-level operation category.
  final TransactionIntentType operationType;

  /// Opaque customer reference (not a verified identity claim).
  final String customerReference;

  /// Opaque institution / lender / bank reference.
  final String institutionReference;

  /// Structured terms of the operation (loan terms, transfer details, etc.).
  final Map<String, Object?> operationTerms;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// Optional UTC expiration for the intent session.
  final DateTime? expiresAt;

  /// Optional metadata, including custom operation type labels.
  final IntentMetadata metadata;

  /// Effective operation type label for audit/export.
  ///
  /// Prefer [IntentMetadata.customOperationType] when [operationType] is
  /// [TransactionIntentType.custom].
  String get effectiveOperationType {
    if (operationType == TransactionIntentType.custom &&
        metadata.customOperationType != null &&
        metadata.customOperationType!.isNotEmpty) {
      return metadata.customOperationType!;
    }
    return operationType.wireName;
  }

  /// Whether this intent is expired relative to [now].
  bool isExpired({DateTime? now}) {
    if (expiresAt == null) {
      return false;
    }
    final reference = (now ?? DateTime.now()).toUtc();
    return !reference.isBefore(expiresAt!.toUtc());
  }

  /// Deserializes from JSON.
  factory TransactionIntent.fromJson(Map<String, Object?> json) {
    final termsRaw = json['operationTerms'];
    final metadataRaw = json['metadata'];
    return TransactionIntent(
      intentId: json['intentId']! as String,
      operationId: json['operationId']! as String,
      operationType: TransactionIntentTypeX.fromWireName(
        json['operationType']! as String,
      ),
      customerReference: json['customerReference']! as String,
      institutionReference: json['institutionReference']! as String,
      operationTerms: termsRaw is Map
          ? Map<String, Object?>.from(termsRaw)
          : <String, Object?>{},
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt']! as String).toUtc(),
      metadata: metadataRaw is Map
          ? IntentMetadata.fromJson(Map<String, Object?>.from(metadataRaw))
          : const IntentMetadata(),
    );
  }

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        'intentId': intentId,
        'operationId': operationId,
        'operationType': operationType.wireName,
        'customerReference': customerReference,
        'institutionReference': institutionReference,
        'operationTerms': operationTerms,
        'createdAt': createdAt.toUtc().toIso8601String(),
        if (expiresAt != null)
          'expiresAt': expiresAt!.toUtc().toIso8601String(),
        'metadata': metadata.toJson(),
        'effectiveOperationType': effectiveOperationType,
      };

  /// Returns a copy with selected fields replaced.
  TransactionIntent copyWith({
    String? intentId,
    String? operationId,
    TransactionIntentType? operationType,
    String? customerReference,
    String? institutionReference,
    Map<String, Object?>? operationTerms,
    DateTime? createdAt,
    DateTime? expiresAt,
    IntentMetadata? metadata,
  }) {
    return TransactionIntent(
      intentId: intentId ?? this.intentId,
      operationId: operationId ?? this.operationId,
      operationType: operationType ?? this.operationType,
      customerReference: customerReference ?? this.customerReference,
      institutionReference: institutionReference ?? this.institutionReference,
      operationTerms: operationTerms ?? this.operationTerms,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'TransactionIntent(intentId: $intentId, '
      'operationType: ${operationType.wireName})';
}
