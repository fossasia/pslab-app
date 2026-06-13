class GyroscopeConfig {
  final int updatePeriod;
  final int highLimit;
  final int sensorGain;
  final int lowLimit;
  final bool includeLocationData;

  const GyroscopeConfig({
    this.updatePeriod = 1000,
    this.highLimit = 200,
    this.lowLimit = 200,
    this.sensorGain = 1,
    this.includeLocationData = true,
  });

  GyroscopeConfig copyWith({
    int? updatePeriod,
    int? highLimit,
    int? lowLimit,
    int? sensorGain,
    bool? includeLocationData,
  }) {
    return GyroscopeConfig(
      updatePeriod: updatePeriod ?? this.updatePeriod,
      highLimit: highLimit ?? this.highLimit,
      lowLimit: lowLimit ?? this.lowLimit,
      sensorGain: sensorGain ?? this.sensorGain,
      includeLocationData: includeLocationData ?? this.includeLocationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updatePeriod': updatePeriod,
      'highLimit': highLimit,
      'lowLimit': lowLimit,
      'sensorGain': sensorGain,
      'includeLocationData': includeLocationData,
    };
  }

  factory GyroscopeConfig.fromJson(Map<String, dynamic> json) {
    return GyroscopeConfig(
      updatePeriod: json['updatePeriod'] ?? 1000,
      highLimit: json['highLimit'] ?? 200,
      lowLimit: json['lowLimit'] ?? 200,
      sensorGain: json['sensorGain'] ?? 1,
      includeLocationData: json['includeLocationData'] ?? true,
    );
  }
}
