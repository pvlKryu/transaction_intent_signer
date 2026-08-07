import 'liveness_interaction_summary.dart';

/// Host-side helpers for mapping external liveness audit events.
///
/// These helpers do **not** depend on Flutter or `flutter_liveness_actions`.
/// They accept derived signals that a host app can extract from any SDK.
abstract final class LivenessSummaryMapper {
  /// Maps flutter_liveness_actions-like derived signals into
  /// [LivenessInteractionSummary].
  ///
  /// Privacy defaults remain conservative (`rawImagesStored` /
  /// `rawImagesUploaded` false, `derivedSignalsOnly` true).
  static LivenessInteractionSummary fromFlutterLivenessActionsLike({
    required bool faceDetected,
    required int faceCount,
    required bool challengePassed,
    String? actionType,
    int? sessionDurationMs,
    double? avgFrameProcessingMs,
    List<String> actionsCompleted = const [],
    String? sdkVersion,
    Map<String, Object?> extraMetrics = const {},
  }) {
    return LivenessInteractionSummary(
      facePresent: faceDetected,
      singleFace: faceCount == 1,
      challengeCompleted: challengePassed,
      challengeType: actionType,
      durationMs: sessionDurationMs,
      averageProcessingMs: avgFrameProcessingMs?.round(),
      rawImagesStored: false,
      rawImagesUploaded: false,
      derivedSignalsOnly: true,
      metrics: {
        'source': 'flutter_liveness_actions',
        if (sdkVersion != null) 'sdkVersion': sdkVersion,
        if (actionsCompleted.isNotEmpty) 'actionsCompleted': actionsCompleted,
        ...extraMetrics,
      },
    );
  }

  /// Convenience mapper from a generic JSON-like map.
  ///
  /// Expected keys (illustrative): `faceDetected`, `faceCount`,
  /// `challengePassed`, optional `actionType`, `sessionDurationMs`,
  /// `avgFrameProcessingMs`, `actionsCompleted`, `sdkVersion`.
  static LivenessInteractionSummary fromFlutterLivenessActionsLikeMap(
    Map<String, Object?> json, {
    Map<String, Object?> extraMetrics = const {},
  }) {
    final actionsRaw = json['actionsCompleted'];
    return fromFlutterLivenessActionsLike(
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
      extraMetrics: extraMetrics,
    );
  }
}
