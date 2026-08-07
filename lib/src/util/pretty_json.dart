import 'dart:convert';

/// Pretty-prints a JSON-compatible value with stable two-space indentation.
String prettyJson(Object? value) {
  return const JsonEncoder.withIndent('  ').convert(value);
}
