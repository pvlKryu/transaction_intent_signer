import 'package:meta/meta.dart';

import '../audit/audit_assertion_verification_result.dart';
import '../audit/signed_audit_assertion.dart';
import '../authenticator/authenticator_confirmation.dart';
import '../challenge/intent_challenge.dart';
import '../hashing/operation_terms_hash.dart';
import '../intent/transaction_intent.dart';
import '../liveness/liveness_interaction_summary.dart';

/// Lifecycle phase for a mobile demo confirmation session.
enum DemoSessionPhase {
  /// Intent drafted, not yet challenged.
  draft,

  /// Challenge issued and bound to terms hash.
  challenged,

  /// Authenticator confirmation captured.
  confirmed,

  /// Signed audit assertion produced.
  asserted,

  /// Assertion verified by a verifier.
  verified,

  /// Flow failed validation or verification.
  failed,
}

/// Serialization helpers for [DemoSessionPhase].
extension DemoSessionPhaseX on DemoSessionPhase {
  /// Wire / JSON value.
  String get wireName {
    switch (this) {
      case DemoSessionPhase.draft:
        return 'draft';
      case DemoSessionPhase.challenged:
        return 'challenged';
      case DemoSessionPhase.confirmed:
        return 'confirmed';
      case DemoSessionPhase.asserted:
        return 'asserted';
      case DemoSessionPhase.verified:
        return 'verified';
      case DemoSessionPhase.failed:
        return 'failed';
    }
  }

  /// Parses a wire name.
  static DemoSessionPhase fromWireName(String value) {
    switch (value) {
      case 'challenged':
        return DemoSessionPhase.challenged;
      case 'confirmed':
        return DemoSessionPhase.confirmed;
      case 'asserted':
        return DemoSessionPhase.asserted;
      case 'verified':
        return DemoSessionPhase.verified;
      case 'failed':
        return DemoSessionPhase.failed;
      case 'draft':
      default:
        return DemoSessionPhase.draft;
    }
  }
}

/// Shared pure-Dart session model for a Flutter (or any) demo host app.
///
/// This package stays Flutter-free. Host apps can hold this model in app state
/// and render UI from it.
@immutable
class DemoConfirmationSession {
  /// Creates a [DemoConfirmationSession].
  const DemoConfirmationSession({
    required this.sessionId,
    required this.intent,
    required this.phase,
    required this.updatedAt,
    this.operationTermsHash,
    this.challenge,
    this.authenticatorConfirmation,
    this.livenessInteractionSummary,
    this.assertion,
    this.verificationResult,
    this.flowLabel,
    this.errorMessage,
  });

  /// Host session id (UI / navigation correlation).
  final String sessionId;

  /// Current transaction intent.
  final TransactionIntent intent;

  /// Current demo phase.
  final DemoSessionPhase phase;

  /// Last update timestamp (UTC).
  final DateTime updatedAt;

  /// Optional hashed terms.
  final OperationTermsHash? operationTermsHash;

  /// Optional issued challenge.
  final IntentChallenge? challenge;

  /// Optional authenticator confirmation.
  final AuthenticatorConfirmation? authenticatorConfirmation;

  /// Optional liveness summary.
  final LivenessInteractionSummary? livenessInteractionSummary;

  /// Optional signed assertion.
  final SignedAuditAssertion? assertion;

  /// Optional verification result.
  final AuditAssertionVerificationResult? verificationResult;

  /// Optional human flow label (`remote_lending`, `large_transfer`, ...).
  final String? flowLabel;

  /// Optional error message when [phase] is [DemoSessionPhase.failed].
  final String? errorMessage;

  /// Starts a draft session from an intent.
  factory DemoConfirmationSession.draft({
    required String sessionId,
    required TransactionIntent intent,
    String? flowLabel,
    DateTime? updatedAt,
  }) {
    return DemoConfirmationSession(
      sessionId: sessionId,
      intent: intent,
      phase: DemoSessionPhase.draft,
      updatedAt: (updatedAt ?? DateTime.now()).toUtc(),
      flowLabel: flowLabel,
    );
  }

