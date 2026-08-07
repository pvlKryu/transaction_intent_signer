/// High-level categories of high-risk operations that can be confirmed.
///
/// Use [TransactionIntentType.custom] with
/// [IntentMetadata.customOperationType] when the built-in values are
/// insufficient.
enum TransactionIntentType {
  /// Confirm acceptance of a loan offer / credit terms.
  confirmLoanOffer,

  /// Confirm a loan or credit disbursement.
  confirmDisbursement,

  /// Provide electronic consent for disclosed terms.
  provideEConsent,

  /// Authorize a large fund transfer.
  authorizeLargeTransfer,

  /// Change an account recovery phone number.
  changeRecoveryPhone,

  /// Change security-related account settings.
  changeSecuritySettings,

  /// Add a new payee / beneficiary.
  addNewPayee,

  /// Institution-defined custom operation type.
  custom,
}

/// Extension helpers for [TransactionIntentType] serialization.
extension TransactionIntentTypeX on TransactionIntentType {
  /// Wire / JSON value for this type.
  String get wireName {
    switch (this) {
      case TransactionIntentType.confirmLoanOffer:
        return 'confirm_loan_offer';
      case TransactionIntentType.confirmDisbursement:
        return 'confirm_disbursement';
      case TransactionIntentType.provideEConsent:
        return 'provide_e_consent';
      case TransactionIntentType.authorizeLargeTransfer:
        return 'authorize_large_transfer';
      case TransactionIntentType.changeRecoveryPhone:
        return 'change_recovery_phone';
      case TransactionIntentType.changeSecuritySettings:
        return 'change_security_settings';
      case TransactionIntentType.addNewPayee:
        return 'add_new_payee';
      case TransactionIntentType.custom:
        return 'custom';
    }
  }

  /// Parses a wire name into a [TransactionIntentType].
  static TransactionIntentType fromWireName(String value) {
    switch (value) {
      case 'confirm_loan_offer':
        return TransactionIntentType.confirmLoanOffer;
      case 'confirm_disbursement':
        return TransactionIntentType.confirmDisbursement;
      case 'provide_e_consent':
        return TransactionIntentType.provideEConsent;
      case 'authorize_large_transfer':
        return TransactionIntentType.authorizeLargeTransfer;
      case 'change_recovery_phone':
        return TransactionIntentType.changeRecoveryPhone;
      case 'change_security_settings':
        return TransactionIntentType.changeSecuritySettings;
      case 'add_new_payee':
        return TransactionIntentType.addNewPayee;
      case 'custom':
        return TransactionIntentType.custom;
      default:
        return TransactionIntentType.custom;
    }
  }
}
