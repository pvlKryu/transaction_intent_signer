// ignore_for_file: avoid_print

/// Short cookbook snippets for common 1.0 workflows.
library;

import 'package:transaction_intent_signer/transaction_intent_signer.dart';

import 'support/demo_helpers.dart';

void main() {
  print('=== transaction_intent_signer 1.0 cookbook ===\n');

  final now = DateTime.now().toUtc();

  // 1) Intent + hash + challenge
  final intent = TransactionIntent(
    intentId: 'intent_cookbook',
    operationId: 'op_cookbook',
    operationType: TransactionIntentType.provideEConsent,
    customerReference: 'customer_cb',
    institutionReference: 'credit_union_demo',
    operationTerms: const {
      'documentId': 'econsent_v3',
      'documentHash': 'sha256:demo_doc_hash',
      'accepted': true,
    },
    createdAt: now,
  );
  final hash =
      const OperationTermsHasher().sha256Canonical(intent.operationTerms);
  final challenge = IntentChallengeBuilder().build(
    intent: intent,
    operationTermsHash: hash,
    serverNonce: 'srv_cookbook',
    expiresIn: const Duration(minutes: 10),
    issuedAt: now,
  );
  print('1) challengeId=${challenge.challengeId}');
  print('   termsHash=${hash.value}');

  // 2) Build assertion with metadata
  final assertion = AuditAssertionBuilder(signer: demoSigner()).build(
    intent: intent,
    challenge: challenge,
    authenticatorConfirmation: AuthenticatorConfirmation.simulated(
      confirmedAt: now,
    ),
    createdAt: now,
    assertionMetadata: const AssertionMetadata(
      producer: 'cookbook',
      channel: 'mobile_app',
      correlationId: 'corr_cookbook',
    ),
  );
  print('2) assertionId=${assertion.assertionId}');

  // 3) Verify with structured failure codes
  final result = AuditAssertionVerifier(verifier: demoVerifier()).verify(
    assertion,
    challenge: challenge,
    now: now,
  );
  print('3) valid=${result.isValid} code=${result.failureCode.wireName}');

  // 4) Share + dashboard helpers
  final share = const AssertionShareHelper().export(
    assertion,
    format: AssertionShareFormat.summaryText,
  );
  final dashboard = DemoDashboardSnapshot.fromAssertions(
    [assertion],
    verificationByAssertionId: {assertion.assertionId: result},
    generatedAt: now,
  );
  print(
      '4) shareChars=${share.length} dashboardTotal=${dashboard.summary.total}');

  // 5) Custom operation type via metadata
  final customIntent = TransactionIntent(
    intentId: 'intent_custom_cb',
    operationId: 'op_custom_cb',
    operationType: TransactionIntentType.custom,
    customerReference: 'customer_cb',
    institutionReference: 'cdfi_demo',
    operationTerms: const {'action': 'approve_exception', 'caseId': 'EX-9'},
    createdAt: now,
    metadata: const IntentMetadata(customOperationType: 'approve_exception'),
  );
  print('5) effectiveOperationType=${customIntent.effectiveOperationType}');

  print('\nCookbook complete.');
}
