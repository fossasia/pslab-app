class AccelerometerConfig {
  final int updatePeriod;
  final int highLimit;
  final int lowLimit;
  final String activeSensor;
  final double sensorGain;
  final bool includeLocationData;
  final bool autoScale;

  const AccelerometerConfig({
    this.updatePeriod = 50,
    this.highLimit = 20,
    this.lowLimit = 20,
    this.activeSensor = 'In-built Sensor',
    this.sensorGain = 1.0,
    this.includeLocationData = true,
    this.autoScale = true,
  });

  AccelerometerConfig copyWith({
    int? updatePeriod,
    int? highLimit,
    int? lowLimit,
    String? activeSensor,
    double? sensorGain,
    bool? includeLocationData,
    bool? autoScale,
  }) {
    return AccelerometerConfig(
      updatePeriod: updatePeriod ?? this.updatePeriod,
      highLimit: highLimit ?? this.highLimit,
      lowLimit: lowLimit ?? this.lowLimit,
      activeSensor: activeSensor ?? this.activeSensor,
      sensorGain: sensorGain ?? this.sensorGain,
      includeLocationData: includeLocationData ?? this.includeLocationData,
      autoScale: autoScale ?? this.autoScale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updatePeriod': updatePeriod,
      'highLimit': highLimit,
      'lowLimit': lowLimit,
      'activeSensor': activeSensor,
      'sensorGain': sensorGain,
      'includeLocationData': includeLocationData,
      'autoScale': autoScale,
    };
  }

  factory AccelerometerConfig.fromJson(Map<String, dynamic> json) {
    return AccelerometerConfig(
      updatePeriod: json['updatePeriod'] ?? 50,
      highLimit: json['highLimit'] ?? 20,
      lowLimit: json['lowLimit'] ?? 20,
      activeSensor: json['activeSensor'] ?? 'In-built Sensor',
      sensorGain: json['sensorGain'] ?? 1.0,
      includeLocationData: json['includeLocationData'] ?? true,
      autoScale: json['autoScale'] ?? true,
    );
  }
}
