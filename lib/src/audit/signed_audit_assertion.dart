import 'package:meta/meta.dart';

import '../authenticator/authenticator_confirmation.dart';
import '../hashing/operation_terms_hash.dart';
import '../liveness/liveness_interaction_summary.dart';
import 'assertion_metadata.dart';
import 'package_info.dart';

/// Privacy flags embedded in a [SignedAuditAssertion].
@immutable
class AssertionPrivacy {
  /// Creates [AssertionPrivacy].
  const AssertionPrivacy({
    this.rawImagesStored = false,
    this.rawImagesUploaded = false,
    this.derivedSignalsOnly = true,
    this.mediaStoredByThisPackage = false,
  });

  /// Whether raw images were stored by the host flow.
  final bool rawImagesStored;

  /// Whether raw images were uploaded by the host flow.
  final bool rawImagesUploaded;

  /// Whether only derived signals are represented.
  final bool derivedSignalsOnly;

  /// Always `false` for this package — media is never stored here.
  final bool mediaStoredByThisPackage;

  /// Builds privacy flags from an optional liveness summary.
  factory AssertionPrivacy.fromLiveness(LivenessInteractionSummary? summary) {
    if (summary == null) {
      return const AssertionPrivacy();
    }
    return AssertionPrivacy(
      rawImagesStored: summary.rawImagesStored,
      rawImagesUploaded: summary.rawImagesUploaded,
      derivedSignalsOnly: summary.derivedSignalsOnly,
      mediaStoredByThisPackage: false,
    );
  }

  /// Deserializes from JSON.
  factory AssertionPrivacy.fromJson(Map<String, Object?> json) {
    return AssertionPrivacy(
      rawImagesStored: json['rawImagesStored'] as bool? ?? false,
      rawImagesUploaded: json['rawImagesUploaded'] as bool? ?? false,
      derivedSignalsOnly: json['derivedSignalsOnly'] as bool? ?? true,
      mediaStoredByThisPackage:
          json['mediaStoredByThisPackage'] as bool? ?? false,
    );
  }

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        'rawImagesStored': rawImagesStored,
        'rawImagesUploaded': rawImagesUploaded,
        'derivedSignalsOnly': derivedSignalsOnly,
        'mediaStoredByThisPackage': mediaStoredByThisPackage,
      };
}

/// Fixed status fields clarifying package non-claims.
@immutable
class AssertionStatusFields {
  /// Creates [AssertionStatusFields] with package-required defaults.
  const AssertionStatusFields({
    this.identityProofing = notPerformedByThisPackage,
    this.creditDecision = notPerformed,
    this.fraudDecision = notPerformed,
    this.eSignatureCompliance = notClaimed,
  });

  /// Identity proofing was not performed by this package.
  static const String notPerformedByThisPackage =
      'not_performed_by_this_package';

  /// Decisioning was not performed.
  static const String notPerformed = 'not_performed';

  /// Legal e-signature compliance is not claimed.
  static const String notClaimed = 'not_claimed';

  /// Identity proofing status.
  final String identityProofing;

  /// Credit decision status.
  final String creditDecision;

  /// Fraud decision status.
  final String fraudDecision;

  /// E-signature compliance claim status.
  final String eSignatureCompliance;

  /// Deserializes from JSON.
  factory AssertionStatusFields.fromJson(Map<String, Object?> json) {
    return AssertionStatusFields(
      identityProofing:
          json['identityProofing'] as String? ?? notPerformedByThisPackage,
      creditDecision: json['creditDecision'] as String? ?? notPerformed,
      fraudDecision: json['fraudDecision'] as String? ?? notPerformed,
      eSignatureCompliance:
          json['eSignatureCompliance'] as String? ?? notClaimed,
    );
  }

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        'identityProofing': identityProofing,
        'creditDecision': creditDecision,
        'fraudDecision': fraudDecision,
        'eSignatureCompliance': eSignatureCompliance,
      };
}

/// High-level status of a signed audit assertion artifact.
enum AuditAssertionStatus {
  /// Assertion was created successfully as a technical artifact.
  created,

