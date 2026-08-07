import 'package:meta/meta.dart';

import 'canonical_json_encoder.dart';

/// Result of hashing operation terms with a deterministic algorithm.
@immutable
class OperationTermsHash {
  /// Creates an [OperationTermsHash].
  const OperationTermsHash({
    required this.algorithm,
    required this.canonicalization,
    required this.value,
    this.canonicalPayload,
  });

  /// Hash algorithm identifier (e.g. `sha256`).
  final String algorithm;

  /// Canonicalization scheme identifier.
  final String canonicalization;

  /// Prefixed digest, e.g. `sha256:<hex>`.
  final String value;

  /// Optional canonical payload used to produce [value] (debug / audit).
  final String? canonicalPayload;

  /// Hex digest portion of [value] without the algorithm prefix.
  String get hexDigest {
    final separator = value.indexOf(':');
    if (separator < 0) {
      return value;
    }
    return value.substring(separator + 1);
  }

  /// Deserializes from JSON.
  factory OperationTermsHash.fromJson(Map<String, Object?> json) {
    return OperationTermsHash(
      algorithm: json['algorithm']! as String,
      canonicalization: json['canonicalization']! as String,
      value: json['value']! as String,
      canonicalPayload: json['canonicalPayload'] as String?,
    );
  }

  /// Serializes to JSON.
  Map<String, Object?> toJson({bool includeCanonicalPayload = false}) => {
        'algorithm': algorithm,
        'canonicalization': canonicalization,
        'value': value,
        if (includeCanonicalPayload && canonicalPayload != null)
          'canonicalPayload': canonicalPayload,
      };

  @override
  bool operator ==(Object other) {
    return other is OperationTermsHash &&
        other.algorithm == algorithm &&
        other.canonicalization == canonicalization &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(algorithm, canonicalization, value);

  @override
  String toString() => 'OperationTermsHash($value)';
}

/// Convenience constants for [OperationTermsHash].
abstract final class OperationTermsHashAlgorithms {
  /// SHA-256 algorithm label.
  static const String sha256 = 'sha256';

  /// Canonical JSON v1 scheme label.
  static const String canonicalJsonV1 =
      CanonicalJsonEncoder.canonicalizationVersion;
}
