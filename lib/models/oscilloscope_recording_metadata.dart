import 'dart:convert';

class OscilloscopeRecordingMetadata {
  final DateTime? recordedAt;
  final List<String> enabledChannels;

  final String? range;
  final double? timebase;
  final bool triggerEnabled;
  final String? triggerChannel;
  final String? triggerMode;
  final double? triggerLevel;
  final double? samplingRate; // Hz
  final int? samplesPerFrame;
  final int? sampleCount; // number of recorded frames

  const OscilloscopeRecordingMetadata({
    this.recordedAt,
    this.enabledChannels = const [],
    this.range,
    this.timebase,
    this.triggerEnabled = false,
    this.triggerChannel,
    this.triggerMode,
    this.triggerLevel,
    this.samplingRate,
    this.samplesPerFrame,
    this.sampleCount,
  });

  bool get isEmpty =>
      recordedAt == null &&
      enabledChannels.isEmpty &&
      range == null &&
      timebase == null &&
      triggerMode == null &&
      triggerLevel == null &&
      samplingRate == null &&
      samplesPerFrame == null &&
      sampleCount == null;

  Map<String, dynamic> toJson() => {
        'recordedAt': recordedAt?.toIso8601String(),
        'enabledChannels': enabledChannels,
        'range': range,
        'timebase': timebase,
        'triggerEnabled': triggerEnabled,
        'triggerChannel': triggerChannel,
        'triggerMode': triggerMode,
        'triggerLevel': triggerLevel,
        'samplingRate': samplingRate,
        'samplesPerFrame': samplesPerFrame,
        'sampleCount': sampleCount,
      };

  factory OscilloscopeRecordingMetadata.fromJson(Map<String, dynamic> json) {
    return OscilloscopeRecordingMetadata(
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'].toString())
          : null,
      enabledChannels: json['enabledChannels'] != null
          ? List<String>.from(json['enabledChannels'])
          : const [],
      range: json['range'] as String?,
      timebase: (json['timebase'] as num?)?.toDouble(),
      triggerEnabled: json['triggerEnabled'] == true,
      triggerChannel: json['triggerChannel'] as String?,
      triggerMode: json['triggerMode'] as String?,
      triggerLevel: (json['triggerLevel'] as num?)?.toDouble(),
      samplingRate: (json['samplingRate'] as num?)?.toDouble(),
      samplesPerFrame: (json['samplesPerFrame'] as num?)?.toInt(),
      sampleCount: (json['sampleCount'] as num?)?.toInt(),
    );
  }

  String encode() => base64.encode(utf8.encode(jsonEncode(toJson())));

  static OscilloscopeRecordingMetadata? tryDecode(dynamic cell) {
    if (cell == null) return null;
    try {
      final decoded = utf8.decode(base64.decode(cell.toString()));
      final map = jsonDecode(decoded);
      if (map is Map<String, dynamic>) {
        return OscilloscopeRecordingMetadata.fromJson(map);
      }
    } catch (_) {}
    return null;
  }
}
