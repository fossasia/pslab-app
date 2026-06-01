class ThermometerConfig {
  final int updatePeriod;
  final String activeSensor;
  final String unit;
  final bool includeLocationData;

  const ThermometerConfig({
    this.updatePeriod = 500,
    this.activeSensor = 'In-built Sensor',
    this.unit = 'Celsius',
    this.includeLocationData = false,
  });

  ThermometerConfig copyWith({
    int? updatePeriod,
    String? activeSensor,
    String? unit,
    bool? includeLocationData,
  }) {
    return ThermometerConfig(
      updatePeriod: updatePeriod ?? this.updatePeriod,
      activeSensor: activeSensor ?? this.activeSensor,
      unit: unit ?? this.unit,
      includeLocationData: includeLocationData ?? this.includeLocationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updatePeriod': updatePeriod,
      'activeSensor': activeSensor,
      'unit': unit,
      'includeLocationData': includeLocationData,
    };
  }

  factory ThermometerConfig.fromJson(Map<String, dynamic> json) {
    return ThermometerConfig(
      updatePeriod: json['updatePeriod'] as int? ?? 500,
      activeSensor: json['activeSensor'] as String? ?? 'In-built Sensor',
      unit: json['unit'] as String? ?? 'Celsius',
      includeLocationData: json['includeLocationData'] as bool? ?? false,
    );
  }
}
