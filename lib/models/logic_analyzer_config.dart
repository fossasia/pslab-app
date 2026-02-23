class LogicAnalyzerConfig {
  final bool includeLocationData;

  const LogicAnalyzerConfig({this.includeLocationData = true});

  LogicAnalyzerConfig copyWith({bool? includeLocationData}) {
    return LogicAnalyzerConfig(
      includeLocationData: includeLocationData ?? this.includeLocationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {'includeLocationData': includeLocationData};
  }

  factory LogicAnalyzerConfig.fromJson(Map<String, dynamic> json) {
    return LogicAnalyzerConfig(
      includeLocationData: json['includeLocationData'] ?? true,
    );
  }
}
