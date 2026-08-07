/// Signs a canonical assertion payload.
///
/// Demo implementations are provided for reference and testing only.
/// Production systems must use secure server-side key management and
/// institution-specific compliance controls.
abstract class AssertionSigner {
  /// Algorithm identifier written into signed assertions.
  String get algorithm;

  /// Signs [canonicalPayload] and returns an opaque signature string.
  String sign(String canonicalPayload);
}
