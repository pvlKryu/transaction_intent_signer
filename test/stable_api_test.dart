import 'package:test/test.dart';
import 'package:transaction_intent_signer/transaction_intent_signer.dart';

void main() {
  test('add new payee flow produces verifiable assertion', () {
    final now = DateTime.utc(2026, 8, 7, 19);
    final intent = TransactionIntent(
      intentId: 'intent_payee',
      operationId: 'payee_1',
      operationType: TransactionIntentType.addNewPayee,
      customerReference: 'c1',
      institutionReference: 'bank',
      operationTerms: const {
        'payeeName': 'City Utilities',
        'accountNumberLast4': '4421',
      },
      createdAt: now,
    );
    final hash =
        const OperationTermsHasher().sha256Canonical(intent.operationTerms);
    final challenge = IntentChallengeBuilder().build(
      intent: intent,
      operationTermsHash: hash,
      serverNonce: 'n',
      expiresIn: const Duration(minutes: 8),
      issuedAt: now,
    );
    final assertion = AuditAssertionBuilder(
      signer: DemoHmacSigner('payee-secret'),
    ).build(
      intent: intent,
      challenge: challenge,
      authenticatorConfirmation:
          AuthenticatorConfirmation.simulated(confirmedAt: now),
      createdAt: now,
      assertionMetadata: const AssertionMetadata(
        extra: {'flow': 'add_new_payee'},
      ),
    );

    expect(assertion.operationType, 'add_new_payee');
    expect(
      AuditAssertionVerifier(verifier: DemoHmacVerifier('payee-secret'))
          .verify(assertion, challenge: challenge, now: now)
          .isValid,
      isTrue,
    );
  });

  test('package reports 1.0.0 stable version constants', () {
    expect(TransactionIntentSignerInfo.packageVersion, '1.0.0');
    expect(
      TransactionIntentSignerInfo.assertionSchemaVersion,
      'tis_assertion_v1',
    );
  });
}
