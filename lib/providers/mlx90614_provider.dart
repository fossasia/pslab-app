import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import '../communication/sensors/mlx90614.dart';
import '../l10n/app_localizations.dart';
import '../models/chart_data_points.dart';
import 'package:pslab/others/logger_service.dart';
import 'locator.dart';

class MLX90614Provider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  MLX90614? _mlx90614;
  Timer? _dataTimer;

  double _objectTemperature = 0.0;
  double _ambientTemperature = 0.0;

  final List<ChartDataPoint> _objectTempData = [];
  final List<ChartDataPoint> _ambientTempData = [];

  bool _isRunning = false;
  bool _isLooping = false;
  int _timegapMs = 1000;
  int _numberOfReadings = 100;
  int _collectedReadings = 0;

  double _currentTime = 0.0;
  static const int maxDataPoints = 1000;

  double get objectTemperature => _objectTemperature;
  double get ambientTemperature => _ambientTemperature;

  List<ChartDataPoint> get objectTempData => List.unmodifiable(_objectTempData);
  List<ChartDataPoint> get ambientTempData =>
      List.unmodifiable(_ambientTempData);

  bool get isRunning => _isRunning;
  bool get isLooping => _isLooping;
  int get timegapMs => _timegapMs;
  int get numberOfReadings => _numberOfReadings;
  int get collectedReadings => _collectedReadings;

  MLX90614Provider();

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
        logger.w("ScienceLab not connected");
        return;
      }

      _mlx90614 = await MLX90614.create(i2c);
      notifyListeners();
    } catch (e) {
      logger.e('Error initializing MLX90614: $e');
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
    if (_mlx90614 == null) return;

    _isRunning = true;
    _collectedReadings = 0;

    _dataTimer = Timer.periodic(Duration(milliseconds: _timegapMs), (
      timer,
    ) async {
      try {
        await _fetchSensorData();
        _collectedReadings++;

        if (!_isLooping && _collectedReadings >= _numberOfReadings) {
          _stopDataCollection();
        }

        if (_isLooping && _objectTempData.length >= maxDataPoints) {
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
    if (_mlx90614 == null) return;

    try {
      final rawData = await _mlx90614!.getRawData();

      _objectTemperature = rawData['objectTemperature'] ?? 0.0;
      _ambientTemperature = rawData['ambientTemperature'] ?? 0.0;

      _currentTime += _timegapMs / 1000.0;

      _addDataPoint(_objectTempData, _objectTemperature);
      _addDataPoint(_ambientTempData, _ambientTemperature);

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

    if (_objectTempData.length > keepPoints) {
      final removeCount = _objectTempData.length - keepPoints;
      _objectTempData.removeRange(0, removeCount);
      _ambientTempData.removeRange(0, removeCount);
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
    _objectTempData.clear();
    _ambientTempData.clear();
    _objectTemperature = 0;
    _ambientTemperature = 0;
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
