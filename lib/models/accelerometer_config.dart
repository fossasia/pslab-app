class AccelerometerConfig {
  final int updatePeriod;
  final int highLimit;
  final int lowLimit;
  final String activeSensor;
  final int sensorGain;
  final bool includeLocationData;

  const AccelerometerConfig({
    this.updatePeriod = 1000,
    this.highLimit = 200,
    this.lowLimit = 200,
    this.activeSensor = 'In-built Sensor',
    this.sensorGain = 1,
    this.includeLocationData = true,
  });

  AccelerometerConfig copyWith({
    int? updatePeriod,
    int? highLimit,
    int? lowLimit,
    String? activeSensor,
    int? sensorGain,
    bool? includeLocationData,
  }) {
    return AccelerometerConfig(
      updatePeriod: updatePeriod ?? this.updatePeriod,
      highLimit: highLimit ?? this.highLimit,
      lowLimit: lowLimit ?? this.lowLimit,
      activeSensor: activeSensor ?? this.activeSensor,
      sensorGain: sensorGain ?? this.sensorGain,
      includeLocationData: includeLocationData ?? this.includeLocationData,
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
    };
  }

  factory AccelerometerConfig.fromJson(Map<String, dynamic> json) {
    return AccelerometerConfig(
      updatePeriod: json['updatePeriod'] ?? 1000,
      highLimit: json['highLimit'] ?? 200,
      lowLimit: json['lowLimit'] ?? json['depthLimit'] ?? 200,
      activeSensor: json['activeSensor'] ?? 'In-built Sensor',
      sensorGain: json['sensorGain'] ?? 1,
      includeLocationData: json['includeLocationData'] ?? true,
    );
  }
}
