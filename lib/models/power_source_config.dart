class PowerSourceConfig {
  final int loggingInterval;
  final bool includeLocationData;

  const PowerSourceConfig({
    this.loggingInterval = 1000,
    this.includeLocationData = true,
  });

  PowerSourceConfig copyWith({
    bool? includeLocationData,
    int? loggingInterval,
  }) {
    return PowerSourceConfig(
      includeLocationData: includeLocationData ?? this.includeLocationData,
      loggingInterval: loggingInterval ?? this.loggingInterval,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includeLocationData': includeLocationData,
      'loggingInterval': loggingInterval,
    };
  }

  factory PowerSourceConfig.fromJson(Map<String, dynamic> json) {
    return PowerSourceConfig(
      includeLocationData: json['includeLocationData'] ?? true,
      loggingInterval: json['loggingInterval'] ?? 1000,
    );
  }
}
