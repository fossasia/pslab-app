import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import '../communication/sensors/mpu925x.dart';
import '../models/chart_data_points.dart';
import 'package:pslab/others/logger_service.dart';

class MPU925XProvider extends ChangeNotifier {
  MPU925X? _mpu925x;
  Timer? _dataTimer;

  final Map<String, double> _currentValues = {
    'ax': 0.0,
    'ay': 0.0,
    'az': 0.0,
    'gx': 0.0,
    'gy': 0.0,
    'gz': 0.0,
    'mx': 0.0,
    'my': 0.0,
    'mz': 0.0,
    'temperature': 0.0,
  };

  final List<ChartDataPoint> _axData = [];
  final List<ChartDataPoint> _ayData = [];
  final List<ChartDataPoint> _azData = [];

  final List<ChartDataPoint> _gxData = [];
  final List<ChartDataPoint> _gyData = [];
  final List<ChartDataPoint> _gzData = [];

  final List<ChartDataPoint> _mxData = [];
  final List<ChartDataPoint> _myData = [];
  final List<ChartDataPoint> _mzData = [];

  bool _isRunning = false;
  bool _isLooping = false;
  int _timegapMs = 500;
  int _numberOfReadings = 100;
  int _collectedReadings = 0;
  double _currentTime = 0.0;

  int _selectedAccelRange = 16;
  int _selectedGyroRange = 2000;

  Map<String, double> get currentValues => _currentValues;
  List<ChartDataPoint> get axData => List.unmodifiable(_axData);
  List<ChartDataPoint> get ayData => List.unmodifiable(_ayData);
  List<ChartDataPoint> get azData => List.unmodifiable(_azData);

  List<ChartDataPoint> get gxData => List.unmodifiable(_gxData);
  List<ChartDataPoint> get gyData => List.unmodifiable(_gyData);
  List<ChartDataPoint> get gzData => List.unmodifiable(_gzData);

  List<ChartDataPoint> get mxData => List.unmodifiable(_mxData);
  List<ChartDataPoint> get myData => List.unmodifiable(_myData);
  List<ChartDataPoint> get mzData => List.unmodifiable(_mzData);

  bool get isRunning => _isRunning;
  bool get isLooping => _isLooping;
  int get timegapMs => _timegapMs;
  int get numberOfReadings => _numberOfReadings;

  int get selectedAccelRange => _selectedAccelRange;
  int get selectedGyroRange => _selectedGyroRange;

  Future<void> initializeSensors({
    required Function(String) onError,
    required I2C? i2c,
    required ScienceLab? scienceLab,
  }) async {
    try {
      if (i2c == null || scienceLab == null || !scienceLab.isConnected()) {
        onError("PSLab not connected");
        return;
      }
      _mpu925x = await MPU925X.create(i2c, scienceLab);
      notifyListeners();
    } catch (e) {
      logger.e('Error initializing MPU925X: $e');
    }
  }

  Future<void> updateAccelRange(int range) async {
    _selectedAccelRange = range;
    await _mpu925x?.setAccelerationRange(range);
    notifyListeners();
  }

  Future<void> updateGyroRange(int range) async {
    _selectedGyroRange = range;
    await _mpu925x?.setGyroRange(range);
    notifyListeners();
  }

  void toggleDataCollection() {
    _isRunning ? _stopDataCollection() : _startDataCollection();
  }

  void _startDataCollection() {
    if (_mpu925x == null) return;
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
        if (_isLooping && _axData.length >= 1000) {
          _removeOldestDataPoints();
        }
      } catch (e) {
        logger.e('Error fetching MPU925X data: $e');
      }
    });
    notifyListeners();
  }

  void _stopDataCollection() {
    _isRunning = false;
    _dataTimer?.cancel();
    notifyListeners();
  }

  Future<void> _fetchSensorData() async {
    if (_mpu925x == null) return;
    try {
      final rawData = await _mpu925x!.getRawData();
      final magData = await _mpu925x!.getMagneticField();

      _currentTime += _timegapMs / 1000.0;

      _currentValues.addAll(rawData);

      if (magData != null && magData.length == 3) {
        _currentValues['mx'] = magData[0];
        _currentValues['my'] = magData[1];
        _currentValues['mz'] = magData[2];
      }

      _addDataPoint(_axData, _currentValues['ax']!);
      _addDataPoint(_ayData, _currentValues['ay']!);
      _addDataPoint(_azData, _currentValues['az']!);

      _addDataPoint(_gxData, _currentValues['gx']!);
      _addDataPoint(_gyData, _currentValues['gy']!);
      _addDataPoint(_gzData, _currentValues['gz']!);

      _addDataPoint(_mxData, _currentValues['mx']!);
      _addDataPoint(_myData, _currentValues['my']!);
      _addDataPoint(_mzData, _currentValues['mz']!);

      notifyListeners();
    } catch (e) {
      logger.e('Error in _fetchSensorData: $e');
    }
  }

  void _addDataPoint(List<ChartDataPoint> dataList, double value) {
    dataList.add(ChartDataPoint(_currentTime, value));
    if (dataList.length > 50) dataList.removeAt(0);
  }

  void _removeOldestDataPoints() {
    final removeCount = _axData.length - 800;
    _axData.removeRange(0, removeCount);
    _ayData.removeRange(0, removeCount);
    _azData.removeRange(0, removeCount);

    _gxData.removeRange(0, removeCount);
    _gyData.removeRange(0, removeCount);
    _gzData.removeRange(0, removeCount);

    _mxData.removeRange(0, removeCount);
    _myData.removeRange(0, removeCount);
    _mzData.removeRange(0, removeCount);
  }

  void toggleLooping() {
    _isLooping = !_isLooping;
    notifyListeners();
  }

  void setTimegap(int ms) {
    _timegapMs = ms;
    if (_isRunning) {
      _stopDataCollection();
      _startDataCollection();
    }
    notifyListeners();
  }

  void setNumberOfReadings(int val) {
    _numberOfReadings = val;
    notifyListeners();
  }

  void clearData() {
    _axData.clear();
    _ayData.clear();
    _azData.clear();
    _gxData.clear();
    _gyData.clear();
    _gzData.clear();
    _mxData.clear();
    _myData.clear();
    _mzData.clear();
    _currentTime = 0.0;
    _collectedReadings = 0;
    _currentValues.updateAll((key, value) => 0.0);
    notifyListeners();
  }

  @override
  void dispose() {
    _stopDataCollection();
    super.dispose();
  }
}
