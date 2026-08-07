import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../exceptions/transaction_intent_exception.dart';
import 'assertion_signer.dart';

/// Demo HMAC-SHA256 signer for reference and testing only.
///
/// Demo signing is provided for reference and testing only. Production
/// systems must use secure server-side key management and institution-specific
/// compliance controls.
class DemoHmacSigner implements AssertionSigner {
  /// Creates a [DemoHmacSigner] with the given UTF-8 [secret].
  DemoHmacSigner(this.secret) {
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
  String sign(String canonicalPayload) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode(canonicalPayload));
    return 'hmac-sha256:${digest.toString()}';
  }
}
