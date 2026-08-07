/// Example backend validator for signed audit assertions.
///
/// Demonstrates institution-side checks a Dart backend might run after a
/// mobile confirmation. This is reference code only — production systems must
/// use secure key management and their own WebAuthn / risk controls.
library;

import 'package:transaction_intent_signer/transaction_intent_signer.dart';

import 'support/demo_helpers.dart';

/// Result of a backend-side validation pass.
class BackendValidationResult {
  /// Creates a [BackendValidationResult].
  const BackendValidationResult({
    required this.accepted,
    required this.verifiedAt,
    this.failureReason,
    this.assertionVerification,
    this.authoritativeTermsMatch,
  });

  /// Whether the backend would accept the confirmation artifact.
  final bool accepted;

  /// Human-readable failure reason when not accepted.
  final String? failureReason;

  /// Package-level assertion verification result, if run.
  final AuditAssertionVerificationResult? assertionVerification;

  /// Whether recomputed authoritative terms matched the assertion hash.
  final bool? authoritativeTermsMatch;

  /// UTC timestamp for this validation.
  final DateTime verifiedAt;

  /// Serializes to JSON for audit logging demos.
  Map<String, Object?> toJson() => {
        'accepted': accepted,
        if (failureReason != null) 'failureReason': failureReason,
        if (assertionVerification != null)
          'assertionVerification': assertionVerification!.toJson(),
        if (authoritativeTermsMatch != null)
          'authoritativeTermsMatch': authoritativeTermsMatch,
        'verifiedAt': verifiedAt.toUtc().toIso8601String(),
      };
}

/// Reference backend validator.
///
/// Steps:
/// 1. Load challenge by id from a store
/// 2. Optionally re-hash authoritative operation terms and compare
/// 3. Verify the [SignedAuditAssertion] signature + challenge binding
///
/// WebAuthn cryptographic verification remains outside this package.
class BackendAssertionValidator {
  /// Creates a [BackendAssertionValidator].
  BackendAssertionValidator({
    required this.challengeStore,
    required this.assertionVerifier,
    this.termsHasher = const OperationTermsHasher(),
  });

  /// Lookup for previously issued challenges.
  final MockChallengeStore challengeStore;

  /// Package assertion verifier.
  final AuditAssertionVerifier assertionVerifier;

  /// Hasher used to recompute authoritative terms.
  final OperationTermsHasher termsHasher;

  /// Validates an inbound assertion against store + authoritative terms.
  BackendValidationResult validate({
    required SignedAuditAssertion assertion,
    Map<String, Object?>? authoritativeOperationTerms,
    DateTime? now,
  }) {
    final verifiedAt = (now ?? DateTime.now()).toUtc();

    final challenge = challengeStore.get(assertion.challengeId);
    if (challenge == null) {
      return BackendValidationResult(
        accepted: false,
        failureReason: 'Unknown challengeId: ${assertion.challengeId}',
        verifiedAt: verifiedAt,
      );
    }

    bool? termsMatch;
    if (authoritativeOperationTerms != null) {
      final expected =
          termsHasher.sha256Canonical(authoritativeOperationTerms).value;
      termsMatch = expected == assertion.operationTermsHash.value;
      if (!termsMatch) {
        return BackendValidationResult(
          accepted: false,
          failureReason:
              'Authoritative operation terms hash does not match assertion.',
          authoritativeTermsMatch: false,
          verifiedAt: verifiedAt,
        );
      }
    }

    final assertionResult = assertionVerifier.verify(
      assertion,
      challenge: challenge,
      now: verifiedAt,
    );

    if (!assertionResult.isValid) {
      return BackendValidationResult(
        accepted: false,
        failureReason: assertionResult.failureReason,
        assertionVerification: assertionResult,
        authoritativeTermsMatch: termsMatch,
        verifiedAt: verifiedAt,
      );
    }

    return BackendValidationResult(
      accepted: true,
      assertionVerification: assertionResult,
      authoritativeTermsMatch: termsMatch,
      verifiedAt: verifiedAt,
    );
  }
}

/// Builds a sample loan assertion and runs backend validation demos.
void main() {
  section('Backend validator example');

  final now = DateTime.utc(2026, 8, 7, 15, 0);
  final store = MockChallengeStore();
  final terms = <String, Object?>{
    'loanAmount': 15000,
    'currency': 'USD',
    'apr': 12.5,
    'termMonths': 36,
  };

  final intent = TransactionIntent(
    intentId: 'intent_backend_1',
    operationId: 'loan_offer_backend_1',
    operationType: TransactionIntentType.confirmLoanOffer,
    customerReference: 'customer_backend',
    institutionReference: 'community_bank_demo',
    operationTerms: terms,
    createdAt: now,
  );

  final hash = const OperationTermsHasher().sha256Canonical(terms);
  final challenge = IntentChallengeBuilder().build(
    intent: intent,
    operationTermsHash: hash,
    serverNonce: 'srv_nonce_backend',
    expiresIn: const Duration(minutes: 10),
    issuedAt: now,
    challengeId: 'chal_backend_1',
  );
  store.save(challenge);

  final assertion = AuditAssertionBuilder(signer: demoSigner()).build(
    intent: intent,
    challenge: challenge,
    authenticatorConfirmation: AuthenticatorConfirmation.simulated(
      confirmedAt: now.add(const Duration(seconds: 20)),
    ),
    createdAt: now.add(const Duration(seconds: 30)),
    assertionId: 'assert_backend_1',
    assertionMetadata: const AssertionMetadata(
      producer: 'mobile_app',
      channel: 'mobile_app',
      correlationId: 'corr_backend_1',
    ),
  );

  final validator = BackendAssertionValidator(
    challengeStore: store,
    assertionVerifier: AuditAssertionVerifier(verifier: demoVerifier()),
  );

  final ok = validator.validate(
    assertion: assertion,
    authoritativeOperationTerms: terms,
    now: now.add(const Duration(minutes: 1)),
  );
  // ignore: avoid_print
  print('Accepted (happy path): ${ok.accepted}');
  // ignore: avoid_print
  print(prettyJson(ok.toJson()));

  final tamperedTerms = <String, Object?>{...terms, 'loanAmount': 16000};
  final termsMismatch = validator.validate(
    assertion: assertion,
    authoritativeOperationTerms: tamperedTerms,
    now: now.add(const Duration(minutes: 1)),
  );
  // ignore: avoid_print
  print('\nAccepted (terms mismatch): ${termsMismatch.accepted}');
  // ignore: avoid_print
  print(termsMismatch.failureReason);

  final expired = validator.validate(
    assertion: assertion,
    authoritativeOperationTerms: terms,
    now: now.add(const Duration(minutes: 30)),
  );
  // ignore: avoid_print
  print('\nAccepted (expired challenge): ${expired.accepted}');
  // ignore: avoid_print
  print(expired.failureReason);
}
