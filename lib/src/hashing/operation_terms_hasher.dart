import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'canonical_json_encoder.dart';
import 'operation_terms_hash.dart';

/// Hashes operation / loan / transfer terms using canonical JSON + SHA-256.
///
/// Any change to hashed terms (amount, APR, recipient, phone number, consent
/// text hash, etc.) produces a different [OperationTermsHash.value].
class OperationTermsHasher {
  /// Creates an [OperationTermsHasher].
  const OperationTermsHasher({
    this.encoder = const CanonicalJsonEncoder(),
    this.includeCanonicalPayload = false,
  });

  /// Encoder used to produce a deterministic payload.
  final CanonicalJsonEncoder encoder;

  /// When true, include the canonical string on [OperationTermsHash].
  final bool includeCanonicalPayload;

  /// Hashes [terms] with SHA-256 over the canonical JSON encoding.
  OperationTermsHash sha256Canonical(Map<String, Object?> terms) {
    final canonical = encoder.encode(terms);
    final digest = sha256.convert(utf8.encode(canonical));
    return OperationTermsHash(
      algorithm: OperationTermsHashAlgorithms.sha256,
      canonicalization: OperationTermsHashAlgorithms.canonicalJsonV1,
      value: 'sha256:${digest.toString()}',
      canonicalPayload: includeCanonicalPayload ? canonical : null,
    );
  }
}
