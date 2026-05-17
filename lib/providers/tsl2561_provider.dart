import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import '../communication/sensors/tsl2561.dart';
import '../l10n/app_localizations.dart';
import '../models/chart_data_points.dart';
import 'package:pslab/others/logger_service.dart';
import 'locator.dart';

class TSL2561Provider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  TSL2561? _tsl2561;
  Timer? _dataTimer;

  double _fullSpectrum = 0.0;
  double _infrared = 0.0;
  double _visible = 0.0;

  final List<ChartDataPoint> _fullData = [];
  final List<ChartDataPoint> _infraredData = [];
  final List<ChartDataPoint> _visibleData = [];

  bool _isRunning = false;
  bool _isLooping = false;
  int _timegapMs = 1000;
  int _numberOfReadings = 100;
  int _collectedReadings = 0;

  double _currentTime = 0.0;
  static const int maxDataPoints = 1000;

  double get fullSpectrum => _fullSpectrum;
  double get infrared => _infrared;
  double get visible => _visible;

  List<ChartDataPoint> get fullData => List.unmodifiable(_fullData);
  List<ChartDataPoint> get infraredData => List.unmodifiable(_infraredData);
  List<ChartDataPoint> get visibleData => List.unmodifiable(_visibleData);

  bool get isRunning => _isRunning;
  bool get isLooping => _isLooping;
  int get timegapMs => _timegapMs;
  int get numberOfReadings => _numberOfReadings;
  int get collectedReadings => _collectedReadings;

  TSL2561Provider();

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

      _tsl2561 = await TSL2561.create(i2c, scienceLab);
      notifyListeners();
    } catch (e) {
      logger.e('Error initializing TSL2561: $e');
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
    if (_tsl2561 == null) return;

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

        if (_isLooping && _fullData.length >= maxDataPoints) {
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
    if (_tsl2561 == null) return;

    try {
      final rawData = await _tsl2561!.getRawData();

      _fullSpectrum = rawData['full'] ?? 0.0;
      _infrared = rawData['infrared'] ?? 0.0;
      _visible = rawData['visible'] ?? 0.0;

      _currentTime += _timegapMs / 1000.0;

      _addDataPoint(_fullData, _fullSpectrum);
      _addDataPoint(_infraredData, _infrared);
      _addDataPoint(_visibleData, _visible);

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

    if (_fullData.length > keepPoints) {
      final removeCount = _fullData.length - keepPoints;
      _fullData.removeRange(0, removeCount);
      _infraredData.removeRange(0, removeCount);
      _visibleData.removeRange(0, removeCount);
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
    _fullData.clear();
    _infraredData.clear();
    _visibleData.clear();
    _fullSpectrum = 0;
    _infrared = 0;
    _visible = 0;
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
