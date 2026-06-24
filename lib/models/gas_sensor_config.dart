class GasSensorConfig {
  final int updatePeriod;
  final String activeSensor;
  final bool includeLocationData;

  const GasSensorConfig({
    this.updatePeriod = 2000,
    this.activeSensor = 'MQ-135',
    this.includeLocationData = true,
  });

  GasSensorConfig copyWith({
    int? updatePeriod,
    String? activeSensor,
    bool? includeLocationData,
  }) {
    return GasSensorConfig(
      updatePeriod: updatePeriod ?? this.updatePeriod,
      activeSensor: activeSensor ?? this.activeSensor,
      includeLocationData: includeLocationData ?? this.includeLocationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updatePeriod': updatePeriod,
      'activeSensor': activeSensor,
      'includeLocationData': includeLocationData,
    };
  }

  factory GasSensorConfig.fromJson(Map<String, dynamic> json) {
    return GasSensorConfig(
      updatePeriod: json['updatePeriod'] ?? 2000,
      activeSensor: json['activeSensor'] ?? 'MQ-135',
      includeLocationData: json['includeLocationData'] ?? true,
    );
  }
}
