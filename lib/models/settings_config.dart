class SettingsConfig {
  final bool autoStart;
  final String exportFormat;

  const SettingsConfig({
    this.autoStart = true,
    this.exportFormat = 'CSV',
  });

  SettingsConfig copyWith({
    bool? autoStart,
    String? exportFormat,
  }) {
    return SettingsConfig(
      autoStart: autoStart ?? this.autoStart,
      exportFormat: exportFormat ?? this.exportFormat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoStart': autoStart,
      'exportFormat': exportFormat,
    };
  }

  factory SettingsConfig.fromJson(Map<String, dynamic> json) {
    return SettingsConfig(
      autoStart: json['autoStart'] ?? true,
      exportFormat: json['exportFormat'] ?? 'CSV',
    );
  }
}
