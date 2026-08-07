/// Add-new-payee confirmation demo flow.
library;

import 'package:transaction_intent_signer/transaction_intent_signer.dart';

import '../support/demo_helpers.dart';

/// Runs an add-new-payee high-risk confirmation demo.
SignedAuditAssertion runAddNewPayeeFlow({DateTime? clock}) {
  final now = (clock ?? DateTime.now()).toUtc();

  final intent = TransactionIntent(
    intentId: 'intent_payee_001',
    operationId: 'payee_add_44',
    operationType: TransactionIntentType.addNewPayee,
    customerReference: 'customer_901',
    institutionReference: 'community_bank_demo',
    operationTerms: const {
      'payeeName': 'City Utilities',
      'accountNumberLast4': '4421',
      'routingNumberLast4': '0210',
      'payeeType': 'bill_pay',
      'nickname': 'Electric',
    },
    createdAt: now,
    metadata: const IntentMetadata(channel: 'mobile_app'),
  );

  final hash =
      const OperationTermsHasher().sha256Canonical(intent.operationTerms);
  final challenge = IntentChallengeBuilder().build(
    intent: intent,
    operationTermsHash: hash,
    serverNonce: 'srv_nonce_payee',
    expiresIn: const Duration(minutes: 8),
    issuedAt: now,
    challengeId: 'chal_payee_001',
  );

  return AuditAssertionBuilder(signer: demoSigner()).build(
    intent: intent,
    challenge: challenge,
    authenticatorConfirmation: AuthenticatorConfirmation.simulated(
      confirmedAt: now.add(const Duration(seconds: 14)),
    ),
    createdAt: now.add(const Duration(seconds: 20)),
    assertionId: 'assert_payee_001',
    assertionMetadata: const AssertionMetadata(
      producer: 'mobile_app',
      channel: 'mobile_app',
      correlationId: 'corr_payee_001',
      extra: {'flow': 'add_new_payee'},
    ),
  );
}

void main() {
  section('Add new payee demo flow');
  final now = DateTime.utc(2026, 8, 7, 19);
  final assertion = runAddNewPayeeFlow(clock: now);
  final challenge = IntentChallenge(
    challengeId: assertion.challengeId,
    intentId: assertion.intentId,
    operationId: assertion.operationId,
    operationType: assertion.operationType,
    operationTermsHash: assertion.operationTermsHash,
    serverNonce: assertion.serverNonceReference,
    issuedAt: now,
    expiresAt: now.add(const Duration(minutes: 8)),
    challengePayload: const {},
  );

  final result = AuditAssertionVerifier(verifier: demoVerifier()).verify(
    assertion,
    challenge: challenge,
    now: now.add(const Duration(minutes: 1)),
  );

  // ignore: avoid_print
  print('operationType: ${assertion.operationType}');
  // ignore: avoid_print
  print('verification: ${result.isValid} (${result.failureCode.wireName})');
  // ignore: avoid_print
  print(prettyJson(assertion.toJson(), options: PrettyJsonOptions.sharePanel));
}
