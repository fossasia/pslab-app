class MultimeterConfig {
  final int updatePeriod;
  final bool includeLocationData;

  const MultimeterConfig({
    this.updatePeriod = 1000,
    this.includeLocationData = true,
  });

  MultimeterConfig copyWith({int? updatePeriod, bool? includeLocationData}) {
    return MultimeterConfig(
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

  factory MultimeterConfig.fromJson(Map<String, dynamic> json) {
    return MultimeterConfig(
      updatePeriod: json['updatePeriod'] ?? 1000,
      includeLocationData: json['includeLocationData'] ?? true,
    );
  }
}
