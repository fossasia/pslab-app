import 'dart:math';
import 'package:fl_chart/fl_chart.dart';

import 'logger_service.dart';

class InstrumentSeries {
  final String name;
  final double mean;
  final double max;
  final double min;
  final double peakToPeak;
  final double rms;
  final double stdDev;
  final double integral;

  final double lowZonePct;
  final double midZonePct;
  final double highZonePct;

  final List<FlSpot> spots;
  final List<double> rawValues;

  InstrumentSeries({
    required this.name,
    required this.mean,
    required this.max,
    required this.min,
    required this.peakToPeak,
    required this.rms,
    required this.stdDev,
    required this.integral,
    required this.lowZonePct,
    required this.midZonePct,
    required this.highZonePct,
    required this.spots,
    required this.rawValues,
  });
}

class ScientificDataAnalyzer {
  static Map<String, InstrumentSeries> analyze(
      String instrumentName, List<List<dynamic>> rawData) {
    if (rawData.isEmpty || rawData.length < 2) {
      return {};
    }

    int headerIndex = 0;
    for (int i = 0; i < rawData.length; i++) {
      if (rawData[i].isNotEmpty &&
          rawData[i].first.toString().toLowerCase() == 'timestamp') {
        headerIndex = i;
        break;
      }
    }

    if (headerIndex >= rawData.length - 1) {
      return {};
    }

    final headers = rawData[headerIndex].map((e) => e.toString()).toList();
    final dataRows = rawData.sublist(headerIndex + 1);
    String inst = instrumentName.toLowerCase();

    if (inst == 'wave generator') {
      return _parseWaveGeneratorData(dataRows);
    }

    if (inst == 'oscilloscope' || inst == 'logic analyzer') {
      return _parseOscilloscopeData(dataRows);
    }

    Map<String, InstrumentSeries> results = {};
    List<int> dataColumns = _getDataColumnIndices(inst, headers);

    for (int colIndex in dataColumns) {
      if (colIndex >= headers.length) {
        continue;
      }

      String rawColName = headers[colIndex];
      String cleanName = rawColName.toUpperCase();

      if (cleanName == 'READINGS' || cleanName == 'WAVEFORM DATA') {
        cleanName = 'SENSOR SIGNAL';
      } else if (cleanName == 'READINGSX') {
        cleanName = 'X-AXIS';
      } else if (cleanName == 'READINGSY') {
        cleanName = 'Y-AXIS';
      } else if (cleanName == 'READINGSZ') {
        cleanName = 'Z-AXIS';
      }

      List<FlSpot> spots = [];
      double? startTime = _parseDouble(dataRows.first[0]);

      if (startTime == null) {
        continue;
      }

      for (int i = 0; i < dataRows.length; i++) {
        if (dataRows[i].length <= colIndex) {
          continue;
        }

        double? time = _parseDouble(dataRows[i][0]);
        double? value = _parseDouble(dataRows[i][colIndex]);

        if (time != null && value != null) {
          double x = (time - startTime) / 1000.0;
          spots.add(FlSpot(x, value));
        }
      }

      if (spots.length > 1) {
        results[rawColName] = _calculateMetricsForSpots(cleanName, spots);
      }
    }
    return results;
  }

  static Map<String, InstrumentSeries> _parseWaveGeneratorData(
      List<List<dynamic>> dataRows) {
    Map<String, InstrumentSeries> results = {};

    if (dataRows.isEmpty) {
      return results;
    }

    List<dynamic> targetRow = dataRows.last;
    if (targetRow.length < 3) {
      return results;
    }

    String configStr = targetRow[2].toString();

    int freq1 = _extractWaveParam(
        configStr, 'WaveConst.wave1', 'WaveConst.frequency', 1000);
    int type1 = _extractWaveParam(
        configStr, 'WaveConst.wave1', 'WaveConst.waveType', 1);

    List<FlSpot> spots1 = _generateMathematicalWave(freq1, type1);
    results['WAVE_1'] = _calculateMetricsForSpots('ANALOG WAVE 1', spots1);

    int freq2 = _extractWaveParam(
        configStr, 'WaveConst.wave2', 'WaveConst.frequency', 1000);
    int type2 = _extractWaveParam(
        configStr, 'WaveConst.wave2', 'WaveConst.waveType', 1);

    List<FlSpot> spots2 = _generateMathematicalWave(freq2, type2);
    results['WAVE_2'] = _calculateMetricsForSpots('ANALOG WAVE 2', spots2);

    return results;
  }

