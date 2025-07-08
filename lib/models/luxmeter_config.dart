class LuxMeterConfig {
  final int updatePeriod;
  final int highLimit;
  final String activeSensor;
  final int sensorGain;
  final bool includeLocationData;

  const LuxMeterConfig({
    this.updatePeriod = 1000,
    this.highLimit = 2000,
    this.activeSensor = 'In-built Sensor',
    this.sensorGain = 1,
    this.includeLocationData = true,
  });

  LuxMeterConfig copyWith({
    int? updatePeriod,
    int? highLimit,
    String? activeSensor,
    int? sensorGain,
    bool? includeLocationData,
  }) {
    return LuxMeterConfig(
      updatePeriod: updatePeriod ?? this.updatePeriod,
      highLimit: highLimit ?? this.highLimit,
      activeSensor: activeSensor ?? this.activeSensor,
      sensorGain: sensorGain ?? this.sensorGain,
      includeLocationData: includeLocationData ?? this.includeLocationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updatePeriod': updatePeriod,
      'highLimit': highLimit,
      'activeSensor': activeSensor,
      'sensorGain': sensorGain,
      'includeLocationData': includeLocationData,
    };
  }

  factory LuxMeterConfig.fromJson(Map<String, dynamic> json) {
    return LuxMeterConfig(
      updatePeriod: json['updatePeriod'] ?? 1000,
      highLimit: json['highLimit'] ?? 2000,
      activeSensor: json['activeSensor'] ?? 'In-built Sensor',
      sensorGain: json['sensorGain'] ?? 1,
      includeLocationData: json['includeLocationData'] ?? true,
    );
  }
}