  /// Assertion was verified by a verifier implementation.
  verified,

  /// Assertion failed verification.
  verificationFailed,
}

/// Serialization helpers for [AuditAssertionStatus].
extension AuditAssertionStatusX on AuditAssertionStatus {
  /// Wire / JSON value.
  String get wireName {
    switch (this) {
      case AuditAssertionStatus.created:
        return 'created';
      case AuditAssertionStatus.verified:
        return 'verified';
      case AuditAssertionStatus.verificationFailed:
        return 'verification_failed';
    }
  }

  /// Parses a wire name.
  static AuditAssertionStatus fromWireName(String value) {
    switch (value) {
      case 'verified':
        return AuditAssertionStatus.verified;
      case 'verification_failed':
        return AuditAssertionStatus.verificationFailed;
      case 'created':
      default:
        return AuditAssertionStatus.created;
    }
  }
}

/// A signed, audit-friendly technical assertion for an intent confirmation.
///
/// The package creates audit-friendly technical artifacts that can support
/// transaction intent verification workflows. It does not make identity,
/// fraud, credit, legal, or compliance decisions.
@immutable
class SignedAuditAssertion {
  /// Creates a [SignedAuditAssertion].
  const SignedAuditAssertion({
    required this.assertionId,
    required this.intentId,
    required this.operationId,
    required this.operationType,
    required this.institutionReference,
    required this.customerReference,
    required this.operationTermsHash,
    required this.challengeId,
    required this.serverNonceReference,
    required this.authenticatorConfirmation,
    required this.createdAt,
    required this.signatureAlgorithm,
    required this.signature,
    required this.unsignedPayload,
    this.livenessInteractionSummary,
    this.status = AuditAssertionStatus.created,
    this.privacy = const AssertionPrivacy(),
    this.statusFields = const AssertionStatusFields(),
    this.schemaVersion = TransactionIntentSignerInfo.assertionSchemaVersion,
    this.assertionMetadata = const AssertionMetadata(),
    this.metadata = const {},
  });

  /// Unique assertion id.
  final String assertionId;

  /// Linked intent id.
  final String intentId;

  /// Linked operation id.
  final String operationId;

  /// Operation type label.
  final String operationType;

  /// Institution reference.
  final String institutionReference;

  /// Customer reference.
  final String customerReference;

  /// Bound operation terms hash.
  final OperationTermsHash operationTermsHash;

  /// Bound challenge id.
  final String challengeId;

  /// Server nonce reference from the challenge.
  final String serverNonceReference;

  /// Modeled authenticator confirmation.
  final AuthenticatorConfirmation authenticatorConfirmation;

  /// Optional liveness-aware summary from the host app.
  final LivenessInteractionSummary? livenessInteractionSummary;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// Artifact status.
  final AuditAssertionStatus status;

  /// Privacy flags.
  final AssertionPrivacy privacy;

  /// Required non-claim status fields.
  final AssertionStatusFields statusFields;

  /// Semantic schema version for this artifact.
  final String schemaVersion;

  /// Structured assertion metadata for audit indexing.
  final AssertionMetadata assertionMetadata;

  /// Signature algorithm label.
  final String signatureAlgorithm;

  /// Opaque signature string.
  final String signature;

  /// Canonical unsigned payload that was signed.
  final Map<String, Object?> unsignedPayload;

  /// Additional opaque metadata (merged into [assertionMetadata.extra] by
  /// builders; retained for backward-compatible export).
  final Map<String, Object?> metadata;

  /// Convenience accessors matching the required assertion status names.
  String get identityProofing => statusFields.identityProofing;

  /// Credit decision non-claim.
  String get creditDecision => statusFields.creditDecision;

  /// Fraud decision non-claim.
  String get fraudDecision => statusFields.fraudDecision;

  /// E-signature compliance non-claim.
  String get eSignatureCompliance => statusFields.eSignatureCompliance;

