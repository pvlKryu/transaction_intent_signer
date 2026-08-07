/// Security settings change confirmation demo flow.
library;

import 'package:transaction_intent_signer/transaction_intent_signer.dart';

import '../support/demo_helpers.dart';

/// Runs a security-settings change confirmation demo.
///
/// Covers a high-risk mobile banking action such as updating recovery phone
/// and MFA preferences in one confirmation session.
SignedAuditAssertion runSecuritySettingsFlow({DateTime? clock}) {
  final now = (clock ?? DateTime.now()).toUtc();

  final intent = TransactionIntent(
    intentId: 'intent_sec_001',
    operationId: 'security_change_220',
    operationType: TransactionIntentType.changeSecuritySettings,
    customerReference: 'customer_321',
    institutionReference: 'cdfi_demo',
    operationTerms: const {
      'settings': {
        'recoveryPhone': '+1-555-0102',
        'mfaMethod': 'platform_passkey',
        'loginAlertsEnabled': true,
      },
      'previousRecoveryPhoneHash': 'sha256:demo_prev_phone_hash',
      'changeReason': 'customer_requested_update',
    },
    createdAt: now,
    metadata: const IntentMetadata(
      channel: 'mobile_app',
      sessionReference: 'sess_sec_001',
    ),
  );

  final hash =
      const OperationTermsHasher().sha256Canonical(intent.operationTerms);
  final challenge = IntentChallengeBuilder().build(
    intent: intent,
    operationTermsHash: hash,
    serverNonce: 'srv_nonce_sec',
    expiresIn: const Duration(minutes: 8),
    issuedAt: now,
    challengeId: 'chal_sec_001',
  );

  return AuditAssertionBuilder(signer: demoSigner()).build(
    intent: intent,
    challenge: challenge,
    authenticatorConfirmation: AuthenticatorConfirmation.simulated(
      confirmedAt: now.add(const Duration(seconds: 18)),
      credentialReference: 'sim_cred_sec_001',
    ),
    createdAt: now.add(const Duration(seconds: 25)),
    assertionId: 'assert_sec_001',
    assertionMetadata: const AssertionMetadata(
      producer: 'mobile_app',
      channel: 'mobile_app',
      correlationId: 'corr_sec_001',
      extra: {'flow': 'security_settings'},
    ),
  );
}

/// Companion demo for recovery-phone-only change using the dedicated type.
SignedAuditAssertion runRecoveryPhoneFlow({DateTime? clock}) {
  final now = (clock ?? DateTime.now()).toUtc();

  final intent = TransactionIntent(
    intentId: 'intent_phone_001',
    operationId: 'recovery_phone_88',
    operationType: TransactionIntentType.changeRecoveryPhone,
    customerReference: 'customer_321',
    institutionReference: 'cdfi_demo',
    operationTerms: const {
      'newRecoveryPhone': '+1-555-0199',
      'previousRecoveryPhoneHash': 'sha256:demo_prev_phone_hash',
    },
    createdAt: now,
  );

  final hash =
      const OperationTermsHasher().sha256Canonical(intent.operationTerms);
  final challenge = IntentChallengeBuilder().build(
    intent: intent,
    operationTermsHash: hash,
    serverNonce: 'srv_nonce_phone',
    expiresIn: const Duration(minutes: 8),
    issuedAt: now,
    challengeId: 'chal_phone_001',
  );

  return AuditAssertionBuilder(signer: demoSigner()).build(
    intent: intent,
    challenge: challenge,
    authenticatorConfirmation: AuthenticatorConfirmation.simulated(
      confirmedAt: now.add(const Duration(seconds: 12)),
    ),
    createdAt: now.add(const Duration(seconds: 15)),
    assertionId: 'assert_phone_001',
    assertionMetadata: const AssertionMetadata(
      producer: 'mobile_app',
      correlationId: 'corr_phone_001',
      extra: {'flow': 'change_recovery_phone'},
    ),
  );
}

void main() {
  section('Security settings demo flow');
  final now = DateTime.utc(2026, 8, 7, 18);
  final assertion = runSecuritySettingsFlow(clock: now);
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
  print(prettyJson(assertion.toJson()));

  section('Recovery phone companion flow');
  final phone = runRecoveryPhoneFlow(clock: now);
  // ignore: avoid_print
  print('operationType: ${phone.operationType}');
  // ignore: avoid_print
  print('terms hash: ${phone.operationTermsHash.value}');
}
