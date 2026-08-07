/// Shared demo helpers for integration examples.
///
/// Demo signing secrets are for local reference runs only.
library;

import 'package:transaction_intent_signer/transaction_intent_signer.dart';

/// Demo-only HMAC secret. Do not use in production.
const String demoHmacSecret = 'demo-only-secret-do-not-use-in-prod';

/// Builds a demo signer.
DemoHmacSigner demoSigner() => DemoHmacSigner(demoHmacSecret);

/// Builds a demo verifier.
DemoHmacVerifier demoVerifier() => DemoHmacVerifier(demoHmacSecret);

/// In-memory challenge store used by backend validator demos.
class MockChallengeStore {
  final Map<String, IntentChallenge> _byId = {};

  /// Saves a challenge for later lookup.
  void save(IntentChallenge challenge) {
    _byId[challenge.challengeId] = challenge;
  }

  /// Returns a challenge by id, if present.
  IntentChallenge? get(String challengeId) => _byId[challengeId];
}

/// Prints a short section header for demo scripts.
void section(String title) {
  // ignore: avoid_print
  print('\n=== $title ===');
}