  /// Reconstructs an assertion from a signed [unsignedPayload] map.
  ///
  /// Used by compact envelope decoding and audit importers.
  factory SignedAuditAssertion.fromUnsignedPayload({
    required Map<String, Object?> unsignedPayload,
    required String signatureAlgorithm,
    required String signature,
    AuditAssertionStatus status = AuditAssertionStatus.created,
  }) {
    final authRaw = unsignedPayload['authenticatorConfirmation'];
    final livenessRaw = unsignedPayload['livenessInteractionSummary'];
    final privacyRaw = unsignedPayload['privacy'];
    final metadataBlock = unsignedPayload['assertionMetadata'];
    final legacyMetadata = unsignedPayload['metadata'];

    final hashValue = unsignedPayload['operationTermsHash']! as String;

    return SignedAuditAssertion(
      assertionId: unsignedPayload['assertionId']! as String,
      intentId: unsignedPayload['intentId']! as String,
      operationId: unsignedPayload['operationId']! as String,
      operationType: unsignedPayload['operationType']! as String,
      institutionReference: unsignedPayload['institutionReference']! as String,
      customerReference: unsignedPayload['customerReference']! as String,
      operationTermsHash: OperationTermsHash(
        algorithm: OperationTermsHashAlgorithms.sha256,
        canonicalization: OperationTermsHashAlgorithms.canonicalJsonV1,
        value: hashValue,
      ),
      challengeId: unsignedPayload['challengeId']! as String,
      serverNonceReference: unsignedPayload['serverNonceReference']! as String,
      authenticatorConfirmation: AuthenticatorConfirmation.fromJson(
        Map<String, Object?>.from(authRaw as Map),
      ),
      livenessInteractionSummary: livenessRaw is Map
          ? LivenessInteractionSummary.fromJson(
              Map<String, Object?>.from(livenessRaw),
            )
          : null,
      createdAt:
          DateTime.parse(unsignedPayload['createdAt']! as String).toUtc(),
      status: status,
      privacy: privacyRaw is Map
          ? AssertionPrivacy.fromJson(Map<String, Object?>.from(privacyRaw))
          : const AssertionPrivacy(),
      statusFields: AssertionStatusFields(
        identityProofing: unsignedPayload['identityProofing'] as String? ??
            AssertionStatusFields.notPerformedByThisPackage,
        creditDecision: unsignedPayload['creditDecision'] as String? ??
            AssertionStatusFields.notPerformed,
        fraudDecision: unsignedPayload['fraudDecision'] as String? ??
            AssertionStatusFields.notPerformed,
        eSignatureCompliance:
            unsignedPayload['eSignatureCompliance'] as String? ??
                AssertionStatusFields.notClaimed,
      ),
      schemaVersion: unsignedPayload['schemaVersion'] as String? ??
          TransactionIntentSignerInfo.assertionSchemaVersion,
      assertionMetadata: metadataBlock is Map
          ? AssertionMetadata.fromJson(Map<String, Object?>.from(metadataBlock))
          : const AssertionMetadata(),
      signatureAlgorithm: signatureAlgorithm,
      signature: signature,
      unsignedPayload: unsignedPayload,
      metadata: legacyMetadata is Map
          ? Map<String, Object?>.from(legacyMetadata)
          : const {},
    );
  }

