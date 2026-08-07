import 'dart:convert';

import '../exceptions/transaction_intent_exception.dart';

/// Deterministic JSON encoder used before hashing operation terms.
///
/// Rules for [canonicalizationVersion] `canonical_json_v1`:
/// - Map keys are sorted lexicographically (UTF-16 code units).
/// - Nested maps are sorted recursively.
/// - Lists preserve order.
/// - Supported leaf types: [String], [num], [bool], `null`.
/// - Unsupported types throw [CanonicalizationException].
class CanonicalJsonEncoder {
  /// Creates a [CanonicalJsonEncoder].
  const CanonicalJsonEncoder();

  /// Version identifier for this canonicalization algorithm.
  static const String canonicalizationVersion = 'canonical_json_v1';

  /// Encodes [value] into a deterministic canonical JSON string.
  String encode(Object? value) {
    final buffer = StringBuffer();
    _write(buffer, value);
    return buffer.toString();
  }

  void _write(StringBuffer buffer, Object? value) {
    if (value == null) {
      buffer.write('null');
      return;
    }
    if (value is bool) {
      buffer.write(value ? 'true' : 'false');
      return;
    }
    if (value is num) {
      if (value is double && (value.isNaN || value.isInfinite)) {
        throw CanonicalizationException(
          'Unsupported numeric value: $value. '
          'NaN and Infinity are not allowed in canonical JSON.',
        );
      }
      buffer.write(jsonEncode(value));
      return;
    }
    if (value is String) {
      buffer.write(jsonEncode(value));
      return;
    }
    if (value is List) {
      buffer.write('[');
      for (var i = 0; i < value.length; i++) {
        if (i > 0) {
          buffer.write(',');
        }
        _write(buffer, value[i]);
      }
      buffer.write(']');
      return;
    }
    if (value is Map) {
      final entries = value.entries.map((e) {
        if (e.key is! String) {
          throw CanonicalizationException(
            'Map keys must be String, found: ${e.key.runtimeType}',
          );
        }
        return MapEntry(e.key as String, e.value);
      }).toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      buffer.write('{');
      for (var i = 0; i < entries.length; i++) {
        if (i > 0) {
          buffer.write(',');
        }
        buffer.write(jsonEncode(entries[i].key));
        buffer.write(':');
        _write(buffer, entries[i].value);
      }
      buffer.write('}');
      return;
    }

    throw CanonicalizationException(
      'Unsupported type for canonical JSON: ${value.runtimeType}. '
      'Supported types are String, num, bool, null, List, and Map with '
      'String keys.',
    );
  }
}
