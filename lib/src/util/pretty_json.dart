import 'dart:convert';

import '../hashing/canonical_json_encoder.dart';

/// Options controlling pretty JSON rendering for demos and debug panels.
class PrettyJsonOptions {
  /// Creates [PrettyJsonOptions].
  const PrettyJsonOptions({
    this.indent = '  ',
    this.sortMapKeys = false,
    this.maxStringLength,
    this.singleLine = false,
  });

  /// Indentation string used when [singleLine] is false.
  final String indent;

  /// When true, map keys are sorted recursively for stable readable output.
  final bool sortMapKeys;

  /// When set, long strings are truncated with an ellipsis for UI display.
  final int? maxStringLength;

  /// When true, encode without indentation.
  final bool singleLine;

  /// Preset for clipboard / share panels.
  static const PrettyJsonOptions sharePanel = PrettyJsonOptions(
    indent: '  ',
    sortMapKeys: true,
  );

  /// Preset for dense mobile debug overlays.
  static const PrettyJsonOptions compactOverlay = PrettyJsonOptions(
    singleLine: true,
    sortMapKeys: true,
    maxStringLength: 120,
  );
}

/// Pretty-prints a JSON-compatible value.
///
/// By default uses two-space indentation. Pass [options] for sorted keys,
/// truncation, or single-line output.
String prettyJson(
  Object? value, {
  PrettyJsonOptions options = const PrettyJsonOptions(),
}) {
  final prepared = options.sortMapKeys || options.maxStringLength != null
      ? _prepare(value, options)
      : value;

  if (options.singleLine) {
    return jsonEncode(prepared);
  }

  return JsonEncoder.withIndent(options.indent).convert(prepared);
}

/// Encodes [value] as minified JSON.
String encodeJson(Object? value) => jsonEncode(value);

/// Pretty-prints using canonical key ordering (via [CanonicalJsonEncoder]
/// semantics for maps) then indented formatting of the decoded structure.
String prettyCanonicalJson(
  Object? value, {
  String indent = '  ',
}) {
  const encoder = CanonicalJsonEncoder();
  final canonical = encoder.encode(value);
  final decoded = jsonDecode(canonical);
  return JsonEncoder.withIndent(indent).convert(decoded);
}

Object? _prepare(Object? value, PrettyJsonOptions options) {
  if (value == null || value is num || value is bool) {
    return value;
  }
  if (value is String) {
    final max = options.maxStringLength;
    if (max != null && value.length > max) {
      if (max <= 1) {
        return '…';
      }
      return '${value.substring(0, max - 1)}…';
    }
    return value;
  }
  if (value is List) {
    return value.map((e) => _prepare(e, options)).toList();
  }
  if (value is Map) {
    final entries = value.entries.map((e) {
      final key = e.key is String ? e.key as String : e.key.toString();
      return MapEntry(key, _prepare(e.value, options));
    }).toList();
    if (options.sortMapKeys) {
      entries.sort((a, b) => a.key.compareTo(b.key));
    }
    return Map<String, Object?>.fromEntries(entries);
  }
  return value.toString();
}
