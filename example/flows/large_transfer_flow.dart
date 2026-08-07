/// Large transfer confirmation demo flow.
library;

import 'package:transaction_intent_signer/transaction_intent_signer.dart';

import '../support/demo_helpers.dart';

/// Runs a large transfer authorization demo.
SignedAuditAssertion runLargeTransferFlow({DateTime? clock}) {
  final now = (clock ?? DateTime.now()).toUtc();

  final intent = TransactionIntent(
    intentId: 'intent_xfer_001',
    operationId: 'transfer_551',
    operationType: TransactionIntentType.authorizeLargeTransfer,
    customerReference: 'customer_789',
    institutionReference: 'community_bank_demo',
    operationTerms: const {
      'amount': 25000,
      'currency': 'USD',
      'fromAccount': 'checking_1001',
      'toAccount': 'external_9988',
      'recipientName': 'Vendor LLC',
      'memo': 'Invoice 4421',
    },
    createdAt: now,
    metadata: const IntentMetadata(channel: 'mobile_app'),
  );

  final hash =
      const OperationTermsHasher().sha256Canonical(intent.operationTerms);
  final challenge = IntentChallengeBuilder().build(
    intent: intent,
    operationTermsHash: hash,
    serverNonce: 'srv_nonce_xfer',
    expiresIn: const Duration(minutes: 5),
    issuedAt: now,
    challengeId: 'chal_xfer_001',
  );

  return AuditAssertionBuilder(signer: demoSigner()).build(
    intent: intent,
    challenge: challenge,
    authenticatorConfirmation: AuthenticatorConfirmation.simulated(
      confirmedAt: now.add(const Duration(seconds: 15)),
    ),
    createdAt: now.add(const Duration(seconds: 20)),
    assertionId: 'assert_xfer_001',
    assertionMetadata: const AssertionMetadata(
      producer: 'mobile_app',
      channel: 'mobile_app',
      correlationId: 'corr_xfer_001',
      extra: {'flow': 'large_transfer'},
    ),
  );
}

void main() {
  section('Large transfer demo flow');
  final now = DateTime.utc(2026, 8, 7, 17);
  final assertion = runLargeTransferFlow(clock: now);
  final challenge = IntentChallenge(
    challengeId: assertion.challengeId,
    intentId: assertion.intentId,
    operationId: assertion.operationId,
    operationType: assertion.operationType,
    operationTermsHash: assertion.operationTermsHash,
    serverNonce: assertion.serverNonceReference,
    issuedAt: now,
    expiresAt: now.add(const Duration(minutes: 5)),
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
  print(prettyJson(assertion.toJson()));
}
