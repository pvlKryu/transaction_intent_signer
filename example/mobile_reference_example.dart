// ignore_for_file: avoid_print

import 'package:transaction_intent_signer/transaction_intent_signer.dart';

import 'support/demo_helpers.dart';

/// Demonstrates 0.4.0 mobile reference helpers (pure Dart, Flutter-free).
void main() {
  section('Mobile reference helpers');

  final now = DateTime.utc(2026, 8, 7, 20);
  final intent = TransactionIntent(
    intentId: 'intent_mobile_ref',
    operationId: 'loan_offer_mobile',
    operationType: TransactionIntentType.confirmLoanOffer,
    customerReference: 'customer_mobile',
    institutionReference: 'community_bank_demo',
    operationTerms: const {
      'loanAmount': 12000,
      'currency': 'USD',
      'apr': 11.9,
      'termMonths': 24,
    },
    createdAt: now,
  );

  var session = DemoConfirmationSession.draft(
    sessionId: 'sess_mobile_1',
    intent: intent,
    flowLabel: 'remote_lending',
    updatedAt: now,
  );

  final hash =
      const OperationTermsHasher().sha256Canonical(intent.operationTerms);
  final challenge = IntentChallengeBuilder().build(
    intent: intent,
    operationTermsHash: hash,
    serverNonce: 'srv_mobile',
    expiresIn: const Duration(minutes: 10),
    issuedAt: now,
    challengeId: 'chal_mobile',
  );
  session = session.withChallenge(
    operationTermsHash: hash,
    challenge: challenge,
    updatedAt: now,
  );

  final confirmation = AuthenticatorConfirmation.simulated(confirmedAt: now);
  final liveness = LivenessSummaryMapper.fromFlutterLivenessActionsLike(
    faceDetected: true,
    faceCount: 1,
    challengePassed: true,
    actionType: 'blink',
  );
  session = session.withConfirmation(
    authenticatorConfirmation: confirmation,
    livenessInteractionSummary: liveness,
    updatedAt: now,
  );

  final assertion = AuditAssertionBuilder(signer: demoSigner()).build(
    intent: intent,
    challenge: challenge,
    authenticatorConfirmation: confirmation,
    livenessInteractionSummary: liveness,
    createdAt: now,
    assertionId: 'assert_mobile',
    assertionMetadata: const AssertionMetadata(
      producer: 'mobile_app',
      channel: 'mobile_app',
      correlationId: 'corr_mobile',
      extra: {'flow': 'remote_lending'},
    ),
  );
  session = session.withAssertion(assertion, updatedAt: now);

  final verification = AuditAssertionVerifier(verifier: demoVerifier()).verify(
    assertion,
    challenge: challenge,
    now: now,
  );
  session = session.withVerification(verification, updatedAt: now);

  print('session phase: ${session.phase.wireName}');
  print(
      'session json:\n${prettyJson(session.toJson(), options: PrettyJsonOptions.sharePanel)}');

  section('Share payloads');
  const shareHelper = AssertionShareHelper();
  for (final payload in shareHelper.exportAll(assertion)) {
    print('- ${payload.label}: ${payload.format.wireName} '
        '(${payload.length} chars, ${payload.mimeType})');
  }
  print('\nSummary text:\n${shareHelper.summarize(assertion)}');

  section('Demo dashboard snapshot');
  final snapshot = DemoDashboardSnapshot.fromAssertions(
    [assertion],
    verificationByAssertionId: {assertion.assertionId: verification},
    generatedAt: now,
  );
  print(prettyJson(snapshot.toJson(), options: PrettyJsonOptions.sharePanel));
}
