import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/communication/science_lab.dart';

import '../l10n/app_localizations.dart';
import 'locator.dart';

class GasSensorStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  ScienceLab? _scienceLab;

  double _currentValue = 0.0;
  String _activeMode = "Raw";
  int _updatePeriod = 1000;

  Timer? _readTimer;

  final List<double> _sensorData = [];
  final List<double> _timeData = [];
  final List<FlSpot> _gasChartData = [];

  double _startTime = 0;
  double _currentTime = 0;
  final int _maxLength = 80;

  double _valueMin = double.infinity;
  double _valueMax = 0;
  double _valueSum = 0;
  int _dataCount = 0;

  bool _isSensorAvailable = false;
  bool _isInitialized = false;
  bool _isFetching = false;
  bool _isCalibrating = false;

  bool _isRecording = false;
  List<List<dynamic>> _recordedData = [];
  Position? currentPosition;
  StreamSubscription? _locationStream;
  bool get isRecording => _isRecording;

  int? _playbackStartTimestamp;
  bool _isPlayingRecordedData = false;
  bool _isPlaybackPaused = false;
  List<List<dynamic>>? _playbackData;
  int _playbackIndex = 0;
  Timer? _playbackTimer;
  Function? onPlaybackEnd;

  bool isPlayingData() => _isPlayingRecordedData;
  bool get isPlaybackPaused => _isPlaybackPaused;

  final double _rLoad = 10.0;
  double _r0 = 41.7;
  final double _vcc = 5.0;

  final Map<String, List<double>> _gasParams = {
    'CO2': [110.47, -2.862],
    'NH3': [102.2, -2.473],
    'Alcohol': [77.255, -3.18],
    'CO': [605.18, -3.937],
    'Toluene': [44.947, -3.445],
    'Acetone': [34.668, -3.369],
  };

  double get _correction {
    double t = 20.0;
    double h = 0.65;
    return (3.28e-4 * pow(t, 2)) +
        (-2.55e-2 * t) +
        1.38 +
        (-2.24e-1 * (h - 0.65));
  }

  double _calculateRs(double voltage) {
    if (voltage <= 0.01) voltage = 0.01;
    return ((_vcc / voltage) - 1) * _rLoad / _correction;
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
      logger.w('Location permissions are permanently denied.');
      return;
    }

    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      currentPosition = position;
    });
  }

  Future<void> fetchConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('gas_sensor_config');
      if (jsonString != null) {
        final configData = json.decode(jsonString);
        String newMode = configData['activeGas'] ?? 'Raw';
        int newPeriod = configData['updatePeriod'] ?? 1000;

        bool modeChanged = false;
        bool periodChanged = false;

        if (newMode != _activeMode) {
          _activeMode = newMode;
          clearData();
          _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
          modeChanged = true;
        }

        if (newPeriod != _updatePeriod) {
          _updatePeriod = newPeriod;
          periodChanged = true;
        }

        if (modeChanged || periodChanged) {
          notifyListeners();
        }

        if (periodChanged && _readTimer != null && _readTimer!.isActive) {
          _startReadingGasData();
        }
      }
    } catch (e) {
      logger.e("Error reading config: $e");
    }
  }

  Future<void> initializeSensors() async {
    if (_isInitialized) return;

    try {
      await fetchConfig();

      _scienceLab = getIt.get<ScienceLab>();

      if (_scienceLab != null && _scienceLab!.isConnected()) {
        _isSensorAvailable = true;
        _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

        _isCalibrating = true;
        notifyListeners();
        await _calibrateUniversal();
        _isCalibrating = false;

        logger.d('MQ-135 Gas sensor initialized successfully');
      } else {
        _isSensorAvailable = false;
      }
      _startReadingGasData();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      logger.e("Error initializing gas sensor: $e");
      _isSensorAvailable = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _calibrateUniversal() async {
    if (_scienceLab == null || !_scienceLab!.isConnected()) return;
    List<double> rsReadings = [];

    for (int i = 0; i < 10; i++) {
      double volt = await _scienceLab!.getVoltage(appLocalizations.ch1, 1);
      if (volt > 4.99) volt = 4.99;
      rsReadings.add(_calculateRs(volt));
      await Future.delayed(const Duration(milliseconds: 100));
    }

    double avgRs = rsReadings.reduce((a, b) => a + b) / rsReadings.length;
    _r0 = avgRs / 3.6;

    notifyListeners();
  }

  void _startReadingGasData() {
    _readTimer?.cancel();
    _readTimer =
        Timer.periodic(Duration(milliseconds: _updatePeriod), (timer) async {
      if (_isPlayingRecordedData) return;
      await fetchConfig();
      if (!_isSensorAvailable ||
          _scienceLab == null ||
          _isFetching ||
          _isCalibrating) {
        return;
      }

      _isFetching = true;

      try {
        double volt = await _scienceLab!.getVoltage(appLocalizations.ch1, 1);
        if (volt > 4.99) volt = 4.99;

        if (_activeMode == 'Raw') {
          _currentValue = ((volt / 3.3) * 1024.0).clamp(0.0, 1024.0);
        } else {
          double rs = _calculateRs(volt);
          double ratio = rs / _r0;
          double a = _gasParams[_activeMode]![0];
          double b = _gasParams[_activeMode]![1];

          double rawPpm = (a * pow(ratio, b));

          if (_activeMode == 'CO2') {
            _currentValue = (rawPpm + 400.0).clamp(0.0, 10000.0);
          } else if (_activeMode == 'CO') {
            _currentValue = (rawPpm + 3.0).clamp(0.0, 10000.0);
          } else {
            if (rawPpm < 10.0) {
              _currentValue = 0.0;
            } else {
              _currentValue = rawPpm.clamp(0.0, 10000.0);
            }
          }
        }

        _currentTime =
            (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;
        _updateData();
        notifyListeners();
      } catch (e) {
        logger.e("Gas sensor read error: $e");
      } finally {
        _isFetching = false;
      }
    });
  }

  Future<void> startRecording() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('gas_sensor_config');
    bool includeLoc = true;
    if (jsonString != null) {
      includeLoc = json.decode(jsonString)['includeLocationData'] ?? true;
    }

    if (includeLoc) {
      await _startGeoLocationUpdates();
    }

    _isRecording = true;
    _recordedData = [
      [
        'Timestamp',
        'DateTime',
        'Readings',
        'Active Gas',
        'Latitude',
        'Longitude'
      ]
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

  void startPlayback(List<List<dynamic>> data) {
    if (data.length <= 2) return;
    _playbackStartTimestamp = int.tryParse(data[2][0].toString())?.toInt();
    _isPlayingRecordedData = true;
    _isPlaybackPaused = false;
    _playbackData = data;

    _playbackIndex = 2;

    _readTimer?.cancel();

    _sensorData.clear();
    _gasChartData.clear();
    _timeData.clear();
    _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _currentTime = 0;
    _valueSum = 0;
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
      _currentValue = double.tryParse(currentRow[2].toString()) ?? 0.0;
      final timestamp = int.tryParse(currentRow[0].toString())?.toInt();
      if (timestamp != null && _playbackStartTimestamp != null) {
        _currentTime = (timestamp - _playbackStartTimestamp!) / 1000.0;
      }

      if (currentRow.length > 3) {
        _activeMode = currentRow[3].toString();
      }

      _updateData();
      _playbackIndex++;
      notifyListeners();
    } else {
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
      if (_isPlayingRecordedData && !_isPlaybackPaused) {
        _startPlaybackTimer();
      }
    });
  }

  void pausePlayback() {
    if (_isPlayingRecordedData) {
      _isPlaybackPaused = true;
      _playbackTimer?.cancel();
      notifyListeners();
    }
  }

  void resumePlayback() {
    if (_isPlayingRecordedData && _isPlaybackPaused) {
      _isPlaybackPaused = false;
      _startPlaybackTimer();
      notifyListeners();
    }
  }

  Future<void> stopPlayback() async {
    _isPlayingRecordedData = false;
    _isPlaybackPaused = false;
    _playbackTimer?.cancel();
    _playbackData = null;
    _playbackIndex = 0;

    clearData();
    notifyListeners();
    onPlaybackEnd?.call();
  }

  void _updateData() {
    if (_isRecording && !_isPlayingRecordedData) {
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
      _recordedData.add([
        now.millisecondsSinceEpoch.toString(),
        dateFormat.format(now),
        _currentValue.toStringAsFixed(2),
        _activeMode,
        currentPosition?.latitude.toString() ?? 0,
        currentPosition?.longitude.toString() ?? 0
      ]);
    }

    _sensorData.add(_currentValue);
    _timeData.add(_currentTime);
    _valueSum += _currentValue;
    _dataCount++;

    if (_sensorData.length > _maxLength) {
      final removedValue = _sensorData.removeAt(0);
      _timeData.removeAt(0);
      _valueSum -= removedValue;
      _dataCount--;
    }

    if (_sensorData.isNotEmpty) {
      _valueMin = _sensorData.reduce(min);
      _valueMax = _sensorData.reduce(max);
    }

    _gasChartData.clear();
    for (int i = 0; i < _sensorData.length; i++) {
      _gasChartData.add(FlSpot(_timeData[i], _sensorData[i]));
    }
  }

  void clearData() {
    _sensorData.clear();
    _timeData.clear();
    _gasChartData.clear();
    _valueMin = double.infinity;
    _valueMax = 0;
    _valueSum = 0;
    _dataCount = 0;
    _currentTime = 0;
    _currentValue = 0;
  }

  void disposeSensors() {
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
    _readTimer?.cancel();
    _playbackTimer?.cancel();
    _isInitialized = false;
  }

  @override
  void dispose() {
    disposeSensors();
    super.dispose();
  }

  double getCurrentValue() => _currentValue;
  String getActiveMode() => _activeMode;

  double getMinValue() => _valueMin == double.infinity ? 0 : _valueMin;
  double getMaxValue() => _valueMax;
  double getAverageValue() => _dataCount > 0 ? _valueSum / _dataCount : 0.0;

  List<FlSpot> getGasChartData() =>
      _gasChartData.isEmpty ? [const FlSpot(0, 0)] : _gasChartData;
  int getDataLength() => _gasChartData.length;
  double getCurrentTime() => _currentTime;
  double getMaxTime() => _timeData.isNotEmpty ? _timeData.last : 0;
  double getMinTime() => _timeData.isNotEmpty ? _timeData.first : 0;
  bool isSensorAvailable() => _isSensorAvailable;
  bool isInitialized() => _isInitialized;
  bool isCalibrating() => _isCalibrating;

  double getTimeInterval() {
    if (_currentTime <= 10) return 2;
    if (_currentTime <= 30) return 5;
    if (_currentTime <= 80) return 10;
    return 20;
  }
}
