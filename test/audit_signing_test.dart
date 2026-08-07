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
  AssertionMetadata? assertionMetadata,
  Map<String, Object?> metadata = const {},
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
    assertionMetadata: assertionMetadata,
    metadata: metadata,
  );
}

AuditAssertionVerifier get _verifier => AuditAssertionVerifier(
      verifier: DemoHmacVerifier('demo-secret'),
    );

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
      expect(assertion.schemaVersion, 'tis_assertion_v1');
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
      expect(
        assertion.assertionMetadata.packageName,
        'transaction_intent_signer',
      );
      expect(assertion.assertionMetadata.packageVersion, '0.4.0');
    });

    test('assertion metadata is included and round-trips', () {
      final assertion = _buildAssertion(
        assertionMetadata: const AssertionMetadata(
          producer: 'backend',
          channel: 'mobile_app',
          correlationId: 'corr_123',
          appVersion: '1.2.3',
        ),
        metadata: const {'legacyKey': 'legacyValue'},
      );

      expect(assertion.assertionMetadata.producer, 'backend');
      expect(assertion.assertionMetadata.correlationId, 'corr_123');
      expect(assertion.assertionMetadata.extra['legacyKey'], 'legacyValue');

      final roundTrip = SignedAuditAssertion.fromJson(assertion.toJson());
      expect(roundTrip.schemaVersion, 'tis_assertion_v1');
      expect(roundTrip.assertionMetadata.producer, 'backend');
      expect(roundTrip.assertionMetadata.extra['legacyKey'], 'legacyValue');
      expect(roundTrip.metadata['legacyKey'], 'legacyValue');
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

  group('signing and verification result model', () {
    test('demo HMAC signature verifies with checks and failureCode none', () {
      final assertion = _buildAssertion();
      final result = _verifier.verify(assertion);

      expect(result.isValid, isTrue);
      expect(result.failureReason, isNull);
      expect(result.failureCode, VerificationFailureCode.none);
      expect(result.checks, isNotEmpty);
      expect(result.checks.every((c) => c.passed), isTrue);

      final json = result.toJson();
      final roundTrip = AuditAssertionVerificationResult.fromJson(json);
      expect(roundTrip.isValid, isTrue);
      expect(roundTrip.failureCode, VerificationFailureCode.none);
    });

    test('tampered payload fails verification with signature_invalid', () {
      final assertion = _buildAssertion();
      final tampered = assertion.copyWith(
        unsignedPayload: {
          ...assertion.unsignedPayload,
          'customerReference': 'tampered_customer',
        },
      );

      final result = _verifier.verify(tampered);

      expect(result.isValid, isFalse);
      expect(result.failureCode, VerificationFailureCode.signatureInvalid);
      expect(result.failureReason, contains('Signature verification failed'));
    });

    test('wrong secret fails verification', () {
      final assertion = _buildAssertion();
      final result = AuditAssertionVerifier(
        verifier: DemoHmacVerifier('wrong-secret'),
      ).verify(assertion);

      expect(result.isValid, isFalse);
      expect(result.failureCode, VerificationFailureCode.signatureInvalid);
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

      final result = _verifier.verify(
        assertion,
        challenge: challenge,
        now: DateTime.utc(2026, 8, 7, 12, 5),
      );

      expect(result.isValid, isFalse);
      expect(result.failureCode, VerificationFailureCode.challengeExpired);
      expect(result.failureReason, contains('expired'));
    });
  });

  group('tamper detection', () {
    test('top-level customerReference drift is detected after resign skip', () {
      // Signature still matches unsignedPayload, but top-level field differs.
      final assertion = _buildAssertion();
      final drifted = SignedAuditAssertion(
        assertionId: assertion.assertionId,
        intentId: assertion.intentId,
        operationId: assertion.operationId,
        operationType: assertion.operationType,
        institutionReference: assertion.institutionReference,
        customerReference: 'drifted_customer',
        operationTermsHash: assertion.operationTermsHash,
        challengeId: assertion.challengeId,
        serverNonceReference: assertion.serverNonceReference,
        authenticatorConfirmation: assertion.authenticatorConfirmation,
        createdAt: assertion.createdAt,
        signatureAlgorithm: assertion.signatureAlgorithm,
        signature: assertion.signature,
        unsignedPayload: assertion.unsignedPayload,
        schemaVersion: assertion.schemaVersion,
        assertionMetadata: assertion.assertionMetadata,
        statusFields: assertion.statusFields,
        privacy: assertion.privacy,
      );

      final result = _verifier.verify(drifted);
      expect(result.isValid, isFalse);
      expect(result.failureCode, VerificationFailureCode.payloadDrift);
      expect(result.failureReason, contains('customerReference'));
    });

    test('status field drift is detected', () {
      final assertion = _buildAssertion();
      final drifted = SignedAuditAssertion(
        assertionId: assertion.assertionId,
        intentId: assertion.intentId,
        operationId: assertion.operationId,
        operationType: assertion.operationType,
        institutionReference: assertion.institutionReference,
        customerReference: assertion.customerReference,
        operationTermsHash: assertion.operationTermsHash,
        challengeId: assertion.challengeId,
        serverNonceReference: assertion.serverNonceReference,
        authenticatorConfirmation: assertion.authenticatorConfirmation,
        createdAt: assertion.createdAt,
        signatureAlgorithm: assertion.signatureAlgorithm,
        signature: assertion.signature,
        unsignedPayload: assertion.unsignedPayload,
        schemaVersion: assertion.schemaVersion,
        assertionMetadata: assertion.assertionMetadata,
        statusFields: const AssertionStatusFields(
          identityProofing: 'tampered_claim',
        ),
        privacy: assertion.privacy,
      );

      final result = _verifier.verify(drifted);
      expect(result.isValid, isFalse);
      expect(result.failureCode, VerificationFailureCode.payloadDrift);
      expect(result.failureReason, contains('identityProofing'));
    });

    test('challenge nonce mismatch returns structured code', () {
      final assertion = _buildAssertion();
      final intent = _loanIntent();
      const hasher = OperationTermsHasher();
      final hash = hasher.sha256Canonical(intent.operationTerms);
      final otherChallenge = IntentChallengeBuilder().build(
        intent: intent,
        operationTermsHash: hash,
        serverNonce: 'nonce_OTHER',
        expiresIn: const Duration(minutes: 10),
        issuedAt: DateTime.utc(2026, 8, 7, 12, 1),
        challengeId: 'chal_1',
      );

      final result = _verifier.verify(
        assertion,
        challenge: otherChallenge,
        now: DateTime.utc(2026, 8, 7, 12, 2),
      );
      expect(result.isValid, isFalse);
      expect(
          result.failureCode, VerificationFailureCode.challengeNonceMismatch);
    });

    test('algorithm mismatch returns structured code', () {
      final assertion = _buildAssertion();
      final spoofed = SignedAuditAssertion(
        assertionId: assertion.assertionId,
        intentId: assertion.intentId,
        operationId: assertion.operationId,
        operationType: assertion.operationType,
        institutionReference: assertion.institutionReference,
        customerReference: assertion.customerReference,
        operationTermsHash: assertion.operationTermsHash,
        challengeId: assertion.challengeId,
        serverNonceReference: assertion.serverNonceReference,
        authenticatorConfirmation: assertion.authenticatorConfirmation,
        createdAt: assertion.createdAt,
        signatureAlgorithm: 'not_demo_hmac',
        signature: assertion.signature,
        unsignedPayload: assertion.unsignedPayload,
        schemaVersion: assertion.schemaVersion,
        assertionMetadata: assertion.assertionMetadata,
      );

      final result = _verifier.verify(spoofed);
      expect(result.isValid, isFalse);
      expect(result.failureCode, VerificationFailureCode.algorithmMismatch);
    });
  });
}
