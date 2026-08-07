import 'package:meta/meta.dart';

import 'authenticator_type.dart';

/// Modeled result of an authenticator / passkey / WebAuthn confirmation.
///
/// This package does **not** implement production WebAuthn server logic. Host
/// applications should map real authenticator outcomes into this model.
@immutable
class AuthenticatorConfirmation {
  /// Creates an [AuthenticatorConfirmation].
  const AuthenticatorConfirmation({
    required this.userPresence,
    required this.userVerification,
    required this.authenticatorType,
    required this.confirmedAt,
    this.credentialReference,
    this.assertionPayload,
    this.metadata = const {},
  });

  /// Whether user presence was asserted by the authenticator.
  final bool userPresence;

  /// Whether user verification was asserted by the authenticator.
  final bool userVerification;

  /// Authenticator category for this confirmation.
  final AuthenticatorType authenticatorType;

  /// Optional credential / key handle reference.
  final String? credentialReference;

  /// Optional opaque assertion payload from the host authenticator stack.
  final Map<String, Object?>? assertionPayload;

  /// UTC confirmation timestamp.
  final DateTime confirmedAt;

  /// Additional opaque metadata.
  final Map<String, Object?> metadata;

  /// Creates a simulated passkey confirmation for demos and tests.
  factory AuthenticatorConfirmation.simulated({
    bool userPresence = true,
    bool userVerification = true,
    String? credentialReference = 'sim_cred_demo',
    Map<String, Object?>? assertionPayload,
    DateTime? confirmedAt,
    Map<String, Object?> metadata = const {},
  }) {
    return AuthenticatorConfirmation(
      userPresence: userPresence,
      userVerification: userVerification,
      authenticatorType: AuthenticatorType.simulatedPasskey,
      credentialReference: credentialReference,
      assertionPayload: assertionPayload ??
          const {
            'mode': 'simulated',
            'note':
                'Demo confirmation only. Not a production WebAuthn assertion.',
          },
      confirmedAt: (confirmedAt ?? DateTime.now()).toUtc(),
      metadata: metadata,
    );
  }

  /// Deserializes from JSON.
  factory AuthenticatorConfirmation.fromJson(Map<String, Object?> json) {
    final payloadRaw = json['assertionPayload'];
    final metadataRaw = json['metadata'];
    return AuthenticatorConfirmation(
      userPresence: json['userPresence']! as bool,
      userVerification: json['userVerification']! as bool,
      authenticatorType: AuthenticatorTypeX.fromWireName(
        json['authenticatorType']! as String,
      ),
      credentialReference: json['credentialReference'] as String?,
      assertionPayload:
          payloadRaw is Map ? Map<String, Object?>.from(payloadRaw) : null,
      confirmedAt: DateTime.parse(json['confirmedAt']! as String).toUtc(),
      metadata: metadataRaw is Map
          ? Map<String, Object?>.from(metadataRaw)
          : const {},
    );
  }

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        'userPresence': userPresence,
        'userVerification': userVerification,
        'authenticatorType': authenticatorType.wireName,
        if (credentialReference != null)
          'credentialReference': credentialReference,
        if (assertionPayload != null) 'assertionPayload': assertionPayload,
        'confirmedAt': confirmedAt.toUtc().toIso8601String(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  @override
  String toString() =>
      'AuthenticatorConfirmation(${authenticatorType.wireName}, '
      'uv=$userVerification, up=$userPresence)';
}
