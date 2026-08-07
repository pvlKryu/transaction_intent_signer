import 'package:test/test.dart';
import 'package:transaction_intent_signer/transaction_intent_signer.dart';

void main() {
  group('LivenessSummaryMapper', () {
    test(
        'maps flutter_liveness_actions-like signals with safe privacy defaults',
        () {
      final summary = LivenessSummaryMapper.fromFlutterLivenessActionsLike(
        faceDetected: true,
        faceCount: 1,
        challengePassed: true,
        actionType: 'turn_head_left',
        sessionDurationMs: 4200,
        avgFrameProcessingMs: 38.4,
        actionsCompleted: const ['blink', 'turn_head_left'],
        sdkVersion: 'illustrative-1.0.0',
      );

      expect(summary.facePresent, isTrue);
      expect(summary.singleFace, isTrue);
      expect(summary.challengeCompleted, isTrue);
      expect(summary.challengeType, 'turn_head_left');
      expect(summary.durationMs, 4200);
      expect(summary.averageProcessingMs, 38);
      expect(summary.rawImagesStored, isFalse);
      expect(summary.rawImagesUploaded, isFalse);
      expect(summary.derivedSignalsOnly, isTrue);
      expect(summary.metrics['source'], 'flutter_liveness_actions');
    });

    test('maps from generic JSON map', () {
      final summary = LivenessSummaryMapper.fromFlutterLivenessActionsLikeMap({
        'faceDetected': true,
        'faceCount': 2,
        'challengePassed': false,
        'actionType': 'blink',
        'sessionDurationMs': 1000,
      });

      expect(summary.singleFace, isFalse);
      expect(summary.challengeCompleted, isFalse);
      expect(summary.challengeType, 'blink');
    });
  });

  group('0.3.0 scenario flows', () {
    final signer = DemoHmacSigner('scenario-secret');
    final verifier = AuditAssertionVerifier(
      verifier: DemoHmacVerifier('scenario-secret'),
    );
    const hasher = OperationTermsHasher();
    final challenges = IntentChallengeBuilder();

    test('remote lending flow with mapped liveness summary', () {
      final now = DateTime.utc(2026, 8, 7, 16);
      final intent = TransactionIntent(
        intentId: 'intent_lending',
        operationId: 'loan_1',
        operationType: TransactionIntentType.confirmLoanOffer,
        customerReference: 'c1',
        institutionReference: 'cu_demo',
        operationTerms: const {
          'loanAmount': 15000,
          'currency': 'USD',
          'apr': 12.5,
        },
        createdAt: now,
      );
      final hash = hasher.sha256Canonical(intent.operationTerms);
      final challenge = challenges.build(
        intent: intent,
        operationTermsHash: hash,
        serverNonce: 'n1',
        expiresIn: const Duration(minutes: 10),
        issuedAt: now,
      );
      final liveness = LivenessSummaryMapper.fromFlutterLivenessActionsLike(
        faceDetected: true,
        faceCount: 1,
        challengePassed: true,
      );
      final assertion = AuditAssertionBuilder(signer: signer).build(
        intent: intent,
        challenge: challenge,
        authenticatorConfirmation:
            AuthenticatorConfirmation.simulated(confirmedAt: now),
        livenessInteractionSummary: liveness,
        createdAt: now,
      );

      expect(assertion.operationType, 'confirm_loan_offer');
      expect(
        verifier.verify(assertion, challenge: challenge, now: now).isValid,
        isTrue,
      );
    });

    test('large transfer flow', () {
      final now = DateTime.utc(2026, 8, 7, 17);
      final intent = TransactionIntent(
        intentId: 'intent_xfer',
        operationId: 'xfer_1',
        operationType: TransactionIntentType.authorizeLargeTransfer,
        customerReference: 'c2',
        institutionReference: 'bank_demo',
        operationTerms: const {
          'amount': 25000,
          'currency': 'USD',
          'toAccount': 'external_1',
        },
        createdAt: now,
      );
      final hash = hasher.sha256Canonical(intent.operationTerms);
      final challenge = challenges.build(
        intent: intent,
        operationTermsHash: hash,
        serverNonce: 'n2',
        expiresIn: const Duration(minutes: 5),
        issuedAt: now,
      );
      final assertion = AuditAssertionBuilder(signer: signer).build(
        intent: intent,
        challenge: challenge,
        authenticatorConfirmation:
            AuthenticatorConfirmation.simulated(confirmedAt: now),
        createdAt: now,
      );

      expect(assertion.operationType, 'authorize_large_transfer');
      expect(
        verifier.verify(assertion, challenge: challenge, now: now).isValid,
        isTrue,
      );
    });

    test('security settings flow', () {
      final now = DateTime.utc(2026, 8, 7, 18);
      final intent = TransactionIntent(
        intentId: 'intent_sec',
        operationId: 'sec_1',
        operationType: TransactionIntentType.changeSecuritySettings,
        customerReference: 'c3',
        institutionReference: 'cdfi_demo',
        operationTerms: const {
          'settings': {
            'recoveryPhone': '+1-555-0102',
            'mfaMethod': 'platform_passkey',
          },
        },
        createdAt: now,
      );
      final hash = hasher.sha256Canonical(intent.operationTerms);
      final challenge = challenges.build(
        intent: intent,
        operationTermsHash: hash,
        serverNonce: 'n3',
        expiresIn: const Duration(minutes: 8),
        issuedAt: now,
      );
      final assertion = AuditAssertionBuilder(signer: signer).build(
        intent: intent,
        challenge: challenge,
        authenticatorConfirmation:
            AuthenticatorConfirmation.simulated(confirmedAt: now),
        createdAt: now,
        assertionMetadata: const AssertionMetadata(
          producer: 'mobile_app',
          extra: {'flow': 'security_settings'},
        ),
      );

      expect(assertion.operationType, 'change_security_settings');
      expect(assertion.assertionMetadata.extra['flow'], 'security_settings');
      expect(
        verifier.verify(assertion, challenge: challenge, now: now).isValid,
        isTrue,
      );
    });
  });
}
