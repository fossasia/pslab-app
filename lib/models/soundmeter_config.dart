class SoundMeterConfig {
  final int updatePeriod;
  final bool includeLocationData;
  const SoundMeterConfig({
    this.updatePeriod = 1000,
    this.includeLocationData = true,
  });
  SoundMeterConfig copyWith({
    int? updatePeriod,
    bool? includeLocationData,
  }) {
    return SoundMeterConfig(
      updatePeriod: updatePeriod ?? this.updatePeriod,
      includeLocationData: includeLocationData ?? this.includeLocationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updatePeriod': updatePeriod,
      'includeLocationData': includeLocationData,
    };
  }

  factory SoundMeterConfig.fromJson(Map<String, dynamic> json) {
    return SoundMeterConfig(
      updatePeriod: json['updatePeriod'] ?? 1000,
      includeLocationData: json['includeLocationData'] ?? true,
    );
  }
}
