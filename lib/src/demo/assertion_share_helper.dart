import '../audit/compact_assertion_envelope.dart';
import '../audit/signed_audit_assertion.dart';
import '../util/pretty_json.dart';

/// Export format for copy/share helpers.
enum AssertionShareFormat {
  /// Minified JSON object.
  json,

  /// Indented JSON for human review.
  prettyJson,

  /// Experimental compact three-segment envelope.
  compact,

  /// Short human-readable summary text.
  summaryText,
}

/// Serialization helpers for [AssertionShareFormat].
extension AssertionShareFormatX on AssertionShareFormat {
  /// Wire / JSON value.
  String get wireName {
    switch (this) {
      case AssertionShareFormat.json:
        return 'json';
      case AssertionShareFormat.prettyJson:
        return 'pretty_json';
      case AssertionShareFormat.compact:
        return 'compact';
      case AssertionShareFormat.summaryText:
        return 'summary_text';
    }
  }
}

/// A clipboard / share-sheet friendly assertion export.
class AssertionSharePayload {
  /// Creates an [AssertionSharePayload].
  const AssertionSharePayload({
    required this.format,
    required this.body,
    required this.mimeType,
    required this.suggestedFileName,
    this.label,
  });

  /// Export format.
  final AssertionShareFormat format;

  /// Payload body to copy or share.
  final String body;

  /// Suggested MIME type for host share sheets.
  final String mimeType;

  /// Suggested filename when saving/sharing as a file.
  final String suggestedFileName;

  /// Optional UI label.
  final String? label;

  /// Character length of [body].
  int get length => body.length;

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        'format': format.wireName,
        'mimeType': mimeType,
        'suggestedFileName': suggestedFileName,
        if (label != null) 'label': label,
        'length': length,
        'body': body,
      };
}

/// Builds copy/share payloads from a [SignedAuditAssertion].
///
/// Host Flutter apps can pass [AssertionSharePayload.body] to clipboard or
/// share APIs. This helper does not access platform channels itself.
class AssertionShareHelper {
  /// Creates an [AssertionShareHelper].
  const AssertionShareHelper({
    this.compactEnvelope = const CompactAssertionEnvelope(),
    this.prettyOptions = const PrettyJsonOptions(),
  });

  /// Compact encoder used for [AssertionShareFormat.compact].
  final CompactAssertionEnvelope compactEnvelope;

  /// Pretty-print options for JSON exports.
  final PrettyJsonOptions prettyOptions;

  /// Exports [assertion] in [format].
  AssertionSharePayload export(
    SignedAuditAssertion assertion, {
    required AssertionShareFormat format,
  }) {
    switch (format) {
      case AssertionShareFormat.json:
        return AssertionSharePayload(
          format: format,
          body: encodeJson(assertion.toJson()),
          mimeType: 'application/json',
          suggestedFileName: '${assertion.assertionId}.json',
          label: 'Assertion JSON',
        );
      case AssertionShareFormat.prettyJson:
        return AssertionSharePayload(
          format: format,
          body: prettyJson(assertion.toJson(), options: prettyOptions),
          mimeType: 'application/json',
          suggestedFileName: '${assertion.assertionId}.pretty.json',
          label: 'Pretty assertion JSON',
        );
      case AssertionShareFormat.compact:
        return AssertionSharePayload(
          format: format,
          body: compactEnvelope.encode(assertion),
          mimeType: 'text/plain',
          suggestedFileName: '${assertion.assertionId}.tiscompact',
          label: 'Compact envelope',
        );
      case AssertionShareFormat.summaryText:
        return AssertionSharePayload(
          format: format,
          body: summarize(assertion),
          mimeType: 'text/plain',
          suggestedFileName: '${assertion.assertionId}.txt',
          label: 'Assertion summary',
        );
    }
  }

  /// Exports common formats useful for a demo share sheet.
  List<AssertionSharePayload> exportAll(SignedAuditAssertion assertion) {
    return AssertionShareFormat.values
        .map((format) => export(assertion, format: format))
        .toList();
  }

  /// Builds a short human-readable summary for copy/share.
  String summarize(SignedAuditAssertion assertion) {
    final buffer = StringBuffer()
      ..writeln('Transaction intent assertion (technical artifact)')
      ..writeln('assertionId: ${assertion.assertionId}')
      ..writeln('intentId: ${assertion.intentId}')
      ..writeln('operationId: ${assertion.operationId}')
      ..writeln('operationType: ${assertion.operationType}')
      ..writeln('institution: ${assertion.institutionReference}')
      ..writeln('customer: ${assertion.customerReference}')
      ..writeln('challengeId: ${assertion.challengeId}')
      ..writeln('termsHash: ${assertion.operationTermsHash.value}')
      ..writeln('createdAt: ${assertion.createdAt.toUtc().toIso8601String()}')
      ..writeln('status: ${assertion.status.wireName}')
      ..writeln('identityProofing: ${assertion.identityProofing}')
      ..writeln('creditDecision: ${assertion.creditDecision}')
      ..writeln('fraudDecision: ${assertion.fraudDecision}')
      ..writeln('eSignatureCompliance: ${assertion.eSignatureCompliance}')
      ..writeln(
        'Note: audit-friendly technical artifact only; not identity, fraud, '
        'credit, or legal compliance proof.',
      );
    return buffer.toString();
  }
}
