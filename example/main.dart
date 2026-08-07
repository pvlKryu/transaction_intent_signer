// ignore_for_file: avoid_print

import 'package:transaction_intent_signer/transaction_intent_signer.dart';

import 'backend_validator_example.dart';
import 'flows/large_transfer_flow.dart';
import 'flows/remote_lending_flow.dart';
import 'flows/security_settings_flow.dart';
import 'liveness_mapping_example.dart';
import 'support/demo_helpers.dart';

/// Runs the 0.3.0 integration example suite.
void main() {
  print('=== transaction_intent_signer 0.3.0 integration examples ===');

  // 1) Liveness mapping
  section('1) flutter_liveness_actions mapping');
  const event = SampleFlutterLivenessAuditEvent(
    faceDetected: true,
    faceCount: 1,
    challengePassed: true,
    actionType: 'turn_head_left',
    sessionDurationMs: 4200,
    avgFrameProcessingMs: 38.4,
    actionsCompleted: ['blink', 'turn_head_left'],
    sdkVersion: 'illustrative-1.0.0',
  );
  final summary = mapFlutterLivenessActionsEvent(event);
  print(prettyJson(summary.toJson()));

  // 2) Remote lending
  section('2) Remote lending flow');
  final lendingNow = DateTime.utc(2026, 8, 7, 16);
  final lending = runRemoteLendingFlow(clock: lendingNow);
  print('assertionId=${lending.assertionId} type=${lending.operationType}');

  // 3) Large transfer
  section('3) Large transfer flow');
  final xfer = runLargeTransferFlow(clock: DateTime.utc(2026, 8, 7, 17));
  print('assertionId=${xfer.assertionId} type=${xfer.operationType}');

  // 4) Security settings
  section('4) Security settings flow');
  final security = runSecuritySettingsFlow(clock: DateTime.utc(2026, 8, 7, 18));
  print('assertionId=${security.assertionId} type=${security.operationType}');

  // 5) Backend validator against lending assertion
  section('5) Backend validator');
  final store = MockChallengeStore();
  const terms = <String, Object?>{
    'loanAmount': 15000,
    'currency': 'USD',
    'apr': 12.5,
    'termMonths': 36,
    'monthlyPayment': 501.23,
    'productCode': 'PERSONAL_INSTALLMENT',
    'eConsentTextHash': 'sha256:demo_consent_hash',
  };

  // Rebuild challenge binding from assertion fields for the demo store.
  final challenge = IntentChallenge(
    challengeId: lending.challengeId,
    intentId: lending.intentId,
    operationId: lending.operationId,
    operationType: lending.operationType,
    operationTermsHash: lending.operationTermsHash,
    serverNonce: lending.serverNonceReference,
    issuedAt: lendingNow,
    expiresAt: lendingNow.add(const Duration(minutes: 10)),
    challengePayload: const {},
  );
  store.save(challenge);

  final validator = BackendAssertionValidator(
    challengeStore: store,
    assertionVerifier: AuditAssertionVerifier(verifier: demoVerifier()),
  );
  final validation = validator.validate(
    assertion: lending,
    authoritativeOperationTerms: terms,
    now: lendingNow.add(const Duration(minutes: 1)),
  );
  print(prettyJson(validation.toJson()));

  // 6) Compact envelope snapshot
  section('6) Compact envelope');
  final compact = const CompactAssertionEnvelope().encode(lending);
  print('segments=${compact.split('.').length}');

  print('\nAll integration examples completed.');
}
