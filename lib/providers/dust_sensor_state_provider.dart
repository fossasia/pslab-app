import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../others/logger_service.dart';
import 'dust_sensor_config_provider.dart';
import 'locator.dart';

class DustSensorStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  double _currentDust = 0.0;
  Timer? _timeTimer;
  Timer? _dustTimer;
  final List<double> _dustData = [];
  final List<double> _timeData = [];
  final List<FlSpot> dustChartData = [];
  final List<FlSpot> ppmChartData = [];
  double _startTime = 0;
  double _currentTime = 0;
  final int _chartMaxLength = 50;
  double _dustMin = 0;
  double _dustMax = 0;
  double _dustSum = 0;
  int _dataCount = 0;
  bool _isRecording = false;
  List<List<dynamic>> _recordedData = [];
  bool _isPlayingBack = false;
  List<List<dynamic>>? _playbackData;
  int _playbackIndex = 0;
  Timer? _playbackTimer;
  bool _isPlaybackPaused = false;
  bool get isRecording => _isRecording;
  bool get isPlayingBack => _isPlayingBack;
  bool get isPlaybackPaused => _isPlaybackPaused;

  DustSensorConfigProvider? _configProvider;

  Function(String)? onSensorError;
  Function? onPlaybackEnd;

  Position? currentPosition;
  StreamSubscription? _locationStream;

  void setConfigProvider(DustSensorConfigProvider configProvider) {
    _configProvider = configProvider;
  }

  DustSensorConfigProvider? get configProvider => _configProvider;

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
          'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).listen((Position position) {
      currentPosition = position;
    });
  }

  void initializeSensors({Function(String)? onError}) async {
    onSensorError = onError;

    try {
      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

      _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _currentTime =
            (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;
        _updateData();
        notifyListeners();
      });

      int interval = _configProvider?.config.updatePeriod ?? 1000;
      _dustTimer = Timer.periodic(Duration(milliseconds: interval), (timer) {

        /// TO DO

        notifyListeners();
      });
    } catch (e) {
      logger.e("Dust sensor initialization error: $e");
      _handleSensorError(e);
    }
  }

  void _handleSensorError(dynamic error) {
    onSensorError?.call("Unable to access dust sensor");
    logger.e("Dust sensor error: $error");
  }

  void disposeSensors() async {
    _timeTimer?.cancel();
    _dustTimer?.cancel();
  }

  void startPlayback(List<List<dynamic>> data) {
    if (data.length <= 1) return;

    _isPlayingBack = true;
    _isPlaybackPaused = false;
    _playbackData = data;
    _playbackIndex = 1;

    _timeTimer?.cancel();
    _dustTimer?.cancel();

    _dustData.clear();
    dustChartData.clear();
    ppmChartData.clear();
    _timeData.clear();
    _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _currentTime = 0;
    _dustSum = 0;
    _dataCount = 0;

    _startPlaybackTimer();
    notifyListeners();
  }

  void _startPlaybackTimer() {
    if (_playbackIndex >= _playbackData!.length) {
      stopPlayback();
      return;
    }

    final currentRow = _playbackData![_playbackIndex];
    if (currentRow.length > 2) {
      _currentDust = double.tryParse(currentRow[2].toString()) ?? 0.0;
      _currentTime = (_playbackIndex - 1).toDouble();
      _updateData();
      _playbackIndex++;
      notifyListeners();
    } else {
      logger.e(
          'Skipping playback row at index $_playbackIndex due to insufficient columns (found ${currentRow.length}, expected at least 3');
      _playbackIndex++;
      notifyListeners();
    }

    Duration interval = const Duration(seconds: 1);

    if (_playbackIndex < _playbackData!.length && _playbackIndex > 1) {
      try {
        final currentTimestamp =
            int.tryParse(_playbackData![_playbackIndex - 1][0].toString());
        final nextTimestamp =
            int.tryParse(_playbackData![_playbackIndex][0].toString());

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

    _dustData.clear();
    dustChartData.clear();
    ppmChartData.clear();
    _timeData.clear();
    _dustSum = 0;
    _dataCount = 0;
    _currentDust = 0.0;
    _currentTime = 0;
    notifyListeners();
    onPlaybackEnd?.call();
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

  @override
  void dispose() {
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
    _playbackTimer?.cancel();
    disposeSensors();
    super.dispose();
  }

  void _updateData() {
    final dust = _currentDust;
    final time = _currentTime;
    if (_isRecording) {
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
      _recordedData.add([
        now.millisecondsSinceEpoch.toString(),
        dateFormat.format(now),
        dust.toStringAsFixed(2),
        _configProvider!.config.includeLocationData
            ? currentPosition?.latitude.toString() ?? 0
            : 0,
        _configProvider!.config.includeLocationData
            ? currentPosition?.longitude.toString() ?? 0
            : 0
      ]);
    }
    _dustData.add(dust);
    _timeData.add(time);
    _dustSum += dust;
    _dataCount++;
    if (_dustData.length > _chartMaxLength) {
      final removedValue = _dustData.removeAt(0);
      _timeData.removeAt(0);
      _dustSum -= removedValue;
      _dataCount--;
    }
    if (_dustData.isNotEmpty) {
      _dustMin = _dustData.reduce(min);
      _dustMax = _dustData.reduce(max);
    }
    dustChartData.clear();
    ppmChartData.clear();
    for (int i = 0; i < _dustData.length; i++) {
      dustChartData.add(FlSpot(_timeData[i], _dustData[i]));
      ppmChartData.add(FlSpot(_timeData[i], _dustData[i] * 0.1));
    }
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (_configProvider!.config.includeLocationData) {
      await _startGeoLocationUpdates();
    }
    _isRecording = true;
    _recordedData = [
      ['Timestamp', 'DateTime', 'Readings', 'Latitude', 'Longitude']
    ];
    notifyListeners();
  }

  List<List<dynamic>> stopRecording() {
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
    _isRecording = false;
    notifyListeners();
    return _recordedData;
  }

  double getCurrentDust() => _currentDust;
  double getMinDust() => _dustMin;
  double getMaxDust() => _dustMax;
  double getAverageDust() => _dataCount > 0 ? _dustSum / _dataCount : 0.0;
  double getPPM() => _currentDust * 0.1;
  double getMaxPPM() => _dustMax * 0.1;
  String getAirQuality() {
    if (_currentDust < 300) return appLocalizations.good;
    if (_currentDust < 1000) return appLocalizations.moderate;
    if (_currentDust < 3000) return appLocalizations.unhealthy;
    return appLocalizations.hazardous;
  }

  List<FlSpot> getDustChartData() => dustChartData;
  List<FlSpot> getPPMChartData() => ppmChartData;
  int getDataLength() => dustChartData.length;
  double getCurrentTime() => _currentTime;
  double getMaxTime() => _timeData.isNotEmpty ? _timeData.last : 0;
  double getMinTime() => _timeData.isNotEmpty ? _timeData.first : 0;
  double getTimeInterval() {
    if (_currentTime <= 10) return 2;
    if (_currentTime <= 30) return 5;
    return 10;
  }
}
