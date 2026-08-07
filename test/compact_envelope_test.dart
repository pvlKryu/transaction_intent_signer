import 'dart:convert';

import 'package:test/test.dart';
import 'package:transaction_intent_signer/transaction_intent_signer.dart';

SignedAuditAssertion _sampleAssertion() {
  final intent = TransactionIntent(
    intentId: 'intent_compact',
    operationId: 'loan_offer_compact',
    operationType: TransactionIntentType.confirmLoanOffer,
    customerReference: 'customer_1',
    institutionReference: 'community_bank_demo',
    operationTerms: const {
      'loanAmount': 10000,
      'currency': 'USD',
      'apr': 9.9,
    },
    createdAt: DateTime.utc(2026, 8, 7, 12),
  );
  final hash =
      const OperationTermsHasher().sha256Canonical(intent.operationTerms);
  final challenge = IntentChallengeBuilder().build(
    intent: intent,
    operationTermsHash: hash,
    serverNonce: 'nonce_compact',
    expiresIn: const Duration(minutes: 10),
    issuedAt: DateTime.utc(2026, 8, 7, 12, 1),
    challengeId: 'chal_compact',
  );

  return AuditAssertionBuilder(
    signer: DemoHmacSigner('compact-secret'),
  ).build(
    intent: intent,
    challenge: challenge,
    authenticatorConfirmation: AuthenticatorConfirmation.simulated(
      confirmedAt: DateTime.utc(2026, 8, 7, 12, 2),
    ),
    createdAt: DateTime.utc(2026, 8, 7, 12, 2),
    assertionId: 'assert_compact',
    assertionMetadata: const AssertionMetadata(
      producer: 'backend',
      correlationId: 'trace_1',
    ),
  );
}

void main() {
  group('CompactAssertionEnvelope', () {
    const codec = CompactAssertionEnvelope();

    test('encode/decode round-trip preserves signature and payload', () {
      final original = _sampleAssertion();
      final compact = codec.encode(original);

      expect(compact.split('.'), hasLength(3));

      final decoded = codec.decode(compact);
      expect(decoded.assertionId, original.assertionId);
      expect(decoded.signature, original.signature);
      expect(decoded.signatureAlgorithm, original.signatureAlgorithm);
      expect(
          decoded.operationTermsHash.value, original.operationTermsHash.value);
      expect(decoded.assertionMetadata.producer, 'backend');
      expect(decoded.schemaVersion, 'tis_assertion_v1');

      final result = AuditAssertionVerifier(
        verifier: DemoHmacVerifier('compact-secret'),
      ).verify(decoded);
      expect(result.isValid, isTrue);
    });

    test('mutated payload in compact form fails signature verification', () {
      final original = _sampleAssertion();
      final parts = codec.encode(original).split('.');

      // Rebuild a compact string with a mutated payload segment.
      final mutatedPayload = Map<String, Object?>.from(original.unsignedPayload)
        ..['customerReference'] = 'mutated_customer';
      final mutatedMiddle = base64Url
          .encode(utf8.encode(jsonEncode(mutatedPayload)))
          .replaceAll('=', '');
      final mutatedCompact = '${parts[0]}.$mutatedMiddle.${parts[2]}';

      final decoded = codec.decode(mutatedCompact);
      final result = AuditAssertionVerifier(
        verifier: DemoHmacVerifier('compact-secret'),
      ).verify(decoded);

      expect(result.isValid, isFalse);
      expect(result.failureCode, VerificationFailureCode.signatureInvalid);
    });

    test('invalid segment count throws', () {
      expect(
        () => codec.decode('only.two'),
        throwsA(
          isA<AuditAssertionException>().having(
            (e) => e.code,
            'code',
            'compact_envelope_invalid',
          ),
        ),
      );
    });
  });
}