  /// Deserializes from JSON.
  factory SignedAuditAssertion.fromJson(Map<String, Object?> json) {
    final hashRaw = json['operationTermsHash'];
    final authRaw = json['authenticatorConfirmation'];
    final livenessRaw = json['livenessInteractionSummary'];
    final privacyRaw = json['privacy'];
    final unsignedRaw = json['unsignedPayload'];
    final metadataRaw = json['metadata'];
    final assertionMetadataRaw = json['assertionMetadata'];

    return SignedAuditAssertion(
      assertionId: json['assertionId']! as String,
      intentId: json['intentId']! as String,
      operationId: json['operationId']! as String,
      operationType: json['operationType']! as String,
      institutionReference: json['institutionReference']! as String,
      customerReference: json['customerReference']! as String,
      operationTermsHash: OperationTermsHash.fromJson(
        Map<String, Object?>.from(hashRaw as Map),
      ),
      challengeId: json['challengeId']! as String,
      serverNonceReference: json['serverNonceReference']! as String,
      authenticatorConfirmation: AuthenticatorConfirmation.fromJson(
        Map<String, Object?>.from(authRaw as Map),
      ),
      livenessInteractionSummary: livenessRaw is Map
          ? LivenessInteractionSummary.fromJson(
              Map<String, Object?>.from(livenessRaw),
            )
          : null,
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
      status: AuditAssertionStatusX.fromWireName(
        json['status'] as String? ?? 'created',
      ),
      privacy: privacyRaw is Map
          ? AssertionPrivacy.fromJson(Map<String, Object?>.from(privacyRaw))
          : const AssertionPrivacy(),
      statusFields: AssertionStatusFields(
        identityProofing: json['identityProofing'] as String? ??
            AssertionStatusFields.notPerformedByThisPackage,
        creditDecision: json['creditDecision'] as String? ??
            AssertionStatusFields.notPerformed,
        fraudDecision: json['fraudDecision'] as String? ??
            AssertionStatusFields.notPerformed,
        eSignatureCompliance: json['eSignatureCompliance'] as String? ??
            AssertionStatusFields.notClaimed,
      ),
      schemaVersion: json['schemaVersion'] as String? ??
          TransactionIntentSignerInfo.assertionSchemaVersion,
      assertionMetadata: assertionMetadataRaw is Map
          ? AssertionMetadata.fromJson(
              Map<String, Object?>.from(assertionMetadataRaw),
            )
          : const AssertionMetadata(),
      signatureAlgorithm: json['signatureAlgorithm']! as String,
      signature: json['signature']! as String,
      unsignedPayload: unsignedRaw is Map
          ? Map<String, Object?>.from(unsignedRaw)
          : <String, Object?>{},
      metadata: metadataRaw is Map
          ? Map<String, Object?>.from(metadataRaw)
          : const {},
    );
  }

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'assertionId': assertionId,
        'intentId': intentId,
        'operationId': operationId,
        'operationType': operationType,
        'institutionReference': institutionReference,
        'customerReference': customerReference,
        'operationTermsHash': operationTermsHash.toJson(),
        'challengeId': challengeId,
        'serverNonceReference': serverNonceReference,
        'authenticatorConfirmation': authenticatorConfirmation.toJson(),
        if (livenessInteractionSummary != null)
          'livenessInteractionSummary': livenessInteractionSummary!.toJson(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'status': status.wireName,
        'privacy': privacy.toJson(),
        'identityProofing': identityProofing,
        'creditDecision': creditDecision,
        'fraudDecision': fraudDecision,
        'eSignatureCompliance': eSignatureCompliance,
        'assertionMetadata': assertionMetadata.toJson(),
        'signatureAlgorithm': signatureAlgorithm,
        'signature': signature,
        'unsignedPayload': unsignedPayload,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Returns a copy with selected fields replaced.
  SignedAuditAssertion copyWith({
    AuditAssertionStatus? status,
    String? signature,
    Map<String, Object?>? unsignedPayload,
    Map<String, Object?>? metadata,
    AssertionMetadata? assertionMetadata,
    String? schemaVersion,
  }) {
    return SignedAuditAssertion(
      assertionId: assertionId,
      intentId: intentId,
      operationId: operationId,
      operationType: operationType,
      institutionReference: institutionReference,
      customerReference: customerReference,
      operationTermsHash: operationTermsHash,
      challengeId: challengeId,
      serverNonceReference: serverNonceReference,
      authenticatorConfirmation: authenticatorConfirmation,
      livenessInteractionSummary: livenessInteractionSummary,
      createdAt: createdAt,
      status: status ?? this.status,
      privacy: privacy,
      statusFields: statusFields,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      assertionMetadata: assertionMetadata ?? this.assertionMetadata,
      signatureAlgorithm: signatureAlgorithm,
      signature: signature ?? this.signature,
      unsignedPayload: unsignedPayload ?? this.unsignedPayload,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() =>
      'SignedAuditAssertion(assertionId: $assertionId, status: ${status.wireName})';
}
