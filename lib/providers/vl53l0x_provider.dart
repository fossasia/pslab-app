import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/sensors/vl53l0x.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/models/chart_data_points.dart';

import '../l10n/app_localizations.dart';
import 'locator.dart';

class VL53L0XProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  static const int maxDataPoints = 1000;
  VL53L0X? _sensor;
  Timer? _timer;

  bool _isRunning = false;
  bool _isLooping = false;
  int _timegapMs = 500;
  int _numberOfReadings = 100;
  int _collectedReadings = 0;

  double _distance = 0.0;
  double _currentTime = 0.0;
  final List<ChartDataPoint> _distanceData = <ChartDataPoint>[];

  bool get isRunning => _isRunning;
  bool get isLooping => _isLooping;
  int get timegapMs => _timegapMs;
  int get numberOfReadings => _numberOfReadings;
  int get collectedReadings => _collectedReadings;
  double get distance => _distance;
  List<ChartDataPoint> get distanceData => List.unmodifiable(_distanceData);

  Future<void> initializeSensors({
    required Function(String) onError,
    I2C? i2c,
    ScienceLab? scienceLab,
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
      _sensor = await VL53L0X.create(i2c, scienceLab);
      logger.d('VL53L0X sensor initialized successfully');
    } catch (e) {
      logger.e('Failed to initialize VL53L0X: $e');
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
    if (_sensor == null) return;

    _isRunning = true;
    _collectedReadings = 0;

    _timer = Timer.periodic(Duration(milliseconds: _timegapMs), (timer) async {
      try {
        await _collectData();
        _collectedReadings++;

        if (!_isLooping && _collectedReadings >= _numberOfReadings) {
          _stopDataCollection();
        }

        if (_isLooping && _distanceData.length >= maxDataPoints) {
          _removeOldestDataPoints();
        }
      } catch (e) {
        logger.e('Error collecting VL53L0X data: $e');
      }
    });
    notifyListeners();
  }

  void _stopDataCollection() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  Future<void> _collectData() async {
    if (_sensor == null) return;

    try {
      double newDistance = await _sensor!.getDistance();
      _distance = newDistance;

      _currentTime += _timegapMs / 1000.0;

      _addDataPoint(_distanceData, _distance);

      notifyListeners();
    } catch (e) {
      logger.e('Error in _collectData: $e');
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
    if (_distanceData.length > keepPoints) {
      final removeCount = _distanceData.length - keepPoints;
      _distanceData.removeRange(0, removeCount);
    }
  }

  void toggleLooping() {
    _isLooping = !_isLooping;
    notifyListeners();
  }

  void setTimegap(int newTimegap) {
    _timegapMs = newTimegap;

    if (_isRunning) {
      _stopDataCollection();
      _startDataCollection();
    }

    notifyListeners();
  }

  void setNumberOfReadings(int newNumber) {
    _numberOfReadings = newNumber;
    notifyListeners();
  }

  void clearData() {
    _distanceData.clear();
    _distance = 0.0;
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
