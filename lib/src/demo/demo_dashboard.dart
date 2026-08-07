import 'package:meta/meta.dart';

import '../audit/audit_assertion_verification_result.dart';
import '../audit/package_info.dart';
import '../audit/signed_audit_assertion.dart';

/// Schema version for demo dashboard snapshots.
abstract final class DemoDashboardSchema {
  /// Current demo dashboard schema label.
  static const String version = 'tis_demo_dashboard_v1';

  /// Producing package name.
  static const String packageName = TransactionIntentSignerInfo.packageName;
}

/// One row/card in a mobile demo dashboard.
@immutable
class DemoDashboardEntry {
  /// Creates a [DemoDashboardEntry].
  const DemoDashboardEntry({
    required this.assertionId,
    required this.intentId,
    required this.operationId,
    required this.operationType,
    required this.institutionReference,
    required this.customerReference,
    required this.status,
    required this.createdAt,
    required this.termsHashShort,
    required this.hasLiveness,
    this.verificationValid,
    this.failureCode,
    this.correlationId,
    this.flowLabel,
    this.channel,
  });

  /// Assertion id.
  final String assertionId;

  /// Intent id.
  final String intentId;

  /// Operation id.
  final String operationId;

  /// Operation type label.
  final String operationType;

  /// Institution reference.
  final String institutionReference;

  /// Customer reference.
  final String customerReference;

  /// Assertion status wire name.
  final String status;

  /// Assertion creation time.
  final DateTime createdAt;

  /// Short preview of the terms hash (for UI lists).
  final String termsHashShort;

  /// Whether a liveness summary is attached.
  final bool hasLiveness;

  /// Optional verification outcome.
  final bool? verificationValid;

  /// Optional verification failure code wire name.
  final String? failureCode;

  /// Optional correlation id from assertion metadata.
  final String? correlationId;

  /// Optional flow label for demo filtering.
  final String? flowLabel;

  /// Optional channel from assertion metadata.
  final String? channel;

  /// Builds an entry from an assertion and optional verification result.
  factory DemoDashboardEntry.fromAssertion(
    SignedAuditAssertion assertion, {
    AuditAssertionVerificationResult? verification,
    String? flowLabel,
  }) {
    final hash = assertion.operationTermsHash.value;
    final short = hash.length <= 18 ? hash : '${hash.substring(0, 18)}…';
    final extraFlow = assertion.assertionMetadata.extra['flow'];

    return DemoDashboardEntry(
      assertionId: assertion.assertionId,
      intentId: assertion.intentId,
      operationId: assertion.operationId,
      operationType: assertion.operationType,
      institutionReference: assertion.institutionReference,
      customerReference: assertion.customerReference,
      status: assertion.status.wireName,
      createdAt: assertion.createdAt,
      termsHashShort: short,
      hasLiveness: assertion.livenessInteractionSummary != null,
      verificationValid: verification?.isValid,
      failureCode: verification?.failureCode.wireName,
      correlationId: assertion.assertionMetadata.correlationId,
      flowLabel: flowLabel ?? (extraFlow is String ? extraFlow : null),
      channel: assertion.assertionMetadata.channel,
    );
  }

  /// Deserializes from JSON.
  factory DemoDashboardEntry.fromJson(Map<String, Object?> json) {
    return DemoDashboardEntry(
      assertionId: json['assertionId']! as String,
      intentId: json['intentId']! as String,
      operationId: json['operationId']! as String,
      operationType: json['operationType']! as String,
      institutionReference: json['institutionReference']! as String,
      customerReference: json['customerReference']! as String,
      status: json['status']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
      termsHashShort: json['termsHashShort']! as String,
      hasLiveness: json['hasLiveness']! as bool,
      verificationValid: json['verificationValid'] as bool?,
      failureCode: json['failureCode'] as String?,
      correlationId: json['correlationId'] as String?,
      flowLabel: json['flowLabel'] as String?,
      channel: json['channel'] as String?,
    );
  }

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        'assertionId': assertionId,
        'intentId': intentId,
        'operationId': operationId,
        'operationType': operationType,
        'institutionReference': institutionReference,
        'customerReference': customerReference,
        'status': status,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'termsHashShort': termsHashShort,
        'hasLiveness': hasLiveness,
        if (verificationValid != null) 'verificationValid': verificationValid,
        if (failureCode != null) 'failureCode': failureCode,
        if (correlationId != null) 'correlationId': correlationId,
        if (flowLabel != null) 'flowLabel': flowLabel,
        if (channel != null) 'channel': channel,
      };
}

