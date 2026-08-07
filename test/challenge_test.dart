import 'package:test/test.dart';
import 'package:transaction_intent_signer/transaction_intent_signer.dart';

TransactionIntent _intent({DateTime? expiresAt}) {
  return TransactionIntent(
    intentId: 'intent_123',
    operationId: 'loan_offer_789',
    operationType: TransactionIntentType.confirmLoanOffer,
    customerReference: 'customer_456',
    institutionReference: 'community_bank_demo',
    operationTerms: const {
      'loanAmount': 15000,
      'currency': 'USD',
      'apr': 12.5,
    },
    createdAt: DateTime.utc(2026, 8, 7, 12),
    expiresAt: expiresAt,
  );
}

void main() {
  group('IntentChallengeBuilder', () {
    const hasher = OperationTermsHasher();
    final builder = IntentChallengeBuilder();

    test('challenge binds intentId, operationTermsHash, and serverNonce', () {
      final intent = _intent();
      final hash = hasher.sha256Canonical(intent.operationTerms);
      final challenge = builder.build(
        intent: intent,
        operationTermsHash: hash,
        serverNonce: 'nonce_abc',
        expiresIn: const Duration(minutes: 5),
        issuedAt: DateTime.utc(2026, 8, 7, 12, 1),
        challengeId: 'chal_1',
      );

      expect(challenge.intentId, 'intent_123');
      expect(challenge.operationTermsHash.value, hash.value);
      expect(challenge.serverNonce, 'nonce_abc');
      expect(challenge.challengePayload['intentId'], 'intent_123');
      expect(challenge.challengePayload['operationTermsHash'], hash.value);
      expect(challenge.challengePayload['serverNonce'], 'nonce_abc');
    });

    test('challenge expiration works', () {
      final intent = _intent();
      final hash = hasher.sha256Canonical(intent.operationTerms);
      final challenge = builder.build(
        intent: intent,
        operationTermsHash: hash,
        serverNonce: 'nonce_abc',
        expiresIn: const Duration(minutes: 5),
        issuedAt: DateTime.utc(2026, 8, 7, 12),
      );

      expect(
        challenge.isExpired(now: DateTime.utc(2026, 8, 7, 12, 4)),
        isFalse,
      );
      expect(
        challenge.isExpired(now: DateTime.utc(2026, 8, 7, 12, 5)),
        isTrue,
      );
    });

    test('expired challenge fails ensureNotExpired', () {
      final intent = _intent();
      final hash = hasher.sha256Canonical(intent.operationTerms);
      final challenge = builder.build(
        intent: intent,
        operationTermsHash: hash,
        serverNonce: 'nonce_abc',
        expiresIn: const Duration(minutes: 1),
        issuedAt: DateTime.utc(2026, 8, 7, 12),
      );

      expect(
        () => builder.ensureNotExpired(
          challenge,
          now: DateTime.utc(2026, 8, 7, 12, 2),
        ),
        throwsA(
          isA<ChallengeException>().having(
            (e) => e.code,
            'code',
            'challenge_expired',
          ),
        ),
      );
    });

    test('cannot build challenge for expired intent', () {
      final intent = _intent(expiresAt: DateTime.utc(2026, 8, 7, 11));
      final hash = hasher.sha256Canonical(intent.operationTerms);
      expect(
        () => builder.build(
          intent: intent,
          operationTermsHash: hash,
          serverNonce: 'nonce_abc',
          expiresIn: const Duration(minutes: 5),
          issuedAt: DateTime.utc(2026, 8, 7, 12),
        ),
        throwsA(isA<ChallengeException>()),
      );
    });
  });
}
