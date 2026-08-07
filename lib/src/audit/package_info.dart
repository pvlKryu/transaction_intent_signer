/// Package identity and assertion schema constants.
abstract final class TransactionIntentSignerInfo {
  /// Pub package name.
  static const String packageName = 'transaction_intent_signer';

  /// Current package version.
  static const String packageVersion = '0.2.0';

  /// Assertion schema version embedded in artifacts.
  ///
  /// `tis_assertion_v1` remains the semantic payload shape; `0.2.0` adds
  /// structured metadata and optional compact envelope export.
  static const String assertionSchemaVersion = 'tis_assertion_v1';
}
