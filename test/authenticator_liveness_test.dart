import 'package:test/test.dart';
import 'package:transaction_intent_signer/transaction_intent_signer.dart';

void main() {
  group('AuthenticatorConfirmation', () {
    test('simulated confirmation creates valid model', () {
      final confirmation = AuthenticatorConfirmation.simulated(
        confirmedAt: DateTime.utc(2026, 8, 7, 12),
      );

      expect(confirmation.userPresence, isTrue);
      expect(confirmation.userVerification, isTrue);
      expect(
        confirmation.authenticatorType,
        AuthenticatorType.simulatedPasskey,
      );
      expect(confirmation.credentialReference, 'sim_cred_demo');
    });

    test('userPresence/userVerification serialize correctly', () {
      final confirmation = AuthenticatorConfirmation(
        userPresence: true,
        userVerification: false,
        authenticatorType: AuthenticatorType.webauthn,
        confirmedAt: DateTime.utc(2026, 8, 7, 12),
      );

      final json = confirmation.toJson();
      expect(json['userPresence'], isTrue);
      expect(json['userVerification'], isFalse);
      expect(json['authenticatorType'], 'webauthn');

      final roundTrip = AuthenticatorConfirmation.fromJson(json);
      expect(roundTrip.userPresence, isTrue);
      expect(roundTrip.userVerification, isFalse);
      expect(roundTrip.authenticatorType, AuthenticatorType.webauthn);
    });
  });

  group('LivenessInteractionSummary', () {
    test('default privacy flags are safe', () {
      const summary = LivenessInteractionSummary(
        facePresent: true,
        singleFace: true,
        challengeCompleted: true,
      );

      expect(summary.rawImagesStored, isFalse);
      expect(summary.rawImagesUploaded, isFalse);
      expect(summary.derivedSignalsOnly, isTrue);
    });

    test('liveness summary is optional and serializes', () {
      const summary = LivenessInteractionSummary(
        facePresent: true,
        singleFace: true,
        challengeCompleted: true,
        challengeType: 'smile',
        durationMs: 3000,
      );

      final json = summary.toJson();
      final roundTrip = LivenessInteractionSummary.fromJson(json);
      expect(roundTrip.challengeType, 'smile');
      expect(roundTrip.durationMs, 3000);
      expect(roundTrip.rawImagesStored, isFalse);
    });
  });
}
