class GasSensorConfig {
  final int updatePeriod;
  final String activeGas;
  final bool includeLocationData;

  const GasSensorConfig({
    this.updatePeriod = 1000,
    this.activeGas = 'Raw',
    this.includeLocationData = true,
  });

  GasSensorConfig copyWith({
    int? updatePeriod,
    String? activeGas,
    bool? includeLocationData,
  }) {
    return GasSensorConfig(
      updatePeriod: updatePeriod ?? this.updatePeriod,
      activeGas: activeGas ?? this.activeGas,
      includeLocationData: includeLocationData ?? this.includeLocationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updatePeriod': updatePeriod,
      'activeGas': activeGas,
      'includeLocationData': includeLocationData,
    };
  }

  factory GasSensorConfig.fromJson(Map<String, dynamic> json) {
    return GasSensorConfig(
      updatePeriod: json['updatePeriod'] ?? 1000,
      activeGas: json['activeGas'] ?? 'Raw',
      includeLocationData: json['includeLocationData'] ?? true,
    );
  }
}
