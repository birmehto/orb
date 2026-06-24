class BubbleSettings {
  final int color;
  final double size;
  final double opacity;
  final bool autoHideEnabled;
  final int autoHideTimeoutSeconds;

  const BubbleSettings({
    this.color = 0xFF6366F1,
    this.size = 56,
    this.opacity = 1.0,
    this.autoHideEnabled = false,
    this.autoHideTimeoutSeconds = 30,
  });

  BubbleSettings copyWith({
    int? color,
    double? size,
    double? opacity,
    bool? autoHideEnabled,
    int? autoHideTimeoutSeconds,
  }) {
    return BubbleSettings(
      color: color ?? this.color,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      autoHideEnabled: autoHideEnabled ?? this.autoHideEnabled,
      autoHideTimeoutSeconds: autoHideTimeoutSeconds ?? this.autoHideTimeoutSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
    'color': color,
    'size': size,
    'opacity': opacity,
    'autoHideEnabled': autoHideEnabled,
    'autoHideTimeoutSeconds': autoHideTimeoutSeconds,
  };

  factory BubbleSettings.fromJson(Map<String, dynamic> json) => BubbleSettings(
    color: json['color'] as int? ?? 0xFF6366F1,
    size: (json['size'] as num?)?.toDouble() ?? 56,
    opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    autoHideEnabled: json['autoHideEnabled'] as bool? ?? false,
    autoHideTimeoutSeconds: json['autoHideTimeoutSeconds'] as int? ?? 30,
  );
}
