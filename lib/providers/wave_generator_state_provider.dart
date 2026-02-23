import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/others/wave_generator_constants.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/wave_generator_config_provider.dart';

enum WaveConst {
  waveType,
  wave1,
  wave2,
  sqr1,
  sqr2,
  sqr3,
  sqr4,
  frequency,
  phase,
  duty,
  sine,
  triangular,
  square,
  pwm,
}

enum WaveData {
  freqMin(10),
  dutyMin(0),
  phaseMin(0),
  freqMax(5000),
  phaseMax(360),
  dutyMax(100);

  final int value;
  const WaveData(this.value);

  int get getValue => value;
}

class WaveGeneratorStateProvider extends ChangeNotifier {
  WaveGeneratorConfigProvider? _configProvider;
  static final int sin = 1;
  static final int triangular = 2;
  static final int pwm = 3;

  late WaveConst? selectedAnalogWave;

  late WaveConst? selectedDigitalWave;

  late WaveConst? propSelected;

  late WaveGeneratorConstants waveGeneratorConstants;

  late List<List<FlSpot>> waveData;

  late ScienceLab _scienceLab;

  List<List<dynamic>> _recordedData = [];

  Position? currentPosition;

  WaveGeneratorStateProvider() {
    selectedAnalogWave = WaveConst.wave1;

    selectedDigitalWave = WaveConst.sqr1;

    _scienceLab = getIt.get<ScienceLab>();

    propSelected = null;

    waveGeneratorConstants = WaveGeneratorConstants();

    waveData = [];
  }

