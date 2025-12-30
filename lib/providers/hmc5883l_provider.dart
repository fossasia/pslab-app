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
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  HMC5883L? _hmc5883l;
  Timer? _dataTimer;

  double _magneticX = 0.0;
  double _magneticY = 0.0;
  double _magneticZ = 0.0;
  double _heading = 0.0;
  double _magnitude = 0.0;

  final List<ChartDataPoint> _magneticXData = [];
  final List<ChartDataPoint> _magneticYData = [];
  final List<ChartDataPoint> _magneticZData = [];
  final List<ChartDataPoint> _headingData = [];
  final List<ChartDataPoint> _magnitudeData = [];

  bool _isRunning = false;
  bool _isLooping = false;
  int _timegapMs = 1000;
  int _numberOfReadings = 100;
  int _collectedReadings = 0;

  bool _isCalibrating = false;
  double _minX = double.infinity;
  double _maxX = double.negativeInfinity;
  double _minY = double.infinity;
  double _maxY = double.negativeInfinity;
  double _minZ = double.infinity;
  double _maxZ = double.negativeInfinity;

  double _currentTime = 0.0;
  static const int maxDataPoints = 1000;

  double get magneticX => _magneticX;
  double get magneticY => _magneticY;
  double get magneticZ => _magneticZ;
  double get heading => _heading;
  double get magnitude => _magnitude;

  List<ChartDataPoint> get magneticXData => List.unmodifiable(_magneticXData);
  List<ChartDataPoint> get magneticYData => List.unmodifiable(_magneticYData);
  List<ChartDataPoint> get magneticZData => List.unmodifiable(_magneticZData);
  List<ChartDataPoint> get headingData => List.unmodifiable(_headingData);
  List<ChartDataPoint> get magnitudeData => List.unmodifiable(_magnitudeData);

  bool get isRunning => _isRunning;
  bool get isLooping => _isLooping;
  bool get isCalibrating => _isCalibrating;
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
      logger.d("HMC5883L sensor initialized successfully");
      notifyListeners();
    } catch (e, stackTrace) {
      logger.e('Error initializing HMC5883L', error: e, stackTrace: stackTrace);
      onError('${appLocalizations.magnetometerError} ${e.toString()}');
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
    _currentTime = 0.0;

    _dataTimer =
        Timer.periodic(Duration(milliseconds: _timegapMs), (timer) async {
      try {
        await _fetchSensorData();
        _collectedReadings++;

        if (!_isLooping && _collectedReadings >= _numberOfReadings) {
          _stopDataCollection();
          return;
        }

        notifyListeners();
      } catch (e) {
        logger.e('Error fetching HMC5883L data: $e');
      }
    });
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
      final data = await _hmc5883l!.getAllData();

      _magneticX = data['magnetic_x'] ?? 0.0;
      _magneticY = data['magnetic_y'] ?? 0.0;
      _magneticZ = data['magnetic_z'] ?? 0.0;
      _heading = data['heading'] ?? 0.0;
      _magnitude = data['magnitude'] ?? 0.0;

      if (_isCalibrating) {
        _updateCalibrationData(_magneticX, _magneticY, _magneticZ);
      }

      _magneticXData.add(ChartDataPoint(_currentTime, _magneticX));
      _magneticYData.add(ChartDataPoint(_currentTime, _magneticY));
      _magneticZData.add(ChartDataPoint(_currentTime, _magneticZ));
      _headingData.add(ChartDataPoint(_currentTime, _heading));
      _magnitudeData.add(ChartDataPoint(_currentTime, _magnitude));

      if (_magneticXData.length > maxDataPoints) {
        _magneticXData.removeAt(0);
        _magneticYData.removeAt(0);
        _magneticZData.removeAt(0);
        _headingData.removeAt(0);
        _magnitudeData.removeAt(0);
      }

      _currentTime += _timegapMs / 1000.0;

      logger.d(
          'HMC5883L data: X=$_magneticX µT, Y=$_magneticY µT, Z=$_magneticZ µT, '
          'Heading=$_heading°, Magnitude=$_magnitude µT');
    } catch (e) {
      logger.e('Error fetching sensor data: $e');
    }
  }

  void _updateCalibrationData(double x, double y, double z) {
    if (x < _minX) _minX = x;
    if (x > _maxX) _maxX = x;
    if (y < _minY) _minY = y;
    if (y > _maxY) _maxY = y;
    if (z < _minZ) _minZ = z;
    if (z > _maxZ) _maxZ = z;
  }

  void startCalibration() {
    _isCalibrating = true;
    _minX = double.infinity;
    _maxX = double.negativeInfinity;
    _minY = double.infinity;
    _maxY = double.negativeInfinity;
    _minZ = double.infinity;
    _maxZ = double.negativeInfinity;

    if (!_isRunning) {
      _startDataCollection();
    }

    notifyListeners();
    logger.d("Started HMC5883L calibration");
  }

  void stopCalibration() {
    if (!_isCalibrating) return;

    _isCalibrating = false;

    if (_hmc5883l != null &&
        _minX != double.infinity &&
        _maxX != double.negativeInfinity) {
      _hmc5883l!.setCalibrationOffsets(
        _minX,
        _maxX,
        _minY,
        _maxY,
        _minZ,
        _maxZ,
      );

      logger.d("HMC5883L calibration completed and applied");
    }

    notifyListeners();
  }

  String getCalibrationStatus() {
    if (!_isCalibrating) {
      return "Not calibrating";
    }

    return "X: [${_minX.toStringAsFixed(1)}, ${_maxX.toStringAsFixed(1)}] µT\n"
        "Y: [${_minY.toStringAsFixed(1)}, ${_maxY.toStringAsFixed(1)}] µT\n"
        "Z: [${_minZ.toStringAsFixed(1)}, ${_maxZ.toStringAsFixed(1)}] µT";
  }

  void setTimegap(int ms) {
    _timegapMs = ms;
    if (_isRunning) {
      _stopDataCollection();
      _startDataCollection();
    }
    notifyListeners();
  }

  void setNumberOfReadings(int count) {
    _numberOfReadings = count;
    notifyListeners();
  }

  void toggleLooping() {
    _isLooping = !_isLooping;
    notifyListeners();
  }

  void clearData() {
    _magneticXData.clear();
    _magneticYData.clear();
    _magneticZData.clear();
    _headingData.clear();
    _magnitudeData.clear();
    _currentTime = 0.0;
    _collectedReadings = 0;
    notifyListeners();
  }

  Future<void> setGain(int gain) async {
    if (_hmc5883l == null) return;

    try {
      await _hmc5883l!.setGain(gain);
      logger.d("HMC5883L gain set to: $gain");
      notifyListeners();
    } catch (e) {
      logger.e("Error setting gain: $e");
    }
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    super.dispose();
  }
}
