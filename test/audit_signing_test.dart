import 'package:test/test.dart';
import 'package:transaction_intent_signer/transaction_intent_signer.dart';

TransactionIntent _loanIntent() {
  return TransactionIntent(
    intentId: 'intent_123',
    operationId: 'loan_offer_789',
    operationType: TransactionIntentType.confirmLoanOffer,
    customerReference: 'customer_456',
    institutionReference: 'community_bank_demo',
    operationTerms: const {
      'loanAmount': 15000,
      'currency': 'USD',
      'apr': 12.5,
      'termMonths': 36,
    },
    createdAt: DateTime.utc(2026, 8, 7, 12),
  );
}

SignedAuditAssertion _buildAssertion({
  TransactionIntent? intent,
  IntentChallenge? challenge,
  LivenessInteractionSummary? liveness,
}) {
  final usedIntent = intent ?? _loanIntent();
  const hasher = OperationTermsHasher();
  final hash = hasher.sha256Canonical(usedIntent.operationTerms);
  final usedChallenge = challenge ??
      IntentChallengeBuilder().build(
        intent: usedIntent,
        operationTermsHash: hash,
        serverNonce: 'nonce_abc',
        expiresIn: const Duration(minutes: 10),
        issuedAt: DateTime.utc(2026, 8, 7, 12, 1),
        challengeId: 'chal_1',
      );

  return AuditAssertionBuilder(
    signer: DemoHmacSigner('demo-secret'),
  ).build(
    intent: usedIntent,
    challenge: usedChallenge,
    authenticatorConfirmation: AuthenticatorConfirmation.simulated(
      confirmedAt: DateTime.utc(2026, 8, 7, 12, 2),
    ),
    livenessInteractionSummary: liveness,
    createdAt: DateTime.utc(2026, 8, 7, 12, 2),
    assertionId: 'assert_1',
  );
}

void main() {
  group('SignedAuditAssertion', () {
    test('assertion creation works with required status and privacy fields',
        () {
      final assertion = _buildAssertion(
        liveness: const LivenessInteractionSummary(
          facePresent: true,
          singleFace: true,
          challengeCompleted: true,
        ),
      );

      expect(assertion.assertionId, 'assert_1');
      expect(
        assertion.identityProofing,
        'not_performed_by_this_package',
      );
      expect(assertion.creditDecision, 'not_performed');
      expect(assertion.fraudDecision, 'not_performed');
      expect(assertion.eSignatureCompliance, 'not_claimed');
      expect(assertion.privacy.rawImagesStored, isFalse);
      expect(assertion.privacy.rawImagesUploaded, isFalse);
      expect(assertion.privacy.derivedSignalsOnly, isTrue);
      expect(assertion.privacy.mediaStoredByThisPackage, isFalse);
    });

    test('assertion JSON round-trip works', () {
      final assertion = _buildAssertion();
      final json = assertion.toJson();
      final roundTrip = SignedAuditAssertion.fromJson(json);

      expect(roundTrip.assertionId, assertion.assertionId);
      expect(roundTrip.signature, assertion.signature);
      expect(roundTrip.operationTermsHash.value,
          assertion.operationTermsHash.value);
      expect(roundTrip.identityProofing, 'not_performed_by_this_package');
      expect(roundTrip.creditDecision, 'not_performed');
      expect(roundTrip.fraudDecision, 'not_performed');
      expect(roundTrip.eSignatureCompliance, 'not_claimed');
    });

    test('expired challenge fails assertion builder', () {
      final intent = _loanIntent();
      const hasher = OperationTermsHasher();
      final hash = hasher.sha256Canonical(intent.operationTerms);
      final challenge = IntentChallengeBuilder().build(
        intent: intent,
        operationTermsHash: hash,
        serverNonce: 'nonce_abc',
        expiresIn: const Duration(minutes: 1),
        issuedAt: DateTime.utc(2026, 8, 7, 12),
        challengeId: 'chal_expired',
      );

      expect(
        () => AuditAssertionBuilder(
          signer: DemoHmacSigner('demo-secret'),
        ).build(
          intent: intent,
          challenge: challenge,
          authenticatorConfirmation: AuthenticatorConfirmation.simulated(
            confirmedAt: DateTime.utc(2026, 8, 7, 12, 5),
          ),
          createdAt: DateTime.utc(2026, 8, 7, 12, 5),
        ),
        throwsA(isA<ChallengeException>()),
      );
    });
  });

  group('signing', () {
    test('demo HMAC signature verifies', () {
      final assertion = _buildAssertion();
      final result = AuditAssertionVerifier(
        verifier: DemoHmacVerifier('demo-secret'),
      ).verify(assertion);

      expect(result.isValid, isTrue);
      expect(result.failureReason, isNull);
    });

    test('tampered payload fails verification', () {
      final assertion = _buildAssertion();
      final tampered = assertion.copyWith(
        unsignedPayload: {
          ...assertion.unsignedPayload,
          'customerReference': 'tampered_customer',
        },
      );

      final result = AuditAssertionVerifier(
        verifier: DemoHmacVerifier('demo-secret'),
      ).verify(tampered);

      expect(result.isValid, isFalse);
      expect(result.failureReason, contains('Signature verification failed'));
    });

    test('wrong secret fails verification', () {
      final assertion = _buildAssertion();
      final result = AuditAssertionVerifier(
        verifier: DemoHmacVerifier('wrong-secret'),
      ).verify(assertion);

      expect(result.isValid, isFalse);
    });

    test('expired challenge fails verifier when challenge supplied', () {
      final intent = _loanIntent();
      const hasher = OperationTermsHasher();
      final hash = hasher.sha256Canonical(intent.operationTerms);
      final challenge = IntentChallengeBuilder().build(
        intent: intent,
        operationTermsHash: hash,
        serverNonce: 'nonce_abc',
        expiresIn: const Duration(minutes: 1),
        issuedAt: DateTime.utc(2026, 8, 7, 12),
        challengeId: 'chal_1',
      );
      final assertion = AuditAssertionBuilder(
        signer: DemoHmacSigner('demo-secret'),
      ).build(
        intent: intent,
        challenge: challenge,
        authenticatorConfirmation: AuthenticatorConfirmation.simulated(
          confirmedAt: DateTime.utc(2026, 8, 7, 12, 0, 30),
        ),
        createdAt: DateTime.utc(2026, 8, 7, 12, 0, 30),
        assertionId: 'assert_1',
      );

      final result = AuditAssertionVerifier(
        verifier: DemoHmacVerifier('demo-secret'),
      ).verify(
        assertion,
        challenge: challenge,
        now: DateTime.utc(2026, 8, 7, 12, 5),
      );

      expect(result.isValid, isFalse);
      expect(result.failureReason, contains('expired'));
    });
  });
}