  void setConfigProvider(WaveGeneratorConfigProvider configProvider) {
    _configProvider = configProvider;
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      logger.w('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        logger.w('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      logger.w(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
      return;
    }

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }

  void setAnalogSelectedWave(WaveConst wave) {
    selectedAnalogWave = wave;
    propSelected = null;
    previewWave();
    notifyListeners();
  }

  void setDigitalSelectedWave(WaveConst wave) {
    selectedDigitalWave = wave;
    propSelected = null;
    previewWave();
    notifyListeners();
  }

  void setPropSelected(WaveConst wave) {
    propSelected = wave;
    previewWave();
    notifyListeners();
  }

  void setAnalogWaveType(int waveType) {
    waveGeneratorConstants.wave[selectedAnalogWave]?[WaveConst.waveType] =
        waveType;
    previewWave();
    notifyListeners();
  }

  Future<void> setValue(int value) async {
    if (waveGeneratorConstants.modeSelected == WaveConst.square) {
      waveGeneratorConstants.wave[selectedAnalogWave]?[propSelected!] = value;
    } else {
      if (propSelected == WaveConst.frequency) {
        waveGeneratorConstants.wave[WaveConst.sqr1]?[propSelected!] = value;
      } else {
        waveGeneratorConstants.wave[selectedDigitalWave]?[propSelected!] =
            value;
      }
    }
    previewWave();
    await setWave();
    notifyListeners();
  }

  Future<void> setWave() async {
    double freq1 = waveGeneratorConstants
        .wave[WaveConst.wave1]![WaveConst.frequency]!
        .toDouble();
    double freq2 = waveGeneratorConstants
        .wave[WaveConst.wave2]![WaveConst.frequency]!
        .toDouble();
    double phase = waveGeneratorConstants
        .wave[WaveConst.wave2]![WaveConst.phase]!
        .toDouble();

    String waveType1 =
        waveGeneratorConstants.wave[WaveConst.wave1]![WaveConst.waveType]! ==
            sin
        ? "sine"
        : "tria";
    String waveType2 =
        waveGeneratorConstants.wave[WaveConst.wave2]![WaveConst.waveType]! ==
            sin
        ? "sine"
        : "tria";

    if (_scienceLab.isConnected()) {
      if (waveGeneratorConstants.modeSelected == WaveConst.square) {
        if (phase == WaveData.phaseMin.getValue) {
          await _scienceLab.setSI1(freq1, waveType1);
          await _scienceLab.setSI2(freq2, waveType2);
        } else {
          await _scienceLab.setWaves(freq1, phase, freq2);
        }
      } else {
        double freqSqr1 = waveGeneratorConstants
            .wave[WaveConst.sqr1]![WaveConst.frequency]!
            .toDouble();
        double dutySqr1 =
            waveGeneratorConstants.wave[WaveConst.sqr1]![WaveConst.duty]!
                .toDouble() /
            100;
        double dutySqr2 =
            waveGeneratorConstants.wave[WaveConst.sqr2]![WaveConst.duty]!
                .toDouble() /
            100;
        double phaseSqr2 =
            waveGeneratorConstants.wave[WaveConst.sqr2]![WaveConst.phase]!
                .toDouble() /
            360;
        double dutySqr3 =
            waveGeneratorConstants.wave[WaveConst.sqr3]![WaveConst.duty]!
                .toDouble() /
            100;
        double phaseSqr3 =
            waveGeneratorConstants.wave[WaveConst.sqr3]![WaveConst.phase]!
                .toDouble() /
            360;
        double dutySqr4 =
            waveGeneratorConstants.wave[WaveConst.sqr4]![WaveConst.duty]!
                .toDouble() /
            100;
        double phaseSqr4 =
            waveGeneratorConstants.wave[WaveConst.sqr4]![WaveConst.phase]!
                .toDouble() /
            360;

        await _scienceLab.sqrPWM(
          freqSqr1,
          dutySqr1,
          phaseSqr2,
          dutySqr2,
          phaseSqr3,
          dutySqr3,
          phaseSqr4,
          dutySqr4,
          false,
        );
      }
    }
  }

  Future<void> incrementValue() async {
    int min, max;
    switch (propSelected) {
      case WaveConst.frequency:
        min = WaveData.freqMin.getValue;
        max = WaveData.freqMax.getValue;
        break;
      case WaveConst.phase:
        min = WaveData.phaseMin.getValue;
        max = WaveData.phaseMax.getValue;
        break;
      case WaveConst.duty:
        min = WaveData.dutyMin.getValue;
        max = WaveData.dutyMax.getValue;
        break;
      default:
        return;
    }

    int current = waveGeneratorConstants.modeSelected == WaveConst.square
        ? (waveGeneratorConstants.wave[selectedAnalogWave]?[propSelected!] ??
              min)
        : propSelected == WaveConst.frequency
        ? (waveGeneratorConstants.wave[WaveConst.sqr1]?[propSelected!] ?? min)
        : (waveGeneratorConstants.wave[selectedDigitalWave]?[propSelected!] ??
              min);

    if (current < max) await setValue(current + 1);
  }

  Future<void> decrementValue() async {
    int min;
    switch (propSelected) {
      case WaveConst.frequency:
        min = WaveData.freqMin.getValue;
        break;
      case WaveConst.phase:
        min = WaveData.phaseMin.getValue;
        break;
      case WaveConst.duty:
        min = WaveData.dutyMin.getValue;
        break;
      default:
        return;
    }

    int current = waveGeneratorConstants.modeSelected == WaveConst.square
        ? (waveGeneratorConstants.wave[selectedAnalogWave]?[propSelected!] ??
              min)
        : propSelected == WaveConst.frequency
        ? (waveGeneratorConstants.wave[WaveConst.sqr1]?[propSelected!] ?? min)
        : (waveGeneratorConstants.wave[selectedDigitalWave]?[propSelected!] ??
              min);

    if (current > min) await setValue(current - 1);
  }

  void previewWave() {
    waveData.clear();
    List<FlSpot> samplePoints = getSamplePoints(false);
    List<FlSpot> referencePoints = getSamplePoints(true);
    waveData.add(referencePoints);
    waveData.add(samplePoints);
    notifyListeners();
  }

  List<FlSpot> getSamplePoints(bool isReference) {
    List<FlSpot> entries = [];
    if (waveGeneratorConstants.modeSelected == WaveConst.pwm) {
      double freq = waveGeneratorConstants
          .wave[WaveConst.sqr1]![WaveConst.frequency]!
          .toDouble();
      double duty =
          waveGeneratorConstants.wave[selectedDigitalWave]![WaveConst.duty]!
              .toDouble() /
          100;
      double phase = 0;
      if (selectedDigitalWave != WaveConst.sqr1 && !isReference) {
        phase =
            waveGeneratorConstants.wave[selectedDigitalWave]?[WaveConst.phase]!
                .toDouble() ??
            0;
      }
      for (int i = 0; i < 5000; i++) {
        double t = 2 * pi * freq * i / 1e6 + phase * pi / 180;
        double y;
        if (t % (2 * pi) < 2 * pi * duty) {
          y = 5;
        } else {
          y = -5;
        }
        entries.add(FlSpot(i.toDouble(), y));
      }
    } else {
      double phase = 0;
      int shape =
          waveGeneratorConstants.wave[selectedAnalogWave]![WaveConst.waveType]!;

      double freq = waveGeneratorConstants
          .wave[selectedAnalogWave]![WaveConst.frequency]!
          .toDouble();

      if (selectedAnalogWave != WaveConst.wave1 && !isReference) {
        phase = waveGeneratorConstants.wave[WaveConst.wave2]![WaveConst.phase]!
            .toDouble();
      }
      if (shape == 1) {
        for (int i = 0; i < 5000; i++) {
          double y = 5 * math.sin(2 * pi * (freq / 1e6) * i + phase * pi / 180);
          entries.add(FlSpot(i.toDouble(), y));
        }
      } else {
        for (int i = 0; i < 5000; i++) {
          double y =
              (10 / pi) *
              (math.asin(
                math.sin(2 * pi * (freq / 1e6) * i + phase * pi / 180),
              ));
          entries.add(FlSpot(i.toDouble(), y));
        }
      }
    }
    return entries;
  }

  Map<WaveConst, Map<WaveConst, int>> parseWave(String input) {
    String jsonLike = input.replaceAllMapped(
      RegExp(r'WaveConst\.(\w+)'),
      (m) => '"${m[1]}"',
    );

    jsonLike = jsonLike.replaceAllMapped(
      RegExp(r'(\w+):'),
      (m) => '"${m[1]}":',
    );

    final Map<String, dynamic> raw = jsonDecode(jsonLike);

    return raw.map((key, value) {
      return MapEntry(
        _waveConstFromString(key),
        (value as Map<String, dynamic>).map((k, v) {
          return MapEntry(_waveConstFromString(k), v as int);
        }),
      );
    });
  }

  WaveConst _waveConstFromString(String s) {
    switch (s) {
      case 'wave1':
        return WaveConst.wave1;
      case 'wave2':
        return WaveConst.wave2;
      case 'waveType':
        return WaveConst.waveType;
      case 'sqr1':
        return WaveConst.sqr1;
      case 'sqr2':
        return WaveConst.sqr2;
      case 'sqr3':
        return WaveConst.sqr3;
      case 'sqr4':
        return WaveConst.sqr4;
      case 'frequency':
        return WaveConst.frequency;
      case 'phase':
        return WaveConst.phase;
      case 'duty':
        return WaveConst.duty;
      default:
        return WaveConst.wave1;
    }
  }

  Future<void> loadPlaybackData(List<List<dynamic>> playbackData) async {
    waveGeneratorConstants.wave = parseWave(
      playbackData[playbackData.length - 1][2].toString(),
    );
    previewWave();
    await setWave();
    notifyListeners();
  }

  Future<bool> logData() async {
    if (_configProvider!.config.includeLocationData) {
      await _getCurrentLocation();
    }
    _recordedData = [
      ['Timestamp', 'DateTime', 'Waveform Data', 'Latitude', 'Longitude'],
    ];
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
    _recordedData.add([
      now.millisecondsSinceEpoch.toString(),
      dateFormat.format(now),
      waveGeneratorConstants.wave,
      _configProvider!.config.includeLocationData
          ? currentPosition?.latitude.toString() ?? 0
          : 0,
      _configProvider!.config.includeLocationData
          ? currentPosition?.longitude.toString() ?? 0
          : 0,
    ]);
    return true;
  }

  List<List<dynamic>> get recordedData => _recordedData;

  List<LineChartBarData> createPlots() {
    List<Color> colors = [Colors.white, Colors.white60];
    List<LineChartBarData> plots = [];
    plots.addAll(
      List<LineChartBarData>.generate(waveData.length, (index) {
        return LineChartBarData(
          spots: waveData[index],
          isCurved: false,
          color: colors[index % colors.length],
          barWidth: 1,
          dotData: const FlDotData(show: false),
        );
      }),
    );
    return plots;
  }
}
