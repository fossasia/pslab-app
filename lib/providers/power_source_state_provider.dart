import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/power_source_config_provider.dart';

enum Pin { pv1, pv2, pv3, pcs }

class PowerSourceStateProvider extends ChangeNotifier {
  late PowerSourceConfigProvider _configProvider;
  late double voltagePV1;
  late double voltagePV2;
  late double voltagePV3;
  late double currentPCS;

  late List<double> rangePV1;
  late List<double> rangePV2;
  late List<double> rangePV3;
  late List<double> rangePCS;

  late double step;

  late ScienceLab _scienceLab;

  bool _isPlayingBack = false;
  bool get isPlayingBack => _isPlayingBack;
  bool _isPlaybackPaused = false;
  bool get isPlaybackPaused => _isPlaybackPaused;
  List<List<dynamic>>? _playbackData;
  int _playbackIndex = 0;
  Timer? _playbackTimer;
  Timer? _loggingTimer;
  Function? onPlaybackEnd;
  late bool _isRecording;
  bool get isRecording => _isRecording;

  List<List<dynamic>> _recordedData = [];

  Position? currentPosition;
  StreamSubscription? _locationStream;

  PowerSourceStateProvider() {
    voltagePV1 = -5.00;
    voltagePV2 = -3.30;
    voltagePV3 = 0.00;
    currentPCS = 0.00;

    rangePV1 = [-5.00, 5.00];
    rangePV2 = [-3.30, 3.30];
    rangePV3 = [0.00, 3.30];
    rangePCS = [0.00, 3.30];

    step = 0.01;

    _scienceLab = getIt.get<ScienceLab>();
    _isRecording = false;
  }

  void setConfigProvider(PowerSourceConfigProvider powerSourceConfigProvider) {
    _configProvider = powerSourceConfigProvider;
  }

