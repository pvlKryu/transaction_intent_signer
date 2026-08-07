import 'package:test/test.dart';
import 'package:transaction_intent_signer/transaction_intent_signer.dart';

void main() {
  group('CanonicalJsonEncoder', () {
    const encoder = CanonicalJsonEncoder();

    test('sorts map keys', () {
      final encoded = encoder.encode({
        'z': 1,
        'a': 2,
        'm': 3,
      });
      expect(encoded, '{"a":2,"m":3,"z":1}');
    });

    test('sorts nested maps', () {
      final encoded = encoder.encode({
        'outer': {
          'b': true,
          'a': {
            'y': 2,
            'x': 1,
          },
        },
      });
      expect(encoded, '{"outer":{"a":{"x":1,"y":2},"b":true}}');
    });

    test('preserves list order', () {
      expect(
          encoder.encode({
            'items': [3, 1, 2]
          }),
          '{"items":[3,1,2]}');
    });

    test('supports strings, numbers, booleans, null', () {
      expect(
        encoder.encode({
          's': 'hi',
          'n': 1.5,
          'b': false,
          'u': null,
        }),
        '{"b":false,"n":1.5,"s":"hi","u":null}',
      );
    });

    test('throws meaningful exception for unsupported types', () {
      expect(
        () => encoder.encode({'when': DateTime.utc(2026)}),
        throwsA(
          isA<CanonicalizationException>().having(
            (e) => e.message,
            'message',
            contains('Unsupported type'),
          ),
        ),
      );
    });
  });

  group('OperationTermsHasher', () {
    const hasher = OperationTermsHasher();

    test('same terms with different key order produce same hash', () {
      final a = hasher.sha256Canonical({
        'loanAmount': 15000,
        'apr': 12.5,
        'currency': 'USD',
      });
      final b = hasher.sha256Canonical({
        'currency': 'USD',
        'loanAmount': 15000,
        'apr': 12.5,
      });
      expect(a.value, b.value);
      expect(a.algorithm, 'sha256');
      expect(a.canonicalization, 'canonical_json_v1');
      expect(a.value.startsWith('sha256:'), isTrue);
    });

    test('changed loanAmount changes hash', () {
      final original = hasher.sha256Canonical({
        'loanAmount': 15000,
        'apr': 12.5,
      });
      final changed = hasher.sha256Canonical({
        'loanAmount': 16000,
        'apr': 12.5,
      });
      expect(original.value, isNot(changed.value));
    });

    test('changed APR changes hash', () {
      final original = hasher.sha256Canonical({
        'loanAmount': 15000,
        'apr': 12.5,
      });
      final changed = hasher.sha256Canonical({
        'loanAmount': 15000,
        'apr': 13.5,
      });
      expect(original.value, isNot(changed.value));
    });

    test('changed transfer recipient changes hash', () {
      final original = hasher.sha256Canonical({
        'amount': 5000,
        'currency': 'USD',
        'recipientAccount': 'acct_111',
      });
      final changed = hasher.sha256Canonical({
        'amount': 5000,
        'currency': 'USD',
        'recipientAccount': 'acct_222',
      });
      expect(original.value, isNot(changed.value));
    });
  });
}
