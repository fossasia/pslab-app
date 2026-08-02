class OscilloscopeConfig {
  static const int defaultBufferSize = 5;

  final bool includeLocationData;
  final bool bufferOverlayEnabled;
  final int bufferSize;

  const OscilloscopeConfig({
    this.includeLocationData = true,
    this.bufferOverlayEnabled = false,
    this.bufferSize = defaultBufferSize,
  });

  OscilloscopeConfig copyWith({
    bool? includeLocationData,
    bool? bufferOverlayEnabled,
    int? bufferSize,
  }) {
    return OscilloscopeConfig(
      includeLocationData: includeLocationData ?? this.includeLocationData,
      bufferOverlayEnabled: bufferOverlayEnabled ?? this.bufferOverlayEnabled,
      bufferSize: bufferSize ?? this.bufferSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includeLocationData': includeLocationData,
      'bufferOverlayEnabled': bufferOverlayEnabled,
      'bufferSize': bufferSize,
    };
  }

  factory OscilloscopeConfig.fromJson(Map<String, dynamic> json) {
    return OscilloscopeConfig(
      includeLocationData: json['includeLocationData'] ?? true,
      bufferOverlayEnabled: json['bufferOverlayEnabled'] ?? false,
      bufferSize: json['bufferSize'] ?? defaultBufferSize,
    );
  }
}