  Future<void> _startGeoLocationUpdates() async {
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

    _locationStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).listen((Position position) {
          currentPosition = position;
        });
  }

  double valueToIndex(double value, Pin pin) {
    List<double> range;
    int sections;
    switch (pin) {
      case Pin.pv1:
        range = rangePV1;
        sections = 1000;
        break;
      case Pin.pv2:
        range = rangePV2;
        sections = 660;
        break;
      case Pin.pv3:
        range = rangePV3;
        sections = 330;
        break;
      case Pin.pcs:
        range = rangePCS;
        sections = 330;
        break;
    }
    final clampedValue = value.clamp(range[0], range[1]);
    return ((clampedValue - range[0]) / (range[1] - range[0])) * sections;
  }

  double indexToValue(double index, Pin pin) {
    List<double> range;
    int sections;
    switch (pin) {
      case Pin.pv1:
        range = rangePV1;
        sections = 1000;
        break;
      case Pin.pv2:
        range = rangePV2;
        sections = 660;
        break;
      case Pin.pv3:
        range = rangePV3;
        sections = 330;
        break;
      case Pin.pcs:
        range = rangePCS;
        sections = 330;
        break;
    }
    final clampedIndex = index.clamp(0, sections);
    return (clampedIndex / sections) * (range[1] - range[0]) + range[0];
  }

  Future<void> setPV1(double value) async {
    final clampedValue = value.clamp(rangePV1[0], rangePV1[1]);
    voltagePV1 = clampedValue;
    voltagePV3 = (3.3 / 2) * (1 + (voltagePV1 / 5.0));
    await _scienceLab.setPV1(voltagePV1);
    notifyListeners();
  }

  Future<void> setPV2(double value) async {
    final clampedValue = value.clamp(rangePV2[0], rangePV2[1]);
    voltagePV2 = clampedValue;
    currentPCS = (3.3 - voltagePV2) / 2;
    await _scienceLab.setPV2(voltagePV2);
    notifyListeners();
  }

  Future<void> setPV3(double value) async {
    final clampedValue = value.clamp(rangePV3[0], rangePV3[1]);
    voltagePV3 = clampedValue;
    voltagePV1 = 5 * (2 * voltagePV3 / 3.3 - 1);
    await _scienceLab.setPV3(voltagePV3);
    notifyListeners();
  }

  Future<void> setPCS(double value) async {
    final clampedValue = value.clamp(rangePCS[0], rangePCS[1]);
    currentPCS = clampedValue;
    voltagePV2 = 3.3 - 2 * currentPCS;
    await _scienceLab.setPCS(currentPCS);
    notifyListeners();
  }

  Future<void> setValue(double value, Pin pin) async {
    switch (pin) {
      case Pin.pv1:
        await setPV1(value);
        break;
      case Pin.pv2:
        await setPV2(value);
        break;
      case Pin.pv3:
        await setPV3(value);
        break;
      case Pin.pcs:
        await setPCS(value);
        break;
    }
  }

  double getValue(Pin pin) {
    switch (pin) {
      case Pin.pv1:
        return voltagePV1;
      case Pin.pv2:
        return voltagePV2;
      case Pin.pv3:
        return voltagePV3;
      case Pin.pcs:
        return currentPCS;
    }
  }

  void _startPlaybackTimer() {
    if (_playbackIndex >= _playbackData!.length) {
      stopPlayback();
      return;
    }

    final currentRow = _playbackData![_playbackIndex];
    if (currentRow.length > 2) {
      voltagePV1 = double.tryParse(currentRow[2].toString()) ?? 0.00;
      voltagePV2 = double.tryParse(currentRow[3].toString()) ?? 0.00;
      voltagePV3 = double.tryParse(currentRow[4].toString()) ?? 0.00;
      currentPCS = double.tryParse(currentRow[5].toString()) ?? 0.00;
      setValue(voltagePV1, Pin.pv1);
      setValue(voltagePV2, Pin.pv2);
      setValue(voltagePV3, Pin.pv3);
      setValue(currentPCS, Pin.pcs);
      _playbackIndex++;
      notifyListeners();
    } else {
      logger.e(
        'Skipping playback row at index $_playbackIndex due to insufficient columns (found ${currentRow.length}, expected at least 3',
      );
      _playbackIndex++;
      notifyListeners();
    }

    Duration interval = const Duration(seconds: 1);

    if (_playbackIndex < _playbackData!.length && _playbackIndex > 1) {
      try {
        final currentTimestamp = int.tryParse(
          _playbackData![_playbackIndex - 1][0].toString(),
        );
        final nextTimestamp = int.tryParse(
          _playbackData![_playbackIndex][0].toString(),
        );

        if (currentTimestamp != null && nextTimestamp != null) {
          final timeDiff = nextTimestamp - currentTimestamp;
          interval = Duration(milliseconds: timeDiff);
          if (interval.inMilliseconds < 100) {
            interval = const Duration(milliseconds: 100);
          } else if (interval.inMilliseconds > 10000) {
            interval = const Duration(seconds: 10);
          }
        }
      } catch (e) {
        interval = const Duration(seconds: 1);
      }
    }

    _playbackTimer = Timer(interval, () {
      if (_isPlayingBack && !_isPlaybackPaused) {
        _startPlaybackTimer();
      }
    });
  }

  Future<void> stopPlayback() async {
    _isPlayingBack = false;
    _isPlaybackPaused = false;
    _playbackTimer?.cancel();
    _playbackData = null;
    _playbackIndex = 0;

    notifyListeners();
    onPlaybackEnd?.call();
  }

  void startPlayback(List<List<dynamic>> data) {
    if (data.length <= 1) return;

    _isPlayingBack = true;
    _isPlaybackPaused = false;
    _playbackData = data;
    _playbackIndex = 2;

    _startPlaybackTimer();
    notifyListeners();
  }

  void pausePlayback() {
    if (_isPlayingBack) {
      _isPlaybackPaused = true;
      _playbackTimer?.cancel();
      notifyListeners();
    }
  }

  void resumePlayback() {
    if (_isPlayingBack && _isPlaybackPaused) {
      _isPlaybackPaused = false;
      _startPlaybackTimer();
      notifyListeners();
    }
  }

  Future<bool> startRecording() async {
    if (!_scienceLab.isConnected()) {
      return false;
    }
    if (_configProvider.config.includeLocationData) {
      await _startGeoLocationUpdates();
    }
    _isRecording = true;
    _recordedData = [
      [
        'Timestamp',
        'DateTime',
        'PV1',
        'PV2',
        'PV3',
        'PCS',
        'Latitude',
        'Longitude',
      ],
    ];
    _loggingTimer = Timer.periodic(
      Duration(milliseconds: _configProvider.config.loggingInterval),
      (timer) {
        final now = DateTime.now();
        final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
        _recordedData.add([
          now.millisecondsSinceEpoch.toString(),
          dateFormat.format(now),
          voltagePV1.toStringAsFixed(2),
          voltagePV2.toStringAsFixed(2),
          voltagePV3.toStringAsFixed(2),
          currentPCS.toStringAsFixed(2),
          _configProvider.config.includeLocationData
              ? currentPosition?.latitude.toString() ?? 0
              : 0,
          _configProvider.config.includeLocationData
              ? currentPosition?.longitude.toString() ?? 0
              : 0,
        ]);
      },
    );
    notifyListeners();
    return true;
  }

  List<List<dynamic>> stopRecording() {
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
    if (_loggingTimer != null) {
      _loggingTimer!.cancel();
    }
    _isRecording = false;
    notifyListeners();
    return _recordedData;
  }
}
