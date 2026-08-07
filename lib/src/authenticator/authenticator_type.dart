/// Types of authenticator confirmation results modeled by this package.
///
/// This package models confirmation outcomes. It does not implement a
/// production WebAuthn / passkey server.
enum AuthenticatorType {
  /// Platform authenticator / passkey confirmation.
  platformPasskey,

  /// Generic WebAuthn confirmation.
  webauthn,

  /// Simulated passkey confirmation for demos and tests.
  simulatedPasskey,

  /// Manual demo confirmation without a real authenticator.
  manualDemoConfirmation,

  /// Institution-defined custom authenticator label.
  custom,
}

/// Serialization helpers for [AuthenticatorType].
extension AuthenticatorTypeX on AuthenticatorType {
  /// Wire / JSON value.
  String get wireName {
    switch (this) {
      case AuthenticatorType.platformPasskey:
        return 'platform_passkey';
      case AuthenticatorType.webauthn:
        return 'webauthn';
      case AuthenticatorType.simulatedPasskey:
        return 'simulated_passkey';
      case AuthenticatorType.manualDemoConfirmation:
        return 'manual_demo_confirmation';
      case AuthenticatorType.custom:
        return 'custom';
    }
  }

  /// Parses a wire name into an [AuthenticatorType].
  static AuthenticatorType fromWireName(String value) {
    switch (value) {
      case 'platform_passkey':
        return AuthenticatorType.platformPasskey;
      case 'webauthn':
        return AuthenticatorType.webauthn;
      case 'simulated_passkey':
        return AuthenticatorType.simulatedPasskey;
      case 'manual_demo_confirmation':
        return AuthenticatorType.manualDemoConfirmation;
      case 'custom':
        return AuthenticatorType.custom;
      default:
        return AuthenticatorType.custom;
    }
  }
}
