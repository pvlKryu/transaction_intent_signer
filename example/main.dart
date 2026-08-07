// ignore_for_file: avoid_print

import 'package:transaction_intent_signer/transaction_intent_signer.dart';

void main() {
  print('=== transaction_intent_signer demo ===\n');

  final now = DateTime.now().toUtc();

  // 1) Create a loan offer intent
  final intent = TransactionIntent(
    intentId: 'intent_loan_demo_001',
    operationId: 'loan_offer_789',
    operationType: TransactionIntentType.confirmLoanOffer,
    customerReference: 'customer_456',
    institutionReference: 'community_bank_demo',
    operationTerms: const {
      'loanAmount': 15000,
      'currency': 'USD',
      'apr': 12.5,
      'termMonths': 36,
      'monthlyPayment': 501.23,
    },
    createdAt: now,
    expiresAt: now.add(const Duration(hours: 1)),
    metadata: const IntentMetadata(channel: 'mobile_app'),
  );

  // 2) Hash operation terms
  const hasher = OperationTermsHasher(includeCanonicalPayload: true);
  final termsHash = hasher.sha256Canonical(intent.operationTerms);
  print('Operation terms hash: ${termsHash.value}');
  print('Canonical payload: ${termsHash.canonicalPayload}\n');

  // 3) Build challenge bound to server nonce
  final challenge = IntentChallengeBuilder().build(
    intent: intent,
    operationTermsHash: termsHash,
    serverNonce: 'srv_nonce_demo_9f3a',
    expiresIn: const Duration(minutes: 10),
    issuedAt: now,
    challengeId: 'chal_demo_001',
  );
  print('Challenge id: ${challenge.challengeId}');
  print('Challenge payload:\n${prettyJson(challenge.challengePayload)}\n');

  // 4) Simulated passkey confirmation
  final confirmation = AuthenticatorConfirmation.simulated(
    confirmedAt: now.add(const Duration(seconds: 30)),
    credentialReference: 'sim_cred_loan_demo',
  );

  // 5) Optional liveness-aware summary from host app
  const liveness = LivenessInteractionSummary(
    facePresent: true,
    singleFace: true,
    challengeCompleted: true,
    challengeType: 'turn_head_left',
    durationMs: 4200,
    averageProcessingMs: 38,
  );

  // 6) Build signed audit assertion
  final signer = DemoHmacSigner('demo-only-secret-do-not-use-in-prod');
  final assertion = AuditAssertionBuilder(signer: signer).build(
    intent: intent,
    challenge: challenge,
    authenticatorConfirmation: confirmation,
    livenessInteractionSummary: liveness,
    createdAt: now.add(const Duration(seconds: 45)),
    assertionId: 'assert_demo_001',
  );

  print('Signed audit assertion:\n${prettyJson(assertion.toJson())}\n');

  // 7) Verify assertion
  final verifier = AuditAssertionVerifier(
    verifier: DemoHmacVerifier('demo-only-secret-do-not-use-in-prod'),
  );
  final ok = verifier.verify(assertion, challenge: challenge, now: now);
  print('Verification valid: ${ok.isValid}');

  // 8) Demonstrate tampering detection
  final tampered = assertion.copyWith(
    unsignedPayload: {
      ...assertion.unsignedPayload,
      'operationTermsHash': 'sha256:tampered',
    },
  );
  final bad = verifier.verify(tampered, challenge: challenge, now: now);
  print('Tampered verification valid: ${bad.isValid}');
  print('Tampered failure reason: ${bad.failureReason}');
}
