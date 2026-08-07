import 'package:meta/meta.dart';

import 'package_info.dart';

/// Structured metadata attached to a [SignedAuditAssertion].
///
/// Host systems may add opaque keys via [extra]. Structured fields are
/// preferred for audit trail indexing.
@immutable
class AssertionMetadata {
  /// Creates [AssertionMetadata].
  const AssertionMetadata({
    this.schemaVersion = TransactionIntentSignerInfo.assertionSchemaVersion,
    this.packageName = TransactionIntentSignerInfo.packageName,
    this.packageVersion = TransactionIntentSignerInfo.packageVersion,
    this.producer,
    this.channel,
    this.correlationId,
    this.appVersion,
    this.locale,
    this.extra = const {},
  });

  /// Semantic assertion schema version (e.g. `tis_assertion_v1`).
  final String schemaVersion;

  /// Producing package name.
  final String packageName;

  /// Producing package version.
  final String packageVersion;

  /// Who produced the artifact (`mobile_app`, `backend`, etc.).
  final String? producer;

  /// Delivery channel (`mobile_app`, `web`, etc.).
  final String? channel;

  /// Host correlation / trace id for audit joins.
  final String? correlationId;

  /// Optional host application version.
  final String? appVersion;

  /// Optional locale associated with the confirmation UX.
  final String? locale;

  /// Additional opaque key/value metadata.
  final Map<String, Object?> extra;

  /// Deserializes from JSON.
  factory AssertionMetadata.fromJson(Map<String, Object?> json) {
    final extraRaw = json['extra'];
    return AssertionMetadata(
      schemaVersion: json['schemaVersion'] as String? ??
          TransactionIntentSignerInfo.assertionSchemaVersion,
      packageName: json['packageName'] as String? ??
          TransactionIntentSignerInfo.packageName,
      packageVersion: json['packageVersion'] as String? ??
          TransactionIntentSignerInfo.packageVersion,
      producer: json['producer'] as String?,
      channel: json['channel'] as String?,
      correlationId: json['correlationId'] as String?,
      appVersion: json['appVersion'] as String?,
      locale: json['locale'] as String?,
      extra: extraRaw is Map ? Map<String, Object?>.from(extraRaw) : const {},
    );
  }

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'packageName': packageName,
        'packageVersion': packageVersion,
        if (producer != null) 'producer': producer,
        if (channel != null) 'channel': channel,
        if (correlationId != null) 'correlationId': correlationId,
        if (appVersion != null) 'appVersion': appVersion,
        if (locale != null) 'locale': locale,
        if (extra.isNotEmpty) 'extra': extra,
      };

  /// Returns a copy with selected fields replaced.
  AssertionMetadata copyWith({
    String? schemaVersion,
    String? packageName,
    String? packageVersion,
    String? producer,
    String? channel,
    String? correlationId,
    String? appVersion,
    String? locale,
    Map<String, Object?>? extra,
  }) {
    return AssertionMetadata(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      packageName: packageName ?? this.packageName,
      packageVersion: packageVersion ?? this.packageVersion,
      producer: producer ?? this.producer,
      channel: channel ?? this.channel,
      correlationId: correlationId ?? this.correlationId,
      appVersion: appVersion ?? this.appVersion,
      locale: locale ?? this.locale,
      extra: extra ?? this.extra,
    );
  }

  /// Merges [extraEntries] into [extra].
  AssertionMetadata withExtra(Map<String, Object?> extraEntries) {
    if (extraEntries.isEmpty) {
      return this;
    }
    return copyWith(extra: {...extra, ...extraEntries});
  }

  @override
  String toString() => 'AssertionMetadata(${toJson()})';
}
