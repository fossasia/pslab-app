import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/sensors/sht21.dart';
import 'package:pslab/others/logger_service.dart';

import 'package:pslab/models/chart_data_points.dart';

class SHT21Provider extends ChangeNotifier {
  static const String _tag = "SHT21Provider";

  SHT21? _sensor;
  Timer? _readTimer;

  bool _isSensorAvailable = false;
  bool _isInitialized = false;

  bool isRunning = false;
  bool isLooping = false;
  int timegapMs = 500;
  int numberOfReadings = 500;

  double _currentTemp = 0.0;
  double _currentHumidity = 0.0;

  final List<double> _timeData = [];
  final List<double> _tempRawData = [];
  final List<double> _humidityRawData = [];
  bool _isFetching = false;
  final List<ChartDataPoint> tempChartData = [];
  final List<ChartDataPoint> humidityChartData = [];
  double _startTime = 0;

  double get currentTemp => _currentTemp;
  double get currentHumidity => _currentHumidity;
  bool get isSensorAvailable => _isSensorAvailable;

  Future<void> initializeSensors({
    required Function(String) onError,
    I2C? i2c,
    ScienceLab? scienceLab,
  }) async {
    if (_isInitialized) return;

    if (scienceLab != null && scienceLab.isConnected() && i2c != null) {
      _sensor = SHT21(i2c);

      bool connected = await _sensor!.checkConnection();
      if (connected) {
        _isSensorAvailable = true;
        _isInitialized = true;
        logger.d("$_tag: SHT21 initialized successfully!");
        notifyListeners();
        return;
      }
    }

    _isSensorAvailable = false;
    _isInitialized = true;
    onError("SHT21 Sensor not found.");
    notifyListeners();
  }

  void toggleDataCollection() {
    if (isRunning) {
      _stopReading();
    } else {
      _startReading();
    }
  }

  void toggleLooping() {
    isLooping = !isLooping;
    notifyListeners();
  }

  void setTimegap(int newTimegap) {
    timegapMs = newTimegap;
    if (isRunning) {
      _stopReading();
      _startReading();
    }
    notifyListeners();
  }

  void setNumberOfReadings(int readings) {
    numberOfReadings = readings;
    notifyListeners();
  }

  void clearData() {
    _timeData.clear();
    _tempRawData.clear();
    _humidityRawData.clear();
    tempChartData.clear();
    humidityChartData.clear();
    _currentTemp = 0.0;
    _currentHumidity = 0.0;
    notifyListeners();
  }

  void _startReading() {
    if (!_isSensorAvailable || _sensor == null) return;

    isRunning = true;
    if (_timeData.isEmpty) {
      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    } else {
      double now = DateTime.now().millisecondsSinceEpoch / 1000.0;
      double timePaused = now - _startTime - _timeData.last;
      _startTime += timePaused;
    }

    _readTimer?.cancel();
    _readTimer =
        Timer.periodic(Duration(milliseconds: timegapMs), (timer) async {
      if (!isRunning) return;

      if (_isFetching) return;
      _isFetching = true;

      try {
        _currentHumidity = await _sensor!.getHumidity();
        await Future.delayed(const Duration(milliseconds: 250));

        _currentTemp = await _sensor!.getTemperature();

        _updateChartData();
        notifyListeners();

        if (!isLooping && tempChartData.length >= numberOfReadings) {
          _stopReading();
        }
      } catch (e) {
        logger.e("$_tag: Error reading sensor data: $e");
      } finally {
        _isFetching = false;
      }
    });
    notifyListeners();
  }

  void _stopReading() {
    isRunning = false;
    _readTimer?.cancel();
    notifyListeners();
  }

  void _updateChartData() {
    double currentTime =
        (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;

    _timeData.add(currentTime);
    _tempRawData.add(_currentTemp);
    _humidityRawData.add(_currentHumidity);

    if (_timeData.length > numberOfReadings && !isLooping) return;

    if (isLooping && _timeData.length > numberOfReadings) {
      _timeData.removeAt(0);
      _tempRawData.removeAt(0);
      _humidityRawData.removeAt(0);
    }

    tempChartData.clear();
    humidityChartData.clear();
    for (int i = 0; i < _timeData.length; i++) {
      tempChartData.add(ChartDataPoint(_timeData[i], _tempRawData[i]));
      humidityChartData.add(ChartDataPoint(_timeData[i], _humidityRawData[i]));
    }
  }

  @override
  void dispose() {
    _stopReading();
    super.dispose();
  }
}
