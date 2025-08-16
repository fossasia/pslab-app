import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import '../communication/sensors/bmp180.dart';
import '../l10n/app_localizations.dart';
import '../models/chart_data_points.dart';
import 'package:pslab/others/logger_service.dart';
import 'locator.dart';

class BMP180Provider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  BMP180? _bmp180;
  Timer? _dataTimer;

  double _temperature = 0.0;
  double _pressure = 0.0;
  double _altitude = 0.0;

  final List<ChartDataPoint> _temperatureData = [];
  final List<ChartDataPoint> _pressureData = [];
  final List<ChartDataPoint> _altitudeData = [];

  bool _isRunning = false;
  bool _isLooping = false;
  int _timegapMs = 1000;
  int _numberOfReadings = 100;
  int _collectedReadings = 0;

  double _currentTime = 0.0;
  static const int maxDataPoints = 1000;

  double get temperature => _temperature;
  double get pressure => _pressure;
  double get altitude => _altitude;

  List<ChartDataPoint> get temperatureData =>
      List.unmodifiable(_temperatureData);
  List<ChartDataPoint> get pressureData => List.unmodifiable(_pressureData);
  List<ChartDataPoint> get altitudeData => List.unmodifiable(_altitudeData);

  bool get isRunning => _isRunning;
  bool get isLooping => _isLooping;
  int get timegapMs => _timegapMs;
  int get numberOfReadings => _numberOfReadings;
  int get collectedReadings => _collectedReadings;

  BMP180Provider();

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

      _bmp180 = await BMP180.create(i2c, scienceLab);
      notifyListeners();
    } catch (e) {
      logger.e('Error initializing BMP180: $e');
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
    if (_bmp180 == null) return;

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

        if (_isLooping && _temperatureData.length >= maxDataPoints) {
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
    if (_bmp180 == null) return;

    try {
      final rawData = await _bmp180!.getRawData();

      _temperature = rawData['temperature'] ?? 0.0;
      _pressure = rawData['pressure'] ?? 0.0;
      _altitude = rawData['altitude'] ?? 0.0;

      _currentTime += _timegapMs / 1000.0;

      _addDataPoint(_temperatureData, _temperature);
      _addDataPoint(_pressureData, _pressure);
      _addDataPoint(_altitudeData, _altitude);

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

    if (_temperatureData.length > keepPoints) {
      final removeCount = _temperatureData.length - keepPoints;
      _temperatureData.removeRange(0, removeCount);
      _pressureData.removeRange(0, removeCount);
      _altitudeData.removeRange(0, removeCount);
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
    _temperatureData.clear();
    _pressureData.clear();
    _altitudeData.clear();
    _pressure = 0;
    _altitude = 0;
    _temperature = 0;
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
