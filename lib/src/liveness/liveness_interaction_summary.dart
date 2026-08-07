import 'package:meta/meta.dart';

/// Optional liveness-aware interaction summary supplied by the host app.
///
/// This package does not depend on `flutter_liveness_actions` or any other
/// liveness SDK. Host applications may map derived signals from any source
/// into this model.
@immutable
class LivenessInteractionSummary {
  /// Creates a [LivenessInteractionSummary].
  const LivenessInteractionSummary({
    required this.facePresent,
    required this.singleFace,
    required this.challengeCompleted,
    this.challengeType,
    this.durationMs,
    this.averageProcessingMs,
    this.rawImagesStored = false,
    this.rawImagesUploaded = false,
    this.derivedSignalsOnly = true,
    this.metrics = const {},
  });

  /// Whether a face was reported present during the interaction.
  final bool facePresent;

  /// Whether a single face was reported.
  final bool singleFace;

  /// Whether the liveness challenge completed successfully.
  final bool challengeCompleted;

  /// Optional challenge type label from the host liveness system.
  final String? challengeType;

  /// Optional total interaction duration in milliseconds.
  final int? durationMs;

  /// Optional average processing time in milliseconds.
  final int? averageProcessingMs;

  /// Whether raw images were stored. Defaults to `false`.
  final bool rawImagesStored;

  /// Whether raw images were uploaded. Defaults to `false`.
  final bool rawImagesUploaded;

  /// Whether only derived signals (not raw media) are represented.
  /// Defaults to `true`.
  final bool derivedSignalsOnly;

  /// Additional derived metrics from the host system.
  final Map<String, Object?> metrics;

  /// Privacy-oriented flags exported into audit assertions.
  Map<String, Object?> get privacyFlags => {
        'rawImagesStored': rawImagesStored,
        'rawImagesUploaded': rawImagesUploaded,
        'derivedSignalsOnly': derivedSignalsOnly,
      };

  /// Deserializes from JSON.
  factory LivenessInteractionSummary.fromJson(Map<String, Object?> json) {
    final metricsRaw = json['metrics'];
    return LivenessInteractionSummary(
      facePresent: json['facePresent']! as bool,
      singleFace: json['singleFace']! as bool,
      challengeCompleted: json['challengeCompleted']! as bool,
      challengeType: json['challengeType'] as String?,
      durationMs: json['durationMs'] as int?,
      averageProcessingMs: json['averageProcessingMs'] as int?,
      rawImagesStored: json['rawImagesStored'] as bool? ?? false,
      rawImagesUploaded: json['rawImagesUploaded'] as bool? ?? false,
      derivedSignalsOnly: json['derivedSignalsOnly'] as bool? ?? true,
      metrics:
          metricsRaw is Map ? Map<String, Object?>.from(metricsRaw) : const {},
    );
  }

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        'facePresent': facePresent,
        'singleFace': singleFace,
        'challengeCompleted': challengeCompleted,
        if (challengeType != null) 'challengeType': challengeType,
        if (durationMs != null) 'durationMs': durationMs,
        if (averageProcessingMs != null)
          'averageProcessingMs': averageProcessingMs,
        'rawImagesStored': rawImagesStored,
        'rawImagesUploaded': rawImagesUploaded,
        'derivedSignalsOnly': derivedSignalsOnly,
        if (metrics.isNotEmpty) 'metrics': metrics,
      };

  @override
  String toString() =>
      'LivenessInteractionSummary(completed: $challengeCompleted)';
}
