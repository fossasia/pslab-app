import 'dart:math';

/// Formats a recording length for display (e.g. "1 hr 2 min 3 sec").
String formatRecordingDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  final parts = <String>[];
  if (hours > 0) {
    parts.add('$hours hr');
  }
  if (minutes > 0) {
    parts.add('$minutes min');
  }
  if (seconds > 0 || parts.isEmpty) {
    parts.add('$seconds sec');
  }
  return parts.join(' ');
}

Duration? durationFromMetadataMilliseconds(dynamic value) {
  final ms = int.tryParse(value.toString());
  if (ms == null || ms < 0) {
    return null;
  }
  return Duration(milliseconds: ms);
}

/// Reads duration from saved file rows (metadata row or timestamp column).
Duration? computeRecordingDurationFromData(List<List<dynamic>> data) {
  if (data.isEmpty) {
    return null;
  }

  if (data[0].isNotEmpty) {
    final fromMeta = durationFromMetadataMilliseconds(
        data[0].length >= 4 ? data[0][3] : null);
    if (fromMeta != null) {
      return fromMeta;
    }
  }

  int headerIndex = -1;
  int timestampColumn = -1;
  for (int i = 0; i < data.length; i++) {
    final row = data[i];
    if (row.isEmpty) {
      continue;
    }
    for (int j = 0; j < row.length; j++) {
      if (row[j].toString().toLowerCase() == 'timestamp') {
        headerIndex = i;
        timestampColumn = j;
        break;
      }
    }
    if (headerIndex >= 0) {
      break;
    }
  }

  if (headerIndex < 0 || timestampColumn < 0) {
    return null;
  }

  double? minTimestamp;
  double? maxTimestamp;
  for (int i = headerIndex + 1; i < data.length; i++) {
    final row = data[i];
    if (row.isEmpty || row.length <= timestampColumn) {
      continue;
    }
    final timestamp = double.tryParse(row[timestampColumn].toString());
    if (timestamp == null) {
      continue;
    }
    minTimestamp =
        minTimestamp == null ? timestamp : min(minTimestamp, timestamp);
    maxTimestamp =
        maxTimestamp == null ? timestamp : max(maxTimestamp, timestamp);
  }

  if (minTimestamp == null || maxTimestamp == null) {
    return null;
  }

  final deltaMs = (maxTimestamp - minTimestamp).round();
  if (deltaMs < 0) {
    return null;
  }
  return Duration(milliseconds: deltaMs);
}
