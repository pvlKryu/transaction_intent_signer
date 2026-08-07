import 'package:test/test.dart';
import 'package:transaction_intent_signer/transaction_intent_signer.dart';

SignedAuditAssertion _assertion() {
  final now = DateTime.utc(2026, 8, 7, 20);
  final intent = TransactionIntent(
    intentId: 'intent_demo',
    operationId: 'op_demo',
    operationType: TransactionIntentType.confirmLoanOffer,
    customerReference: 'customer_1',
    institutionReference: 'bank_demo',
    operationTerms: const {'loanAmount': 1000, 'currency': 'USD'},
    createdAt: now,
  );
  final hash =
      const OperationTermsHasher().sha256Canonical(intent.operationTerms);
  final challenge = IntentChallengeBuilder().build(
    intent: intent,
    operationTermsHash: hash,
    serverNonce: 'nonce_demo',
    expiresIn: const Duration(minutes: 10),
    issuedAt: now,
    challengeId: 'chal_demo',
  );
  return AuditAssertionBuilder(signer: DemoHmacSigner('demo')).build(
    intent: intent,
    challenge: challenge,
    authenticatorConfirmation:
        AuthenticatorConfirmation.simulated(confirmedAt: now),
    livenessInteractionSummary: const LivenessInteractionSummary(
      facePresent: true,
      singleFace: true,
      challengeCompleted: true,
    ),
    createdAt: now,
    assertionId: 'assert_demo',
    assertionMetadata: const AssertionMetadata(
      channel: 'mobile_app',
      correlationId: 'corr_demo',
      extra: {'flow': 'remote_lending'},
    ),
  );
}

void main() {
  group('DemoConfirmationSession', () {
    test('advances through demo phases', () {
      final now = DateTime.utc(2026, 8, 7, 20);
      final intent = TransactionIntent(
        intentId: 'intent_1',
        operationId: 'op_1',
        operationType: TransactionIntentType.authorizeLargeTransfer,
        customerReference: 'c1',
        institutionReference: 'bank',
        operationTerms: const {'amount': 1, 'currency': 'USD'},
        createdAt: now,
      );

      var session = DemoConfirmationSession.draft(
        sessionId: 'sess_1',
        intent: intent,
        flowLabel: 'large_transfer',
        updatedAt: now,
      );
      expect(session.phase, DemoSessionPhase.draft);

      final hash =
          const OperationTermsHasher().sha256Canonical(intent.operationTerms);
      final challenge = IntentChallengeBuilder().build(
        intent: intent,
        operationTermsHash: hash,
        serverNonce: 'n',
        expiresIn: const Duration(minutes: 5),
        issuedAt: now,
      );
      session = session.withChallenge(
        operationTermsHash: hash,
        challenge: challenge,
        updatedAt: now,
      );
      expect(session.phase, DemoSessionPhase.challenged);

      session = session.withConfirmation(
        authenticatorConfirmation:
            AuthenticatorConfirmation.simulated(confirmedAt: now),
        updatedAt: now,
      );
      expect(session.phase, DemoSessionPhase.confirmed);

      final assertion =
          AuditAssertionBuilder(signer: DemoHmacSigner('demo')).build(
        intent: intent,
        challenge: challenge,
        authenticatorConfirmation: session.authenticatorConfirmation!,
        createdAt: now,
        assertionId: 'a1',
      );
      session = session.withAssertion(assertion, updatedAt: now);
      expect(session.phase, DemoSessionPhase.asserted);

      final result = AuditAssertionVerifier(
        verifier: DemoHmacVerifier('demo'),
      ).verify(assertion, challenge: challenge, now: now);
      session = session.withVerification(result, updatedAt: now);
      expect(session.phase, DemoSessionPhase.verified);
      expect(session.toJson()['phase'], 'verified');
    });
  });

  group('AssertionShareHelper', () {
    test('exports json, pretty, compact, and summary formats', () {
      final assertion = _assertion();
      const helper = AssertionShareHelper(
        prettyOptions: PrettyJsonOptions.sharePanel,
      );

      final all = helper.exportAll(assertion);
      expect(all, hasLength(4));

      final pretty = helper.export(
        assertion,
        format: AssertionShareFormat.prettyJson,
      );
      expect(pretty.mimeType, 'application/json');
      expect(pretty.body, contains('"assertionId"'));
      expect(pretty.suggestedFileName, endsWith('.pretty.json'));

      final summary = helper.export(
        assertion,
        format: AssertionShareFormat.summaryText,
      );
      expect(summary.body, contains('identityProofing:'));
      expect(summary.body, contains('technical artifact'));

      final compact = helper.export(
        assertion,
        format: AssertionShareFormat.compact,
      );
      expect(compact.body.split('.'), hasLength(3));
    });
  });

  group('prettyJson options', () {
    test('sorts keys and truncates long strings', () {
      final encoded = prettyJson(
        {
          'z': 'hello',
          'a': 'abcdefghijklmnopqrstuvwxyz',
        },
        options: const PrettyJsonOptions(
          sortMapKeys: true,
          maxStringLength: 10,
        ),
      );
      expect(encoded.indexOf('"a"'), lessThan(encoded.indexOf('"z"')));
      expect(encoded, contains('abcdefghi…'));
    });

    test('prettyCanonicalJson indents canonical map ordering', () {
      final encoded = prettyCanonicalJson({
        'z': 1,
        'a': {'y': 2, 'x': 1},
      });
      expect(encoded, contains('"a"'));
      expect(encoded, contains('"x": 1'));
    });
  });

  group('DemoDashboardSnapshot', () {
    test('builds schema snapshot with summary counters', () {
      final assertion = _assertion();
      final verification = AuditAssertionVerifier(
        verifier: DemoHmacVerifier('demo'),
      ).verify(assertion);

      final snapshot = DemoDashboardSnapshot.fromAssertions(
        [assertion],
        verificationByAssertionId: {assertion.assertionId: verification},
        generatedAt: DateTime.utc(2026, 8, 7, 21),
      );

      expect(snapshot.schemaVersion, 'tis_demo_dashboard_v1');
      expect(snapshot.summary.total, 1);
      expect(snapshot.summary.verified, 1);
      expect(snapshot.summary.withLiveness, 1);
      expect(snapshot.entries.single.flowLabel, 'remote_lending');
      expect(snapshot.entries.single.verificationValid, isTrue);

      final roundTrip = DemoDashboardSnapshot.fromJson(snapshot.toJson());
      expect(roundTrip.entries.single.assertionId, 'assert_demo');
      expect(roundTrip.packageVersion, '0.4.0');
    });
  });
}
