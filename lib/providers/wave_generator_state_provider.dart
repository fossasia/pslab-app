import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';
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
  sawtooth
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
  static final int sawtooth = 4;

  late WaveConst? selectedAnalogWave;

  late WaveConst? selectedDigitalWave;

  late WaveConst? propSelected;

  late WaveGeneratorConstants waveGeneratorConstants;

  late List<List<FlSpot>> waveData;

  late ScienceLab _scienceLab;

  List<List<dynamic>> _recordedData = [];

  Position? currentPosition;

  AudioStream? _audioStream;

  bool isPlayingSound = false;

  double _audioAngle = 0.0;

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

  void toggleSound() {
    if (isPlayingSound) {
      isPlayingSound = false;

      _stopAudioStream();
    } else {
      isPlayingSound = true;

      _startAudioStream();
    }

    notifyListeners();
  }

  Future<void> _startAudioStream() async {
    _audioStream = getAudioStream();

    _audioStream!.init(bufferMilliSec: 1000, channels: 1, sampleRate: 44100);

    _audioStream!.resume();

    await Future.delayed(const Duration(milliseconds: 100));

    _audioAngle = 0.0;

    final int bufferSize = 4096;

    final double bufferDurationMs = (bufferSize / 44100.0) * 1000.0;

    final List<Float32List> bufferPool =
        List.generate(5, (_) => Float32List(bufferSize));

    int poolIndex = 0;

    double generatedAudioMs = 0.0;

    Stopwatch stopwatch = Stopwatch()..start();

    for (int i = 0; i < 3; i++) {
      final buffer = bufferPool[poolIndex];

      poolIndex = (poolIndex + 1) % bufferPool.length;

      _fillAudioBuffer(buffer, bufferSize);

      _audioStream!.push(buffer);

      generatedAudioMs += bufferDurationMs;
    }

    while (isPlayingSound) {
      double elapsedRealTimeMs = stopwatch.elapsedMilliseconds.toDouble();

      if (generatedAudioMs - elapsedRealTimeMs < 300.0) {
        final buffer = bufferPool[poolIndex];

        poolIndex = (poolIndex + 1) % bufferPool.length;

        _fillAudioBuffer(buffer, bufferSize);

        _audioStream!.push(buffer);

        generatedAudioMs += bufferDurationMs;
      } else {
        await Future.delayed(const Duration(milliseconds: 20));
      }

      if (elapsedRealTimeMs > generatedAudioMs) {
        generatedAudioMs = elapsedRealTimeMs;
      }
    }
  }

  void _fillAudioBuffer(Float32List buffer, int bufferSize) {
    double frequency;

    double duty = 0.5;

    if (waveGeneratorConstants.modeSelected == WaveConst.square) {
      frequency = waveGeneratorConstants
          .wave[selectedAnalogWave]![WaveConst.frequency]!
          .toDouble();
    } else {
      frequency = waveGeneratorConstants
          .wave[WaveConst.sqr1]![WaveConst.frequency]!
          .toDouble();

      int currentDuty =
          waveGeneratorConstants.wave[selectedDigitalWave]![WaveConst.duty] ??
              50;

      duty = currentDuty / 100.0;
    }

    if (frequency <= 0) frequency = 1;

    double increment = (2 * math.pi * frequency) / 44100.0;

    const double volume = 0.15;

    for (int i = 0; i < bufferSize; i++) {
      if (waveGeneratorConstants.modeSelected == WaveConst.pwm) {
        buffer[i] = (_audioAngle < (2 * math.pi * duty)) ? volume : -volume;
      } else {
        double safeSin = math.sin(_audioAngle).clamp(-1.0, 1.0);
        double sample = safeSin;
        int currentWaveType = waveGeneratorConstants
            .wave[selectedAnalogWave]![WaveConst.waveType]!;

        if (currentWaveType == triangular) {
          sample = (2 / math.pi) * math.asin(safeSin);
        } else if (currentWaveType == sawtooth) {
          sample = (_audioAngle / math.pi) - 1.0;
        }

        buffer[i] = sample * volume;
      }

      _audioAngle += increment;

      if (_audioAngle >= 2 * math.pi) {
        _audioAngle -= 2 * math.pi;
      }
    }
  }

  void _stopAudioStream() {
    if (_audioStream != null) {
      _audioStream!.uninit();

      _audioStream = null;
    }
  }

  @override
  void dispose() {
    _stopAudioStream();
    isPlayingSound = false;
    super.dispose();
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
          'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    currentPosition =
        await Geolocator.getCurrentPosition(locationSettings: locationSettings);
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

    int shape1 =
        waveGeneratorConstants.wave[WaveConst.wave1]![WaveConst.waveType]!;
    int shape2 =
        waveGeneratorConstants.wave[WaveConst.wave2]![WaveConst.waveType]!;

    String waveType1 =
        shape1 == sin ? "sine" : (shape1 == triangular ? "tria" : "sawtooth");
    String waveType2 =
        shape2 == sin ? "sine" : (shape2 == triangular ? "tria" : "sawtooth");

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
        double dutySqr1 = waveGeneratorConstants
                .wave[WaveConst.sqr1]![WaveConst.duty]!
                .toDouble() /
            100;
        double dutySqr2 = waveGeneratorConstants
                .wave[WaveConst.sqr2]![WaveConst.duty]!
                .toDouble() /
            100;
        double phaseSqr2 = waveGeneratorConstants
                .wave[WaveConst.sqr2]![WaveConst.phase]!
                .toDouble() /
            360;
        double dutySqr3 = waveGeneratorConstants
                .wave[WaveConst.sqr3]![WaveConst.duty]!
                .toDouble() /
            100;
        double phaseSqr3 = waveGeneratorConstants
                .wave[WaveConst.sqr3]![WaveConst.phase]!
                .toDouble() /
            360;
        double dutySqr4 = waveGeneratorConstants
                .wave[WaveConst.sqr4]![WaveConst.duty]!
                .toDouble() /
            100;
        double phaseSqr4 = waveGeneratorConstants
                .wave[WaveConst.sqr4]![WaveConst.phase]!
                .toDouble() /
            360;

        await _scienceLab.sqrPWM(freqSqr1, dutySqr1, phaseSqr2, dutySqr2,
            phaseSqr3, dutySqr3, phaseSqr4, dutySqr4, false);
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
            ? (waveGeneratorConstants.wave[WaveConst.sqr1]?[propSelected!] ??
                min)
            : (waveGeneratorConstants.wave[selectedDigitalWave]
                    ?[propSelected!] ??
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
            ? (waveGeneratorConstants.wave[WaveConst.sqr1]?[propSelected!] ??
                min)
            : (waveGeneratorConstants.wave[selectedDigitalWave]
                    ?[propSelected!] ??
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
      double duty = waveGeneratorConstants
              .wave[selectedDigitalWave]![WaveConst.duty]!
              .toDouble() /
          100;
      double phase = 0;
      if (selectedDigitalWave != WaveConst.sqr1 && !isReference) {
        phase = waveGeneratorConstants.wave[selectedDigitalWave]
                    ?[WaveConst.phase]!
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

      if (shape == sin) {
        for (int i = 0; i < 5000; i++) {
          double y = 5 * math.sin(2 * pi * (freq / 1e6) * i + phase * pi / 180);
          entries.add(FlSpot(i.toDouble(), y));
        }
      } else if (shape == triangular) {
        for (int i = 0; i < 5000; i++) {
          double y = (10 / pi) *
              (math.asin(
                  math.sin(2 * pi * (freq / 1e6) * i + phase * pi / 180)));
          entries.add(FlSpot(i.toDouble(), y));
        }
      } else if (shape == sawtooth) {
        for (int i = 0; i < 5000; i++) {
          double t = 2 * pi * (freq / 1e6) * i + phase * pi / 180;
          double y = 5 * (((t % (2 * pi)) / pi) - 1.0);
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
      case 'sine':
        return WaveConst.sine;
      case 'triangular':
        return WaveConst.triangular;
      case 'square':
        return WaveConst.square;
      case 'pwm':
        return WaveConst.pwm;
      case 'sawtooth':
        return WaveConst.sawtooth;
      default:
        return WaveConst.wave1;
    }
  }

  Future<void> loadPlaybackData(List<List<dynamic>> playbackData) async {
    waveGeneratorConstants.wave =
        parseWave(playbackData[playbackData.length - 1][2].toString());
    previewWave();
    await setWave();
    notifyListeners();
  }

  Future<bool> logData() async {
    if (_configProvider!.config.includeLocationData) {
      await _getCurrentLocation();
    }
    _recordedData = [
      ['Timestamp', 'DateTime', 'Waveform Data', 'Latitude', 'Longitude']
    ];
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
    _recordedData.add(
      [
        now.millisecondsSinceEpoch.toString(),
        dateFormat.format(now),
        waveGeneratorConstants.wave,
        _configProvider!.config.includeLocationData
            ? currentPosition?.latitude.toString() ?? 0
            : 0,
        _configProvider!.config.includeLocationData
            ? currentPosition?.longitude.toString() ?? 0
            : 0
      ],
    );
    return true;
  }

  List<List<dynamic>> get recordedData => _recordedData;

  List<LineChartBarData> createPlots() {
    List<Color> colors = [Colors.white, Colors.white60];
    List<LineChartBarData> plots = [];
    plots.addAll(
      List<LineChartBarData>.generate(
        waveData.length,
        (index) {
          return LineChartBarData(
            spots: waveData[index],
            isCurved: false,
            color: colors[index % colors.length],
            barWidth: 1,
            dotData: const FlDotData(
              show: false,
            ),
          );
        },
      ),
    );
    return plots;
  }
}
