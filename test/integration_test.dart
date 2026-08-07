import 'package:test/test.dart';
import 'package:transaction_intent_signer/transaction_intent_signer.dart';

void main() {
  const hasher = OperationTermsHasher();
  final challengeBuilder = IntentChallengeBuilder();
  final signer = DemoHmacSigner('integration-demo-secret');
  final verifier = AuditAssertionVerifier(
    verifier: DemoHmacVerifier('integration-demo-secret'),
  );

  test('full loan offer flow', () {
    final intent = TransactionIntent(
      intentId: 'intent_loan_1',
      operationId: 'loan_offer_1',
      operationType: TransactionIntentType.confirmLoanOffer,
      customerReference: 'customer_1',
      institutionReference: 'credit_union_demo',
      operationTerms: const {
        'loanAmount': 15000,
        'currency': 'USD',
        'apr': 12.5,
        'termMonths': 36,
        'monthlyPayment': 501.23,
      },
      createdAt: DateTime.utc(2026, 8, 7, 10),
    );

    final hash = hasher.sha256Canonical(intent.operationTerms);
    final challenge = challengeBuilder.build(
      intent: intent,
      operationTermsHash: hash,
      serverNonce: 'nonce_loan',
      expiresIn: const Duration(minutes: 15),
      issuedAt: DateTime.utc(2026, 8, 7, 10, 1),
    );
    final assertion = AuditAssertionBuilder(signer: signer).build(
      intent: intent,
      challenge: challenge,
      authenticatorConfirmation: AuthenticatorConfirmation.simulated(
        confirmedAt: DateTime.utc(2026, 8, 7, 10, 2),
      ),
      livenessInteractionSummary: const LivenessInteractionSummary(
        facePresent: true,
        singleFace: true,
        challengeCompleted: true,
      ),
      createdAt: DateTime.utc(2026, 8, 7, 10, 2),
    );

    final result = verifier.verify(
      assertion,
      challenge: challenge,
      now: DateTime.utc(2026, 8, 7, 10, 3),
    );
    expect(result.isValid, isTrue, reason: result.failureReason);
    expect(assertion.operationType, 'confirm_loan_offer');
  });

  test('full large transfer flow', () {
    final intent = TransactionIntent(
      intentId: 'intent_xfer_1',
      operationId: 'transfer_1',
      operationType: TransactionIntentType.authorizeLargeTransfer,
      customerReference: 'customer_2',
      institutionReference: 'community_bank_demo',
      operationTerms: const {
        'amount': 25000,
        'currency': 'USD',
        'fromAccount': 'checking_1001',
        'toAccount': 'external_9988',
        'recipientName': 'Vendor LLC',
      },
      createdAt: DateTime.utc(2026, 8, 7, 11),
    );

    final hash = hasher.sha256Canonical(intent.operationTerms);
    final challenge = challengeBuilder.build(
      intent: intent,
      operationTermsHash: hash,
      serverNonce: 'nonce_xfer',
      expiresIn: const Duration(minutes: 5),
      issuedAt: DateTime.utc(2026, 8, 7, 11, 1),
    );
    final assertion = AuditAssertionBuilder(signer: signer).build(
      intent: intent,
      challenge: challenge,
      authenticatorConfirmation: AuthenticatorConfirmation.simulated(
        confirmedAt: DateTime.utc(2026, 8, 7, 11, 2),
      ),
      createdAt: DateTime.utc(2026, 8, 7, 11, 2),
    );

    expect(
      verifier
          .verify(
            assertion,
            challenge: challenge,
            now: DateTime.utc(2026, 8, 7, 11, 3),
          )
          .isValid,
      isTrue,
    );
    expect(assertion.operationType, 'authorize_large_transfer');
  });

  test('full custom intent flow', () {
    final intent = TransactionIntent(
      intentId: 'intent_custom_1',
      operationId: 'op_custom_1',
      operationType: TransactionIntentType.custom,
      customerReference: 'customer_3',
      institutionReference: 'cdfi_demo',
      operationTerms: const {
        'action': 'unlock_wire_template',
        'templateId': 'wire_42',
      },
      createdAt: DateTime.utc(2026, 8, 7, 12),
      metadata: const IntentMetadata(
        customOperationType: 'unlock_wire_template',
        channel: 'mobile_app',
      ),
    );

    expect(intent.effectiveOperationType, 'unlock_wire_template');

    final hash = hasher.sha256Canonical(intent.operationTerms);
    final challenge = challengeBuilder.build(
      intent: intent,
      operationTermsHash: hash,
      serverNonce: 'nonce_custom',
      expiresIn: const Duration(minutes: 8),
      issuedAt: DateTime.utc(2026, 8, 7, 12, 1),
    );
    final assertion = AuditAssertionBuilder(signer: signer).build(
      intent: intent,
      challenge: challenge,
      authenticatorConfirmation: AuthenticatorConfirmation.simulated(
        confirmedAt: DateTime.utc(2026, 8, 7, 12, 2),
      ),
      createdAt: DateTime.utc(2026, 8, 7, 12, 2),
    );

    expect(assertion.operationType, 'unlock_wire_template');
    expect(
      verifier
          .verify(
            assertion,
            challenge: challenge,
            now: DateTime.utc(2026, 8, 7, 12, 3),
          )
          .isValid,
      isTrue,
    );
  });
}
