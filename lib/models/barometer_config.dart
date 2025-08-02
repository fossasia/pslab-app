class BarometerConfig {
  final int updatePeriod;
  final double highLimit;
  final String activeSensor;
  final bool includeLocationData;

  const BarometerConfig({
    this.updatePeriod = 1000,
    this.highLimit = 1.10,
    this.activeSensor = 'In-built Sensor',
    this.includeLocationData = true,
  });

  BarometerConfig copyWith({
    int? updatePeriod,
    double? highLimit,
    String? activeSensor,
    bool? includeLocationData,
  }) {
    return BarometerConfig(
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

  factory BarometerConfig.fromJson(Map<String, dynamic> json) {
    return BarometerConfig(
      updatePeriod: json['updatePeriod'] ?? 1000,
      highLimit: json['highLimit'] ?? 1.10,
      activeSensor: json['activeSensor'] ?? 'In-built Sensor',
      includeLocationData: json['includeLocationData'] ?? true,
    );
  }
}
