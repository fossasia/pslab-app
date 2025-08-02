class SoundMeterConfig {
  final bool includeLocationData;
  const SoundMeterConfig({
    this.includeLocationData = true,
  });
  SoundMeterConfig copyWith({
    bool? includeLocationData,
  }) {
    return SoundMeterConfig(
      includeLocationData: includeLocationData ?? this.includeLocationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includeLocationData': includeLocationData,
    };
  }

  factory SoundMeterConfig.fromJson(Map<String, dynamic> json) {
    return SoundMeterConfig(
      includeLocationData: json['includeLocationData'] ?? true,
    );
  }
}
