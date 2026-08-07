/// Verifies a signature over a canonical assertion payload.
abstract class AssertionVerifier {
  /// Algorithm identifier expected by this verifier.
  String get algorithm;

  /// Returns `true` when [signature] is valid for [canonicalPayload].
  bool verify({
    required String canonicalPayload,
    required String signature,
  });
}
