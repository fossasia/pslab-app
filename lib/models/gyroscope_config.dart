class GyroscopeConfig {
  final int updatePeriod;
  final int highLimit;
  final double sensorGain;
  final int lowLimit;
  final bool includeLocationData;
  final String activeSensor;
  final bool autoScale;

  const GyroscopeConfig({
    this.updatePeriod = 50,
    this.highLimit = 20,
    this.lowLimit = 20,
    this.sensorGain = 1.0,
    this.includeLocationData = true,
    this.activeSensor = 'In-built Sensor',
    this.autoScale = true,
  });

  GyroscopeConfig copyWith({
    int? updatePeriod,
    int? highLimit,
    int? lowLimit,
    double? sensorGain,
    bool? includeLocationData,
    String? activeSensor,
    bool? autoScale,
  }) {
    return GyroscopeConfig(
      updatePeriod: updatePeriod ?? this.updatePeriod,
      highLimit: highLimit ?? this.highLimit,
      lowLimit: lowLimit ?? this.lowLimit,
      sensorGain: sensorGain ?? this.sensorGain,
      includeLocationData: includeLocationData ?? this.includeLocationData,
      activeSensor: activeSensor ?? this.activeSensor,
      autoScale: autoScale ?? this.autoScale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updatePeriod': updatePeriod,
      'highLimit': highLimit,
      'lowLimit': lowLimit,
      'sensorGain': sensorGain,
      'includeLocationData': includeLocationData,
      'activeSensor': activeSensor,
      'autoScale': autoScale,
    };
  }

  factory GyroscopeConfig.fromJson(Map<String, dynamic> json) {
    return GyroscopeConfig(
      updatePeriod: json['updatePeriod'] ?? 50,
      highLimit: json['highLimit'] ?? 20,
      lowLimit: json['lowLimit'] ?? 20,
      sensorGain: json['sensorGain'] ?? 1.0,
      includeLocationData: json['includeLocationData'] ?? true,
      activeSensor: json['activeSensor'] ?? 'In-built Sensor',
      autoScale: json['autoScale'] ?? true,
    );
  }
}
