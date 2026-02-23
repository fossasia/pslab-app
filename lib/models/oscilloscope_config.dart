class OscilloscopeConfig {
  final bool includeLocationData;

  const OscilloscopeConfig({this.includeLocationData = true});

  OscilloscopeConfig copyWith({bool? includeLocationData}) {
    return OscilloscopeConfig(
      includeLocationData: includeLocationData ?? this.includeLocationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {'includeLocationData': includeLocationData};
  }

  factory OscilloscopeConfig.fromJson(Map<String, dynamic> json) {
    return OscilloscopeConfig(
      includeLocationData: json['includeLocationData'] ?? true,
    );
  }
}
