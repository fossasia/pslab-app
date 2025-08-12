import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import '../communication/sensors/apds9960.dart';
import '../l10n/app_localizations.dart';
import '../models/chart_data_points.dart';
import 'package:pslab/others/logger_service.dart';
import 'locator.dart';

class APDS9960Provider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  APDS9960? _apds9960;
  Timer? _dataTimer;

  int _red = 0;
  int _green = 0;
  int _blue = 0;
  int _clear = 0;
  double _lux = 0.0;
  int _proximity = 0;
  int _gesture = 0;
  String _gestureString = '';

  final List<ChartDataPoint> _luxData = [];
  final List<ChartDataPoint> _proximityData = [];

  bool _isRunning = false;
  bool _isLooping = false;
  int _timegapMs = 1000;
  int _numberOfReadings = 100;
  int _collectedReadings = 0;
  int _mode = 0;

  double _currentTime = 0.0;
  static const int maxDataPoints = 1000;

  int get red => _red;
  int get green => _green;
  int get blue => _blue;
  int get clear => _clear;
  double get lux => _lux;
  int get proximity => _proximity;
  int get gesture => _gesture;
  String get gestureString => _gestureString;

  List<ChartDataPoint> get luxData => List.unmodifiable(_luxData);
  List<ChartDataPoint> get proximityData => List.unmodifiable(_proximityData);

  bool get isRunning => _isRunning;
  bool get isLooping => _isLooping;
  int get timegapMs => _timegapMs;
  int get numberOfReadings => _numberOfReadings;
  int get collectedReadings => _collectedReadings;
  int get mode => _mode;

  APDS9960Provider();

  Future<void> initializeSensors({
    required Function(String) onError,
    required I2C? i2c,
    required ScienceLab? scienceLab,
  }) async {
    try {
      if (i2c == null || scienceLab == null) {
        onError(appLocalizations.pslabNotConnected);
        logger.w('I2C or ScienceLab not available');
        return;
      }

      if (!scienceLab.isConnected()) {
        onError(appLocalizations.pslabNotConnected);
        logger.w("Sciencelab not connected");
        return;
      }

      _apds9960 = await APDS9960.create(i2c, scienceLab);
      notifyListeners();
    } catch (e) {
      logger.e('Error initializing APDS9960: $e');
    }
  }

  void setMode(int newMode) {
    if (_mode != newMode) {
      _mode = newMode;

      if (_isRunning) {
        _stopDataCollection();
        _startDataCollection();
      }

      if (_mode != 1) {
        _gesture = 0;
        _gestureString = '';
      }

      notifyListeners();
    }
  }

  void toggleDataCollection() {
    if (_isRunning) {
      _stopDataCollection();
    } else {
      _startDataCollection();
    }
  }

  void _startDataCollection() {
    if (_apds9960 == null) return;

    _isRunning = true;
    _collectedReadings = 0;

    _dataTimer =
        Timer.periodic(Duration(milliseconds: _timegapMs), (timer) async {
      try {
        await _fetchSensorData();
        _collectedReadings++;

        if (!_isLooping && _collectedReadings >= _numberOfReadings) {
          _stopDataCollection();
        }

        if (_isLooping && _luxData.length >= maxDataPoints) {
          _removeOldestDataPoints();
        }
      } catch (e) {
        logger.e('Error fetching sensor data: $e');
      }
    });
    notifyListeners();
  }

  void _stopDataCollection() {
    _isRunning = false;
    _dataTimer?.cancel();
    _dataTimer = null;
    notifyListeners();
  }

  Future<void> _fetchSensorData() async {
    if (_apds9960 == null) return;

    try {
      final rawData = await _apds9960!.getRawData(_mode);

      if (_mode == 0) {
        List<int>? colorData = rawData['colorData'];
        if (colorData != null && colorData.length >= 4) {
          _red = colorData[0];
          _green = colorData[1];
          _blue = colorData[2];
          _clear = colorData[3];
        }

        _lux = rawData['lux'] ?? 0.0;
        _proximity = rawData['proximity'] ?? 0;

        _currentTime += _timegapMs / 1000.0;

        _addDataPoint(_luxData, _lux);
        _addDataPoint(_proximityData, _proximity.toDouble());
      } else {
        _gesture = rawData['gesture'] ?? 0;
        _gestureString = _apds9960!.getGestureString(_gesture);
      }

      notifyListeners();
    } catch (e) {
      logger.e('Error in _fetchSensorData: $e');
      rethrow;
    }
  }

  void _addDataPoint(List<ChartDataPoint> dataList, double value) {
    dataList.add(ChartDataPoint(_currentTime, value));
    if (dataList.length > 50) {
      dataList.removeAt(0);
    }
  }

  void _removeOldestDataPoints() {
    const keepPoints = 800;

    if (_luxData.length > keepPoints) {
      final removeCount = _luxData.length - keepPoints;
      _luxData.removeRange(0, removeCount);
      _proximityData.removeRange(0, removeCount);
    }
  }

  void toggleLooping() {
    _isLooping = !_isLooping;
    notifyListeners();
  }

  void setTimegap(int timegapMs) {
    _timegapMs = timegapMs;

    if (_isRunning) {
      _stopDataCollection();
      _startDataCollection();
    }

    notifyListeners();
  }

  void setNumberOfReadings(int numberOfReadings) {
    _numberOfReadings = numberOfReadings;
    notifyListeners();
  }

  void clearData() {
    _luxData.clear();
    _proximityData.clear();
    _red = 0;
    _green = 0;
    _blue = 0;
    _clear = 0;
    _lux = 0.0;
    _proximity = 0;
    _gesture = 0;
    _gestureString = '';
    _currentTime = 0.0;
    _collectedReadings = 0;
    notifyListeners();
  }

  bool get isCollectionComplete {
    return !_isLooping && _collectedReadings >= _numberOfReadings;
  }

  @override
  void dispose() {
    _stopDataCollection();
    super.dispose();
  }
}
