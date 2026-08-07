import 'dart:convert';

import '../exceptions/transaction_intent_exception.dart';
import 'package_info.dart';
import 'signed_audit_assertion.dart';

/// Experimental JWS-style compact envelope for [SignedAuditAssertion].
///
/// Format (inspired by JWS compact serialization, **not** a full RFC 7515
/// implementation):
///
/// ```text
/// base64url(header).base64url(payload).base64url(signature)
/// ```
///
/// - `header` describes algorithm / type / schema version
/// - `payload` is the signed `unsignedPayload` map
/// - `signature` is the existing assertion signature string (UTF-8)
///
/// This is an exploration aid for transport and storage. Production systems
/// should treat it as a reference encoding and apply institution-specific
/// key management and compliance controls.
class CompactAssertionEnvelope {
  /// Creates a [CompactAssertionEnvelope].
  const CompactAssertionEnvelope();

  /// Compact type label written into the header.
  static const String typ = 'TIS-ASSERTION-COMPACT';

  /// Encodes [assertion] into a compact three-part string.
  String encode(SignedAuditAssertion assertion) {
    final header = <String, Object?>{
      'alg': assertion.signatureAlgorithm,
      'typ': typ,
      'tis_schema': assertion.schemaVersion,
      'tis_package': TransactionIntentSignerInfo.packageName,
      'tis_package_version': assertion.assertionMetadata.packageVersion,
    };

    final payload = assertion.unsignedPayload;
    final signature = assertion.signature;

    return '${_b64urlJson(header)}.${_b64urlJson(payload)}.${_b64urlString(signature)}';
  }

  /// Decodes a compact envelope into a [SignedAuditAssertion].
  ///
  /// Reconstructs top-level fields from the payload and attaches the signature
  /// from the third segment. Throws [AuditAssertionException] when the
  /// envelope is malformed.
  SignedAuditAssertion decode(String compact) {
    final parts = compact.split('.');
    if (parts.length != 3) {
      throw const AuditAssertionException(
        'Compact assertion envelope must have three base64url segments.',
        code: 'compact_envelope_invalid',
      );
    }

    final header = _decodeJsonMap(parts[0], label: 'header');
    final payload = _decodeJsonMap(parts[1], label: 'payload');
    final signature = _decodeString(parts[2], label: 'signature');

    final alg = header['alg'] as String?;
    if (alg == null || alg.isEmpty) {
      throw const AuditAssertionException(
        'Compact assertion header is missing alg.',
        code: 'compact_envelope_invalid',
      );
    }

    final hashValue = payload['operationTermsHash'];
    if (hashValue is! String) {
      throw const AuditAssertionException(
        'Compact assertion payload is missing operationTermsHash string.',
        code: 'compact_envelope_invalid',
      );
    }

    try {
      return SignedAuditAssertion.fromUnsignedPayload(
        unsignedPayload: payload,
        signatureAlgorithm: alg,
        signature: signature,
      );
    } on Object catch (e) {
      throw AuditAssertionException(
        'Failed to reconstruct assertion from compact envelope: $e',
        code: 'compact_envelope_invalid',
      );
    }
  }

  String _b64urlJson(Map<String, Object?> value) {
    final json = jsonEncode(value);
    return _b64url(utf8.encode(json));
  }

  String _b64urlString(String value) => _b64url(utf8.encode(value));

  String _b64url(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  List<int> _b64urlDecode(String input) {
    var normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (normalized.length % 4) {
      case 2:
        normalized += '==';
      case 3:
        normalized += '=';
    }
    return base64.decode(normalized);
  }

  Map<String, Object?> _decodeJsonMap(String segment, {required String label}) {
    try {
      final decoded = utf8.decode(_b64urlDecode(segment));
      final dynamic json = jsonDecode(decoded);
      if (json is! Map) {
        throw AuditAssertionException(
          'Compact assertion $label must be a JSON object.',
          code: 'compact_envelope_invalid',
        );
      }
      return Map<String, Object?>.from(json);
    } on AuditAssertionException {
      rethrow;
    } on Object catch (e) {
      throw AuditAssertionException(
        'Failed to decode compact assertion $label: $e',
        code: 'compact_envelope_invalid',
      );
    }
  }

  String _decodeString(String segment, {required String label}) {
    try {
      return utf8.decode(_b64urlDecode(segment));
    } on Object catch (e) {
      throw AuditAssertionException(
        'Failed to decode compact assertion $label: $e',
        code: 'compact_envelope_invalid',
      );
    }
  }
}
