import 'dart:async';
import 'package:flutter/foundation.dart';
import '../communication/peripherals/i2c.dart';
import '../communication/sensors/sht21.dart';
import '../models/chart_data_points.dart';
import '../others/logger_service.dart';

class SHT21Provider extends ChangeNotifier {
  SHT21? _sensor;
  Timer? _dataTimer;

  double _temperature = 0.0;
  double _humidity = 0.0;

  final List<ChartDataPoint> _temperatureData = [];
  final List<ChartDataPoint> _humidityData = [];

  bool _isRunning = false;
  bool _isLooping = false;
  int _timegapMs = 1000;
  int _numberOfReadings = 100;
  int _collectedReadings = 0;

  double _currentTime = 0.0;
  static const int maxDataPoints = 1000;

  double get temperature => _temperature;
  double get humidity => _humidity;

  List<ChartDataPoint> get temperatureData =>
      List.unmodifiable(_temperatureData);
  List<ChartDataPoint> get humidityData => List.unmodifiable(_humidityData);

  bool get isRunning => _isRunning;
  bool get isLooping => _isLooping;
  int get timegapMs => _timegapMs;
  int get numberOfReadings => _numberOfReadings;
  int get collectedReadings => _collectedReadings;

  SHT21Provider();

  void init(I2C i2c) {
    _sensor = SHT21(i2c);
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
        logger.e('Error fetching SHT21 sensor data: $e');
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
    if (_sensor == null) return;

    try {
      double temp = await _sensor!.getTemperature();
      double hum = await _sensor!.getHumidity();

      _temperature = temp;
      _humidity = hum;

      _currentTime += _timegapMs / 1000.0;

      _addDataPoint(_temperatureData, _temperature);
      _addDataPoint(_humidityData, _humidity);

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
      _humidityData.removeRange(0, removeCount);
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
    _humidityData.clear();
    _temperature = 0;
    _humidity = 0;
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
