class WaveGeneratorConfig {
  final bool includeLocationData;

  const WaveGeneratorConfig({this.includeLocationData = true});

  WaveGeneratorConfig copyWith({bool? includeLocationData}) {
    return WaveGeneratorConfig(
      includeLocationData: includeLocationData ?? this.includeLocationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {'includeLocationData': includeLocationData};
  }

  factory WaveGeneratorConfig.fromJson(Map<String, dynamic> json) {
    return WaveGeneratorConfig(
      includeLocationData: json['includeLocationData'] ?? true,
    );
  }
}
