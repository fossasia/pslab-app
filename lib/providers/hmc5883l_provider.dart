import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import '../communication/sensors/hmc5883l.dart';
import '../l10n/app_localizations.dart';
import '../models/chart_data_points.dart';
import 'package:pslab/others/logger_service.dart';
import 'locator.dart';

class HMC5883LProvider extends ChangeNotifier {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  HMC5883L? _hmc5883l;
  Timer? _dataTimer;

  double _bx = 0.0;
  double _by = 0.0;
  double _bz = 0.0;

  final List<ChartDataPoint> _bxData = [];
  final List<ChartDataPoint> _byData = [];
  final List<ChartDataPoint> _bzData = [];

  bool _isRunning = false;
  bool _isLooping = false;
  int _timegapMs = 1000;
  int _numberOfReadings = 100;
  int _collectedReadings = 0;

  double _currentTime = 0.0;
  static const int maxDataPoints = 1000;

  double get bx => _bx;
  double get by => _by;
  double get bz => _bz;

  List<ChartDataPoint> get bxData => List.unmodifiable(_bxData);
  List<ChartDataPoint> get byData => List.unmodifiable(_byData);
  List<ChartDataPoint> get bzData => List.unmodifiable(_bzData);

  bool get isRunning => _isRunning;
  bool get isLooping => _isLooping;
  int get timegapMs => _timegapMs;
  int get numberOfReadings => _numberOfReadings;
  int get collectedReadings => _collectedReadings;

  HMC5883LProvider();

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

      _hmc5883l = await HMC5883L.create(i2c, scienceLab);
      notifyListeners();
    } catch (e) {
      logger.e('Error initializing HMC5883L: $e');
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
    if (_hmc5883l == null) return;

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

        if (_isLooping && _bxData.length >= maxDataPoints) {
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
    if (_hmc5883l == null) return;

    try {
      List<double> data = await _hmc5883l!.getRaw();

      _bx = data[0];
      _by = data[1];
      _bz = data[2];

      _currentTime += _timegapMs / 1000.0;

      _addDataPoint(_bxData, _bx);
      _addDataPoint(_byData, _by);
      _addDataPoint(_bzData, _bz);

      notifyListeners();
    } catch (e) {
      logger.e('Error in _fetchSensorData: $e');
      _stopDataCollection();
    }
  }

  void _addDataPoint(List<ChartDataPoint> dataList, double value) {
    // Corrected instantiation format
    dataList.add(ChartDataPoint(_currentTime, value));
    if (dataList.length > 50) {
      dataList.removeAt(0);
    }
  }

  void _removeOldestDataPoints() {
    const keepPoints = 800;

    if (_bxData.length > keepPoints) {
      final removeCount = _bxData.length - keepPoints;
      _bxData.removeRange(0, removeCount);
      _byData.removeRange(0, removeCount);
      _bzData.removeRange(0, removeCount);
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
    _bxData.clear();
    _byData.clear();
    _bzData.clear();
    _bx = 0;
    _by = 0;
    _bz = 0;
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
