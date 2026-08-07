/// Package identity and assertion schema constants.
abstract final class TransactionIntentSignerInfo {
  /// Pub package name.
  static const String packageName = 'transaction_intent_signer';

  /// Current package version.
  static const String packageVersion = '0.4.0';

  /// Assertion schema version embedded in artifacts.
  ///
  /// `tis_assertion_v1` remains the semantic payload shape. Later package
  /// versions may add metadata, compact envelopes, and demo helpers without
  /// changing this schema label unless the signed field set changes.
  static const String assertionSchemaVersion = 'tis_assertion_v1';
}
