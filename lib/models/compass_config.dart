class CompassConfig {
  final bool includeLocationData;

  const CompassConfig({
    this.includeLocationData = false,
  });

  CompassConfig copyWith({
    bool? includeLocationData,
  }) {
    return CompassConfig(
      includeLocationData: includeLocationData ?? this.includeLocationData,
    );
  }

  factory CompassConfig.fromJson(Map<String, dynamic> json) {
    return CompassConfig(
      includeLocationData: json['includeLocationData'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includeLocationData': includeLocationData,
    };
  }
}
