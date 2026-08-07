/// Remote lending confirmation demo flow.
library;

import 'package:transaction_intent_signer/transaction_intent_signer.dart';

import '../liveness_mapping_example.dart';
import '../support/demo_helpers.dart';

/// Runs a remote lending loan-offer confirmation demo.
SignedAuditAssertion runRemoteLendingFlow({DateTime? clock}) {
  final now = (clock ?? DateTime.now()).toUtc();

  final intent = TransactionIntent(
    intentId: 'intent_lending_001',
    operationId: 'loan_offer_789',
    operationType: TransactionIntentType.confirmLoanOffer,
    customerReference: 'customer_456',
    institutionReference: 'credit_union_demo',
    operationTerms: const {
      'loanAmount': 15000,
      'currency': 'USD',
      'apr': 12.5,
      'termMonths': 36,
      'monthlyPayment': 501.23,
      'productCode': 'PERSONAL_INSTALLMENT',
      'eConsentTextHash': 'sha256:demo_consent_hash',
    },
    createdAt: now,
    expiresAt: now.add(const Duration(hours: 1)),
    metadata: const IntentMetadata(channel: 'mobile_app'),
  );

  final hash =
      const OperationTermsHasher().sha256Canonical(intent.operationTerms);
  final challenge = IntentChallengeBuilder().build(
    intent: intent,
    operationTermsHash: hash,
    serverNonce: 'srv_nonce_lending',
    expiresIn: const Duration(minutes: 10),
    issuedAt: now,
    challengeId: 'chal_lending_001',
  );

  final liveness = mapFlutterLivenessActionsEvent(
    const SampleFlutterLivenessAuditEvent(
      faceDetected: true,
      faceCount: 1,
      challengePassed: true,
      actionType: 'smile',
      sessionDurationMs: 3900,
      avgFrameProcessingMs: 41,
      actionsCompleted: ['smile'],
      sdkVersion: 'illustrative-1.0.0',
    ),
  );

  return AuditAssertionBuilder(signer: demoSigner()).build(
    intent: intent,
    challenge: challenge,
    authenticatorConfirmation: AuthenticatorConfirmation.simulated(
      confirmedAt: now.add(const Duration(seconds: 25)),
    ),
    livenessInteractionSummary: liveness,
    createdAt: now.add(const Duration(seconds: 40)),
    assertionId: 'assert_lending_001',
    assertionMetadata: const AssertionMetadata(
      producer: 'mobile_app',
      channel: 'mobile_app',
      correlationId: 'corr_lending_001',
      extra: {'flow': 'remote_lending'},
    ),
  );
}

void main() {
  section('Remote lending demo flow');
  final now = DateTime.utc(2026, 8, 7, 16);
  final assertion = runRemoteLendingFlow(clock: now);
  final challenge = IntentChallenge(
    challengeId: assertion.challengeId,
    intentId: assertion.intentId,
    operationId: assertion.operationId,
    operationType: assertion.operationType,
    operationTermsHash: assertion.operationTermsHash,
    serverNonce: assertion.serverNonceReference,
    issuedAt: now,
    expiresAt: now.add(const Duration(minutes: 10)),
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
