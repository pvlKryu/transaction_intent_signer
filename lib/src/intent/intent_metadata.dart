/// Optional metadata attached to a [TransactionIntent].
///
/// Use [customOperationType] when [TransactionIntentType.custom] is selected
/// so host systems can retain an institution-specific operation label.
class IntentMetadata {
  /// Creates [IntentMetadata].
  const IntentMetadata({
    this.customOperationType,
    this.channel,
    this.sessionReference,
    this.extra = const {},
  });

  /// Institution-defined operation type label when using
  /// [TransactionIntentType.custom].
  final String? customOperationType;

  /// Optional delivery / confirmation channel (e.g. `mobile_app`).
  final String? channel;

  /// Optional host-session correlation id.
  final String? sessionReference;

  /// Additional opaque key/value metadata.
  final Map<String, Object?> extra;

  /// Deserializes from JSON.
  factory IntentMetadata.fromJson(Map<String, Object?> json) {
    final extraRaw = json['extra'];
    return IntentMetadata(
      customOperationType: json['customOperationType'] as String?,
      channel: json['channel'] as String?,
      sessionReference: json['sessionReference'] as String?,
      extra: extraRaw is Map ? Map<String, Object?>.from(extraRaw) : const {},
    );
  }

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
        if (customOperationType != null)
          'customOperationType': customOperationType,
        if (channel != null) 'channel': channel,
        if (sessionReference != null) 'sessionReference': sessionReference,
        if (extra.isNotEmpty) 'extra': extra,
      };

  /// Returns a copy with selected fields replaced.
  IntentMetadata copyWith({
    String? customOperationType,
    String? channel,
    String? sessionReference,
    Map<String, Object?>? extra,
  }) {
    return IntentMetadata(
      customOperationType: customOperationType ?? this.customOperationType,
      channel: channel ?? this.channel,
      sessionReference: sessionReference ?? this.sessionReference,
      extra: extra ?? this.extra,
    );
  }

  @override
  String toString() => 'IntentMetadata(${toJson()})';
}