/// Aggregate counters for a demo dashboard snapshot.
@immutable
class DemoDashboardSummary {
  /// Creates a [DemoDashboardSummary].
  const DemoDashboardSummary({
    required this.total,
    required this.verified,
    required this.failed,
    required this.withLiveness,
  });

  /// Total entries.
  final int total;

  /// Entries with `verificationValid == true`.
  final int verified;

  /// Entries with `verificationValid == false`.
  final int failed;

  /// Entries that include a liveness summary.
  final int withLiveness;

  /// Builds counters from entries.
  factory DemoDashboardSummary.fromEntries(List<DemoDashboardEntry> entries) {
    var verified = 0;
    var failed = 0;
    var withLiveness = 0;
    for (final e in entries) {
      if (e.verificationValid == true) {
        verified++;
      } else if (e.verificationValid == false) {
        failed++;
      }
      if (e.hasLiveness) {
        withLiveness++;
      }
    }
    return DemoDashboardSummary(
      total: entries.length,
      verified: verified,
      failed: failed,
      withLiveness: withLiveness,
    );
  }

  /// Deserializes from JSON.
  factory DemoDashboardSummary.fromJson(Map<String, Object?> json) {
    return DemoDashboardSummary(
      total: json['total']! as int,
      verified: json['verified']! as int,
      failed: json['failed']! as int,
      withLiveness: json['withLiveness']! as int,
    );
  }

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        'total': total,
        'verified': verified,
        'failed': failed,
        'withLiveness': withLiveness,
      };
}

/// Snapshot a Flutter demo dashboard can render or persist.
@immutable
class DemoDashboardSnapshot {
  /// Creates a [DemoDashboardSnapshot].
  const DemoDashboardSnapshot({
    required this.generatedAt,
    required this.entries,
    required this.summary,
    this.schemaVersion = DemoDashboardSchema.version,
    this.packageName = DemoDashboardSchema.packageName,
    this.packageVersion = TransactionIntentSignerInfo.packageVersion,
  });

  /// Schema version.
  final String schemaVersion;

  /// Package name that produced the snapshot shape.
  final String packageName;

  /// Package version.
  final String packageVersion;

  /// Snapshot generation time.
  final DateTime generatedAt;

  /// Dashboard rows.
  final List<DemoDashboardEntry> entries;

  /// Aggregate summary.
  final DemoDashboardSummary summary;

  /// Builds a snapshot from assertions.
  factory DemoDashboardSnapshot.fromAssertions(
    List<SignedAuditAssertion> assertions, {
    Map<String, AuditAssertionVerificationResult>? verificationByAssertionId,
    Map<String, String>? flowLabelByAssertionId,
    DateTime? generatedAt,
  }) {
    final entries = assertions
        .map(
          (a) => DemoDashboardEntry.fromAssertion(
            a,
            verification: verificationByAssertionId?[a.assertionId],
            flowLabel: flowLabelByAssertionId?[a.assertionId],
          ),
        )
        .toList();

    return DemoDashboardSnapshot(
      generatedAt: (generatedAt ?? DateTime.now()).toUtc(),
      entries: entries,
      summary: DemoDashboardSummary.fromEntries(entries),
    );
  }

  /// Deserializes from JSON.
  factory DemoDashboardSnapshot.fromJson(Map<String, Object?> json) {
    final entriesRaw = json['entries'];
    final summaryRaw = json['summary'];
    return DemoDashboardSnapshot(
      schemaVersion:
          json['schemaVersion'] as String? ?? DemoDashboardSchema.version,
      packageName:
          json['packageName'] as String? ?? DemoDashboardSchema.packageName,
      packageVersion: json['packageVersion'] as String? ??
          TransactionIntentSignerInfo.packageVersion,
      generatedAt: DateTime.parse(json['generatedAt']! as String).toUtc(),
      entries: entriesRaw is List
          ? entriesRaw
              .whereType<Map>()
              .map(
                (e) =>
                    DemoDashboardEntry.fromJson(Map<String, Object?>.from(e)),
              )
              .toList()
          : const [],
      summary: summaryRaw is Map
          ? DemoDashboardSummary.fromJson(Map<String, Object?>.from(summaryRaw))
          : const DemoDashboardSummary(
              total: 0,
              verified: 0,
              failed: 0,
              withLiveness: 0,
            ),
    );
  }

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'packageName': packageName,
        'packageVersion': packageVersion,
        'generatedAt': generatedAt.toUtc().toIso8601String(),
        'summary': summary.toJson(),
        'entries': entries.map((e) => e.toJson()).toList(),
      };
}
