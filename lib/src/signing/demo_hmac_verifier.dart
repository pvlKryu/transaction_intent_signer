import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../exceptions/transaction_intent_exception.dart';
import 'assertion_verifier.dart';

/// Demo HMAC-SHA256 verifier for reference and testing only.
///
/// Demo signing is provided for reference and testing only. Production
/// systems must use secure server-side key management and institution-specific
/// compliance controls.
class DemoHmacVerifier implements AssertionVerifier {
  /// Creates a [DemoHmacVerifier] with the given UTF-8 [secret].
  DemoHmacVerifier(this.secret) {
    if (secret.isEmpty) {
      throw const SignatureException(
        'Demo HMAC secret must be non-empty.',
        code: 'invalid_secret',
      );
    }
  }

  /// Shared secret used for HMAC (demo only).
  final String secret;

  @override
  String get algorithm => 'demo_hmac_sha256';

  @override
  bool verify({
    required String canonicalPayload,
    required String signature,
  }) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode(canonicalPayload));
    final expected = 'hmac-sha256:${digest.toString()}';
    return _constantTimeEquals(expected, signature);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
