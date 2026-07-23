class DustSensorConfig {
  final int updatePeriod;
  final double highLimit;
  final String activeSensor;
  final bool includeLocationData;

  const DustSensorConfig({
    this.updatePeriod = 1000,
    this.highLimit = 4.0,
    this.activeSensor = 'In-built Sensor',
    this.includeLocationData = true,
  });

  DustSensorConfig copyWith({
    int? updatePeriod,
    double? highLimit,
    String? activeSensor,
    bool? includeLocationData,
  }) {
    return DustSensorConfig(
      updatePeriod: updatePeriod ?? this.updatePeriod,
      highLimit: highLimit ?? this.highLimit,
      activeSensor: activeSensor ?? this.activeSensor,
      includeLocationData: includeLocationData ?? this.includeLocationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updatePeriod': updatePeriod,
      'highLimit': highLimit,
      'activeSensor': activeSensor,
      'includeLocationData': includeLocationData,
    };
  }

  factory DustSensorConfig.fromJson(Map<String, dynamic> json) {
    return DustSensorConfig(
      updatePeriod: json['updatePeriod'] ?? 1000,
      highLimit: (json['highLimit'] ?? 4.0).toDouble(),
      activeSensor: json['activeSensor'] ?? 'In-built Sensor',
      includeLocationData: json['includeLocationData'] ?? true,
    );
  }
}
