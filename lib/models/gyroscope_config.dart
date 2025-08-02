class GyroscopeConfig {
  final int updatePeriod;
  final int highLimit;
  final int sensorGain;
  final bool includeLocationData;

  const GyroscopeConfig({
    this.updatePeriod = 1000,
    this.highLimit = 20,
    this.sensorGain = 1,
    this.includeLocationData = true,
  });

  GyroscopeConfig copyWith({
    int? updatePeriod,
    int? highLimit,
    int? sensorGain,
    bool? includeLocationData,
  }) {
    return GyroscopeConfig(
      updatePeriod: updatePeriod ?? this.updatePeriod,
      highLimit: highLimit ?? this.highLimit,
      sensorGain: sensorGain ?? this.sensorGain,
      includeLocationData: includeLocationData ?? this.includeLocationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updatePeriod': updatePeriod,
      'highLimit': highLimit,
      'sensorGain': sensorGain,
      'includeLocationData': includeLocationData,
    };
  }

  factory GyroscopeConfig.fromJson(Map<String, dynamic> json) {
    return GyroscopeConfig(
      updatePeriod: json['updatePeriod'] ?? 1000,
      highLimit: json['highLimit'] ?? 20,
      sensorGain: json['sensorGain'] ?? 1,
      includeLocationData: json['includeLocationData'] ?? true,
    );
  }
}
