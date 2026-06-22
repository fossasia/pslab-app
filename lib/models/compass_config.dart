class CompassConfig {
  final bool includeLocationData;
  final String sensorSource;

  const CompassConfig({
    this.includeLocationData = false,
    this.sensorSource = 'inbuilt',
  });

  CompassConfig copyWith({
    bool? includeLocationData,
    String? sensorSource,
  }) {
    return CompassConfig(
      includeLocationData: includeLocationData ?? this.includeLocationData,
      sensorSource: sensorSource ?? this.sensorSource,
    );
  }

  factory CompassConfig.fromJson(Map<String, dynamic> json) {
    return CompassConfig(
      includeLocationData: json['includeLocationData'] as bool? ?? false,
      sensorSource: json['sensorSource'] as String? ?? 'inbuilt',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includeLocationData': includeLocationData,
      'sensorSource': sensorSource,
    };
  }
}
