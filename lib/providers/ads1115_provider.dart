import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import '../communication/sensors/ads1115.dart';
import '../l10n/app_localizations.dart';
import '../models/chart_data_points.dart';
import 'package:pslab/others/logger_service.dart';
import 'locator.dart';

class ADS1115Provider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get();

  ADS1115? _ads1115;
  Timer? _dataTimer;
  double _voltage = 0.0;
  String _currentGain = "GAIN_ONE";
  String _currentChannel = "UNI_0";
  int _currentRate = 128;

  final List<ChartDataPoint> _voltageData = [];

  bool _isRunning = false;
  bool _isLooping = false;
  int _timegapMs = 1000;
  int _numberOfReadings = 100;
  int _collectedReadings = 0;
  double _currentTime = 0.0;

  static const int maxDataPoints = 1000;

  double get voltage => _voltage;
  String get currentGain => _currentGain;
  String get currentChannel => _currentChannel;
  int get currentRate => _currentRate;
  List<ChartDataPoint> get voltageData => List.unmodifiable(_voltageData);
  bool get isRunning => _isRunning;
  bool get isLooping => _isLooping;
  int get timegapMs => _timegapMs;
  int get numberOfReadings => _numberOfReadings;
  int get collectedReadings => _collectedReadings;

  final List<String> availableGains = [
    "GAIN_TWOTHIRDS",
    "GAIN_ONE",
    "GAIN_TWO",
    "GAIN_FOUR",
    "GAIN_EIGHT",
    "GAIN_SIXTEEN",
  ];

  final List<String> availableChannels = [
    "UNI_0",
    "UNI_1",
    "UNI_2",
    "UNI_3",
    "DIFF_01",
    "DIFF_23",
  ];

  final List<int> availableRates = [8, 16, 32, 64, 128, 250, 475, 860];

  ADS1115Provider();

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

      _ads1115 = await ADS1115.create(i2c, scienceLab);
      _updateCurrentSettings();
      notifyListeners();
    } catch (e) {
      logger.e('Error initializing ADS1115: $e');
    }
  }

  void _updateCurrentSettings() {
    if (_ads1115 != null) {
      _currentGain = _ads1115!.currentGain;
      _currentChannel = _ads1115!.currentChannel;
      _currentRate = _ads1115!.currentRate;
    }
  }

  void setGain(String gain) {
    if (_ads1115 != null) {
      _ads1115!.setGain(gain);
      _currentGain = gain;
      notifyListeners();
    }
  }

  void setChannel(String channel) {
    if (_ads1115 != null) {
      _ads1115!.setChannel(channel);
      _currentChannel = channel;
      notifyListeners();
    }
  }

  void setRate(int rate) {
    if (_ads1115 != null) {
      _ads1115!.setDataRate(rate);
      _currentRate = rate;
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
    if (_ads1115 == null) return;

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

        if (_isLooping && _voltageData.length >= maxDataPoints) {
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
    if (_ads1115 == null) return;

    try {
      final rawData = await _ads1115!.getRawData();
      _voltage = rawData['voltage'] ?? 0.0;
      _currentTime += _timegapMs / 1000.0;

      _addDataPoint(_voltageData, _voltage);
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
    if (_voltageData.length > keepPoints) {
      final removeCount = _voltageData.length - keepPoints;
      _voltageData.removeRange(0, removeCount);
    }
  }

  void toggleLooping() {
    _isLooping = !_isLooping;
    notifyListeners();
  }

  void setTimegap(int timegapMs) {
    if (_timegapMs == timegapMs) {
      return;
    }
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
    _voltageData.clear();
    _voltage = 0.0;
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
