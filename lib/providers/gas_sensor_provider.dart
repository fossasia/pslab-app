import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/sensors/mq135.dart';
import 'package:pslab/models/chart_data_points.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/locator.dart';
import '../l10n/app_localizations.dart';

class GasSensorProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  // Sensor instance
  MQ135? _mq135;

  // Timer for periodic data collection
  Timer? _dataTimer;

  // Current readings
  double _gasPPM = 0.0;

  // State flags
  bool _isRunning = false;
  bool _isLooping = false;
  bool _isSensorAvailable = false;

  // Configuration
  int _timegapMs = 500; // Must be between 200-1000
  int _numberOfReadings = 100;
  int _collectedReadings = 0;

  // Data management
  double _currentTime = 0.0;
  final List<ChartDataPoint> _gasPPMData = [];
  static const int maxDataPoints = 1000;

  // Getters
  double get gasPPM => _gasPPM;
  bool get isRunning => _isRunning;
  bool get isLooping => _isLooping;
  bool get isSensorAvailable => _isSensorAvailable;
  int get timegapMs => _timegapMs;
  int get numberOfReadings => _numberOfReadings;
  int get collectedReadings => _collectedReadings;
  List<ChartDataPoint> get gasPPMData => List.unmodifiable(_gasPPMData);

  // Constructor
  GasSensorProvider();

  /// Initialize the gas sensor
  ///
  /// Sets up the MQ135 sensor interface and validates connection
  Future<void> initializeSensors({
    required ScienceLab? scienceLab,
    required Function(String)? onError,
  }) async {
    try {
      if (scienceLab == null) {
        _isSensorAvailable = false;
        onError?.call(appLocalizations.pslabNotConnected);
        logger.w('ScienceLab not available');
        return;
      }

      if (!scienceLab.isConnected()) {
        _isSensorAvailable = false;
        onError?.call(appLocalizations.pslabNotConnected);
        logger.w('ScienceLab not connected');
        return;
      }

      // Create MQ135 sensor instance
      _mq135 = await MQ135.create(scienceLab);
      _isSensorAvailable = true;

      logger.d('Gas Sensor Provider initialized successfully');
      notifyListeners();
    } catch (e) {
      _isSensorAvailable = false;

      final errorMessage = appLocalizations.gasSensorInitError(e.toString());

      logger.e(errorMessage);
      onError?.call(errorMessage);
      notifyListeners();
    }
  }

  /// Toggle data collection on/off
  void toggleDataCollection() {
    if (_isRunning) {
      _stopDataCollection();
    } else {
      _startDataCollection();
    }
    notifyListeners();
  }

  /// Start periodic data collection
  void _startDataCollection() {
    if (_mq135 == null || !_isSensorAvailable) {
      logger.w('Gas Sensor not available');
      return;
    }

    _isRunning = true;
    _collectedReadings = 0;
    _currentTime = 0.0;

    // Start periodic timer
    _dataTimer =
        Timer.periodic(Duration(milliseconds: _timegapMs), (timer) async {
      try {
        await _fetchSensorData();

        _collectedReadings++;

        // Stop if not looping and reached target readings
        if (!_isLooping && _collectedReadings >= _numberOfReadings) {
          _stopDataCollection();
        }

        // Remove old data points if in looping mode and exceeding limit
        if (_isLooping && _gasPPMData.length >= maxDataPoints) {
          _removeOldestDataPoints();
        }

        notifyListeners();
      } catch (e) {
        logger.e('Error fetching sensor data: $e');
      }
    });

    notifyListeners();
  }

  /// Stop data collection
  void _stopDataCollection() {
    _isRunning = false;
    _dataTimer?.cancel();
    _dataTimer = null;
    notifyListeners();
  }

  /// Fetch sensor data from MQ135
  Future<void> _fetchSensorData() async {
    if (_mq135 == null) return;

    try {
      final rawData = await _mq135!.getRawData();

      _gasPPM = rawData['ppm'] ?? 0.0;
      _currentTime += _timegapMs / 1000.0;

      _addDataPoint(_gasPPMData, _gasPPM);

      logger.d(
          'Gas Sensor: ${_gasPPM.toStringAsFixed(2)} PPM at ${_currentTime.toStringAsFixed(1)}s');
    } catch (e) {
      logger.e('Error in _fetchSensorData: $e');
      rethrow;
    }
  }

  /// Add a data point to the chart
  void _addDataPoint(List<ChartDataPoint> dataList, double value) {
    dataList.add(ChartDataPoint(_currentTime, value));

    // Keep only last 50 points for smooth visualization
    if (dataList.length > 50) {
      dataList.removeAt(0);
    }
  }

  /// Remove oldest data points when exceeding max capacity
  void _removeOldestDataPoints() {
    const keepPoints = 800;
    if (_gasPPMData.length > keepPoints) {
      final removeCount = _gasPPMData.length - keepPoints;
      _gasPPMData.removeRange(0, removeCount);
    }
  }

  /// Toggle looping mode
  void toggleLooping() {
    _isLooping = !_isLooping;
    notifyListeners();
  }

  /// Set time gap between readings (200-1000 ms)
  void setTimegap(int value) {
    if (value >= 200 && value <= 1000) {
      _timegapMs = value;

      // Restart collection with new timegap if running
      if (_isRunning) {
        _stopDataCollection();
        _startDataCollection();
      }

      notifyListeners();
    }
  }

  /// Set number of readings to collect
  void setNumberOfReadings(int value) {
    if (value > 0) {
      _numberOfReadings = value;
      notifyListeners();
    }
  }

  /// Clear all collected data
  void clearData() {
    _gasPPMData.clear();
    _gasPPM = 0.0;
    _currentTime = 0.0;
    _collectedReadings = 0;

    logger.d('Gas Sensor data cleared');
    notifyListeners();
  }

  /// Check if data collection is complete
  bool get isCollectionComplete {
    return !_isLooping && _collectedReadings >= _numberOfReadings;
  }

  @override
  void dispose() {
    _stopDataCollection();
    _mq135 = null;
    super.dispose();
  }
}
