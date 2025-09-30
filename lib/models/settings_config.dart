class SettingsConfig {
  final bool autoStart;
  final String exportFormat;
  final String theme;

  const SettingsConfig({
    this.autoStart = true,
    this.exportFormat = 'CSV',
    this.theme = 'Light',
  });

  SettingsConfig copyWith({
    bool? autoStart,
    String? exportFormat,
    String? theme,
  }) {
    return SettingsConfig(
      autoStart: autoStart ?? this.autoStart,
      exportFormat: exportFormat ?? this.exportFormat,
      theme: theme ?? this.theme,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoStart': autoStart,
      'exportFormat': exportFormat,
      'theme': theme,
    };
  }

  factory SettingsConfig.fromJson(Map<String, dynamic> json) {
    return SettingsConfig(
      autoStart: json['autoStart'] ?? true,
      exportFormat: json['exportFormat'] ?? 'CSV',
      theme: json['theme'] ?? 'Light',
    );
  }
}
