/// Example mapping from a flutter_liveness_actions-shaped audit event into
/// [LivenessInteractionSummary].
///
/// This file does **not** depend on Flutter or `flutter_liveness_actions`.
/// It documents a realistic host-side mapping using derived signals only.
library;

import 'package:transaction_intent_signer/transaction_intent_signer.dart';

/// Illustrative audit-event shape inspired by `flutter_liveness_actions`.
///
/// Field names are intentionally generic so host apps can adapt to the real
/// SDK event model without coupling this package to Flutter.
class SampleFlutterLivenessAuditEvent {
  /// Creates a sample event.
  const SampleFlutterLivenessAuditEvent({
    required this.faceDetected,
    required this.faceCount,
    required this.challengePassed,
    this.actionType,
    this.sessionDurationMs,
    this.avgFrameProcessingMs,
    this.actionsCompleted = const [],
    this.sdkVersion,
  });

  /// Whether the SDK reported a face present.
  final bool faceDetected;

  /// Number of faces reported by the SDK.
  final int faceCount;

  /// Whether the liveness challenge passed.
  final bool challengePassed;

  /// Challenge / action type label (e.g. `turn_head_left`).
  final String? actionType;

  /// Total session duration in milliseconds.
  final int? sessionDurationMs;

  /// Average frame processing time in milliseconds.
  final double? avgFrameProcessingMs;

  /// Completed action labels from the SDK session.
  final List<String> actionsCompleted;

  /// Optional SDK version string.
  final String? sdkVersion;

  /// Sample JSON-like map a host app might receive.
  Map<String, Object?> toJson() => {
        'faceDetected': faceDetected,
        'faceCount': faceCount,
        'challengePassed': challengePassed,
        if (actionType != null) 'actionType': actionType,
        if (sessionDurationMs != null) 'sessionDurationMs': sessionDurationMs,
        if (avgFrameProcessingMs != null)
          'avgFrameProcessingMs': avgFrameProcessingMs,
        'actionsCompleted': actionsCompleted,
        if (sdkVersion != null) 'sdkVersion': sdkVersion,
      };

  /// Parses from a generic map (host adapter input).
  factory SampleFlutterLivenessAuditEvent.fromJson(Map<String, Object?> json) {
    final actionsRaw = json['actionsCompleted'];
    return SampleFlutterLivenessAuditEvent(
      faceDetected: json['faceDetected']! as bool,
      faceCount: json['faceCount']! as int,
      challengePassed: json['challengePassed']! as bool,
      actionType: json['actionType'] as String?,
      sessionDurationMs: json['sessionDurationMs'] as int?,
      avgFrameProcessingMs: (json['avgFrameProcessingMs'] as num?)?.toDouble(),
      actionsCompleted: actionsRaw is List
          ? actionsRaw.map((e) => e.toString()).toList()
          : const [],
      sdkVersion: json['sdkVersion'] as String?,
    );
  }
}

/// Maps a sample flutter_liveness_actions-shaped event to
/// [LivenessInteractionSummary] via [LivenessSummaryMapper].
LivenessInteractionSummary mapFlutterLivenessActionsEvent(
  SampleFlutterLivenessAuditEvent event, {
  Map<String, Object?> extraMetrics = const {},
}) {
  return LivenessSummaryMapper.fromFlutterLivenessActionsLike(
    faceDetected: event.faceDetected,
    faceCount: event.faceCount,
    challengePassed: event.challengePassed,
    actionType: event.actionType,
    sessionDurationMs: event.sessionDurationMs,
    avgFrameProcessingMs: event.avgFrameProcessingMs,
    actionsCompleted: event.actionsCompleted,
    sdkVersion: event.sdkVersion,
    extraMetrics: extraMetrics,
  );
}

/// Demo entrypoint for the mapping example.
void main() {
  // ignore: avoid_print
  print('=== flutter_liveness_actions → LivenessInteractionSummary ===\n');

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

  // ignore: avoid_print
  print('Input event:\n${prettyJson(event.toJson())}\n');
  // ignore: avoid_print
  print('Mapped summary:\n${prettyJson(summary.toJson())}');
}