  static int _extractWaveParam(
      String configStr, String waveKey, String paramKey, int defaultVal) {
    int waveIndex = configStr.indexOf(waveKey);
    if (waveIndex == -1) {
      return defaultVal;
    }

    int paramIndex = configStr.indexOf(paramKey, waveIndex);
    if (paramIndex == -1) {
      return defaultVal;
    }

    final match =
        RegExp(r':\s*(\d+)').firstMatch(configStr.substring(paramIndex));
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? defaultVal;
    }

    return defaultVal;
  }

  static List<FlSpot> _generateMathematicalWave(int freq, int type) {
    List<FlSpot> spots = [];
    double frequencyInHz = freq.toDouble();

    if (frequencyInHz <= 0) {
      frequencyInHz = 1;
    }

    for (int i = 0; i < 2000; i++) {
      double t = i / 1000000.0;
      double y = 0;

      if (type == 1) {
        y = 5 * sin(2 * pi * frequencyInHz * t);
      } else if (type == 2) {
        y = (10 / pi) * asin(sin(2 * pi * frequencyInHz * t));
      } else if (type == 4) {
        double phase = 2 * pi * frequencyInHz * t;
        y = 5 * (((phase % (2 * pi)) / pi) - 1.0);
      } else {
        y = 5 * sin(2 * pi * frequencyInHz * t);
      }

      spots.add(FlSpot(i.toDouble(), y));
    }
    return spots;
  }

  static Map<String, InstrumentSeries> _parseOscilloscopeData(
      List<List<dynamic>> dataRows) {
    Map<String, InstrumentSeries> results = {};

    if (dataRows.isEmpty) {
      return results;
    }

    double? firstTimestamp = _parseDouble(dataRows.first[0]);
    if (firstTimestamp == null) {
      return results;
    }

    Map<String, List<double>> channelRawValues = {};
    Map<String, List<FlSpot>> channelSpots = {};

    for (var row in dataRows) {
      if (row.length < 4) {
        continue;
      }

      double? currentTimestamp = _parseDouble(row[0]);
      if (currentTimestamp == null) {
        continue;
      }

      double timeOffsetSec = (currentTimestamp - firstTimestamp) / 1000.0;

      String spotsStr = row[2].toString();
      String channelsStr = row[3].toString();

      List<List<FlSpot>> allSpots = _parseOscilloscopeSpots(spotsStr);
      List<String> channelNames = _parseChannelsList(channelsStr);

      for (int i = 0; i < channelNames.length; i++) {
        if (i >= allSpots.length) {
          break;
        }

        String colName =
            channelNames[i].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

        if (colName.isEmpty) {
          colName = 'CH${i + 1}';
        }

        if (!channelRawValues.containsKey(colName)) {
          channelRawValues[colName] = [];
          channelSpots[colName] = [];
        }

        for (FlSpot spot in allSpots[i]) {
          channelRawValues[colName]!.add(spot.y);
          channelSpots[colName]!.add(FlSpot(timeOffsetSec + spot.x, spot.y));
        }
      }
    }

    channelSpots.forEach((colName, spots) {
      if (spots.length > 1) {
        List<FlSpot> optimizedSpots = _downsample(spots, 1000);
        results[colName] = _calculateMetricsForSpots(
            colName, optimizedSpots, channelRawValues[colName]);
      }
    });

    return results;
  }

  static List<FlSpot> _downsample(List<FlSpot> spots, int targetCount) {
    if (spots.length <= targetCount) {
      return spots;
    }

    List<FlSpot> result = [];
    double step = spots.length / targetCount;
    for (double i = 0; i < spots.length; i += step) {
      result.add(spots[i.floor()]);
    }
    return result;
  }

  static List<List<FlSpot>> _parseOscilloscopeSpots(String data) {
    List<List<FlSpot>> result = [];
    try {
      String clean = data.trim();
      if (clean.startsWith('[[') && clean.endsWith(']]')) {
        clean = clean.substring(2, clean.length - 2);
      }

      if (clean.isEmpty) {
        return [];
      }

      List<String> groups = clean.split(RegExp(r'\],\s*\['));

      for (String group in groups) {
        List<FlSpot> currentChannelSpots = [];
        Iterable<RegExpMatch> matches =
            RegExp(r'-?\d+\.?\d*(?:[eE][+-]?\d+)?').allMatches(group);

        List<double> numbers = [];
        for (final m in matches) {
          double? val = double.tryParse(m.group(0)!);
          if (val != null) {
            numbers.add(val);
          }
        }

        for (int i = 0; i < numbers.length - 1; i += 2) {
          currentChannelSpots.add(FlSpot(numbers[i], numbers[i + 1]));
        }

        if (currentChannelSpots.isNotEmpty) {
          result.add(currentChannelSpots);
        }
      }
    } catch (e) {
      logger.d('_parseOscilloscopeSpots EXCEPTION: $e');
    }
    return result;
  }

  static List<String> _parseChannelsList(String input) {
    String clean = input.trim();
    if (clean.startsWith('[') && clean.endsWith(']')) {
      clean = clean.substring(1, clean.length - 1);
    }
    return clean
        .split(',')
        .map((s) => s.replaceAll('"', '').replaceAll("'", "").trim())
        .toList();
  }

  static InstrumentSeries _calculateMetricsForSpots(
      String name, List<FlSpot> spots,
      [List<double>? providedRawValues]) {
    spots.sort((a, b) => a.x.compareTo(b.x));
    List<double> rawValues =
        providedRawValues ?? spots.map((s) => s.y).toList();

    double sum = 0, sumSq = 0;
    double maxVal = double.negativeInfinity;
    double minVal = double.infinity;
    int n = rawValues.length;

    for (double y in rawValues) {
      sum += y;
      sumSq += (y * y);
      if (y > maxVal) {
        maxVal = y;
      }
      if (y < minVal) {
        minVal = y;
      }
    }

    double mean = sum / n;
    double rms = sqrt(sumSq / n);
    double peakToPeak = maxVal - minVal;

    double variance = 0;
    for (double val in rawValues) {
      variance += pow(val - mean, 2);
    }
    double stdDev = sqrt(variance / n);

    double integral = 0;
    for (int j = 1; j < spots.length; j++) {
      double dt = spots[j].x - spots[j - 1].x;
      double avgY = (spots[j].y + spots[j - 1].y) / 2.0;
      integral += avgY * dt;
    }

    double range = peakToPeak == 0 ? 1 : peakToPeak;
    double t1 = minVal + (range * 0.33);
    double t2 = minVal + (range * 0.66);
    int lowC = 0, midC = 0, highC = 0;

    for (double val in rawValues) {
      if (val <= t1) {
        lowC++;
      } else if (val >= t2) {
        highC++;
      } else {
        midC++;
      }
    }

    return InstrumentSeries(
      name: name,
      mean: mean,
      max: maxVal,
      min: minVal,
      peakToPeak: peakToPeak,
      rms: rms,
      stdDev: stdDev,
      integral: integral,
      lowZonePct: (lowC / n) * 100,
      midZonePct: (midC / n) * 100,
      highZonePct: (highC / n) * 100,
      spots: spots,
      rawValues: rawValues,
    );
  }

  static List<int> _getDataColumnIndices(
      String instrument, List<String> headers) {
    final inst = instrument.toLowerCase();

    if (inst == 'accelerometer' || inst == 'gyroscope') {
      return [2, 3, 4];
    }

    if (inst == 'compass' || inst == 'power source') {
      return [2, 3, 4, 5];
    }

    if (inst == 'barometer') {
      return [2, 3];
    }

    return [2];
  }

  static double? _parseDouble(dynamic val) {
    if (val is num) {
      return val.toDouble();
    }

    if (val is String) {
      return double.tryParse(val);
    }

    return null;
  }
}
