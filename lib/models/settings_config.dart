class SettingsConfig {
  final bool autoStart;
  final String exportFormat;
  final String languageCode;

  const SettingsConfig({
    this.autoStart = true,
    this.exportFormat = 'CSV',
    this.languageCode = 'en',
  });

  SettingsConfig copyWith({
    bool? autoStart,
    String? exportFormat,
    String? languageCode,
  }) {
    return SettingsConfig(
      autoStart: autoStart ?? this.autoStart,
      exportFormat: exportFormat ?? this.exportFormat,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoStart': autoStart,
      'exportFormat': exportFormat,
      'languageCode': languageCode,
    };
  }

  factory SettingsConfig.fromJson(Map<String, dynamic> json) {
    return SettingsConfig(
      autoStart: json['autoStart'] ?? true,
      exportFormat: json['exportFormat'] ?? 'CSV',
      languageCode: json['languageCode'] ?? 'en',
    );
  }
}