  /// Returns a copy with selected fields replaced.
  DemoConfirmationSession copyWith({
    TransactionIntent? intent,
    DemoSessionPhase? phase,
    DateTime? updatedAt,
    OperationTermsHash? operationTermsHash,
    IntentChallenge? challenge,
    AuthenticatorConfirmation? authenticatorConfirmation,
    LivenessInteractionSummary? livenessInteractionSummary,
    SignedAuditAssertion? assertion,
    AuditAssertionVerificationResult? verificationResult,
    String? flowLabel,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return DemoConfirmationSession(
      sessionId: sessionId,
      intent: intent ?? this.intent,
      phase: phase ?? this.phase,
      updatedAt: (updatedAt ?? DateTime.now()).toUtc(),
      operationTermsHash: operationTermsHash ?? this.operationTermsHash,
      challenge: challenge ?? this.challenge,
      authenticatorConfirmation:
          authenticatorConfirmation ?? this.authenticatorConfirmation,
      livenessInteractionSummary:
          livenessInteractionSummary ?? this.livenessInteractionSummary,
      assertion: assertion ?? this.assertion,
      verificationResult: verificationResult ?? this.verificationResult,
      flowLabel: flowLabel ?? this.flowLabel,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// Advances to challenged phase.
  DemoConfirmationSession withChallenge({
    required OperationTermsHash operationTermsHash,
    required IntentChallenge challenge,
    DateTime? updatedAt,
  }) {
    return copyWith(
      phase: DemoSessionPhase.challenged,
      operationTermsHash: operationTermsHash,
      challenge: challenge,
      updatedAt: updatedAt,
      clearErrorMessage: true,
    );
  }

  /// Advances to confirmed phase.
  DemoConfirmationSession withConfirmation({
    required AuthenticatorConfirmation authenticatorConfirmation,
    LivenessInteractionSummary? livenessInteractionSummary,
    DateTime? updatedAt,
  }) {
    return copyWith(
      phase: DemoSessionPhase.confirmed,
      authenticatorConfirmation: authenticatorConfirmation,
      livenessInteractionSummary: livenessInteractionSummary,
      updatedAt: updatedAt,
      clearErrorMessage: true,
    );
  }

  /// Advances to asserted phase.
  DemoConfirmationSession withAssertion(
    SignedAuditAssertion assertion, {
    DateTime? updatedAt,
  }) {
    return copyWith(
      phase: DemoSessionPhase.asserted,
      assertion: assertion,
      updatedAt: updatedAt,
      clearErrorMessage: true,
    );
  }

  /// Advances to verified or failed based on [result].
  DemoConfirmationSession withVerification(
    AuditAssertionVerificationResult result, {
    DateTime? updatedAt,
  }) {
    return copyWith(
      phase:
          result.isValid ? DemoSessionPhase.verified : DemoSessionPhase.failed,
      verificationResult: result,
      updatedAt: updatedAt,
      errorMessage: result.isValid ? null : result.failureReason,
      clearErrorMessage: result.isValid,
    );
  }

  /// Marks the session failed with [message].
  DemoConfirmationSession withFailure(
    String message, {
    DateTime? updatedAt,
  }) {
    return copyWith(
      phase: DemoSessionPhase.failed,
      errorMessage: message,
      updatedAt: updatedAt,
    );
  }

  /// Serializes to JSON for host persistence / debug panels.
  Map<String, Object?> toJson() => {
        'sessionId': sessionId,
        'phase': phase.wireName,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'intent': intent.toJson(),
        if (operationTermsHash != null)
          'operationTermsHash': operationTermsHash!.toJson(),
        if (challenge != null) 'challenge': challenge!.toJson(),
        if (authenticatorConfirmation != null)
          'authenticatorConfirmation': authenticatorConfirmation!.toJson(),
        if (livenessInteractionSummary != null)
          'livenessInteractionSummary': livenessInteractionSummary!.toJson(),
        if (assertion != null) 'assertion': assertion!.toJson(),
        if (verificationResult != null)
          'verificationResult': verificationResult!.toJson(),
        if (flowLabel != null) 'flowLabel': flowLabel,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };

  @override
  String toString() =>
      'DemoConfirmationSession($sessionId, phase=${phase.wireName})';
}
