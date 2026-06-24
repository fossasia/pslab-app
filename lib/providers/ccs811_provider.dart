import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';
import '../communication/sensors/ccs811.dart';
import '../l10n/app_localizations.dart';
import '../models/chart_data_points.dart';
import 'locator.dart';

class CCS811Provider extends ChangeNotifier {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  CCS811? _ccs811;
  Timer? _dataTimer;

  int _eCO2 = 0;
  int _tvoc = 0;

  final List<ChartDataPoint> _eCO2Data = [];
  final List<ChartDataPoint> _tvocData = [];

  bool _isRunning = false;
  bool _isLooping = false;
  int _timegapMs = 1000;
  int _numberOfReadings = 100;
  int _collectedReadings = 0;

  double _currentTime = 0.0;
  static const int maxDataPoints = 1000;

  int get eCO2 => _eCO2;
  int get tvoc => _tvoc;

  List<ChartDataPoint> get eCO2Data => List.unmodifiable(_eCO2Data);
  List<ChartDataPoint> get tvocData => List.unmodifiable(_tvocData);

  bool get isRunning => _isRunning;
  bool get isLooping => _isLooping;
  int get timegapMs => _timegapMs;
  int get numberOfReadings => _numberOfReadings;
  int get collectedReadings => _collectedReadings;

  CCS811Provider();

  Future<void> initializeSensors({
    required Function(String) onError,
    required I2C? i2c,
    required ScienceLab? scienceLab,
  }) async {
    try {
      if (i2c == null || scienceLab == null) {
        onError(appLocalizations.pslabNotConnected);
        logger.w(appLocalizations.notConnected);
        return;
      }

      if (!scienceLab.isConnected()) {
        onError(appLocalizations.pslabNotConnected);
        logger.w(appLocalizations.notConnected);
        return;
      }

      _ccs811 = await CCS811.create(i2c, scienceLab);
      notifyListeners();
    } catch (e) {
      logger.e('Error initializing CCS811: $e');
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
    if (_ccs811 == null) return;

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

        if (_isLooping && _eCO2Data.length >= maxDataPoints) {
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
    if (_ccs811 == null) return;

    try {
      final rawData = await _ccs811!.getRawData();

      _eCO2 = rawData['eCO2'] ?? 0;
      _tvoc = rawData['TVOC'] ?? 0;

      _currentTime += _timegapMs / 1000.0;

      _addDataPoint(_eCO2Data, _eCO2.toDouble());
      _addDataPoint(_tvocData, _tvoc.toDouble());

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

    if (_eCO2Data.length > keepPoints) {
      final removeCount = _eCO2Data.length - keepPoints;
      _eCO2Data.removeRange(0, removeCount);
      _tvocData.removeRange(0, removeCount);
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
    _eCO2Data.clear();
    _tvocData.clear();
    _eCO2 = 0;
    _tvoc = 0;
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
