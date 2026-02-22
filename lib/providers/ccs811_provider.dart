import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/sensors/ccs811.dart';
import 'package:pslab/providers/ccs811_config_provider.dart';

class CCS811Provider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final CCS811ConfigProvider _configProvider;

  int _currentECO2 = 0;
  int _currentTVOC = 0;

  final List<double> _eCO2Data = [];
  final List<double> _tvocData = [];
  final List<double> _timeData = [];

  final List<FlSpot> eCO2ChartData = [];
  final List<FlSpot> tvocChartData = [];

  Timer? _dataTimer;
  StreamSubscription? _locationStream;
  Position? currentPosition;

  double _startTime = 0;
  double _currentTime = 0;
  final int _chartMaxLength = 50;

  bool _sensorAvailable = false;
  bool _isRecording = false;
  List<List<dynamic>> _recordedData = [];

  CCS811? _ccs811;
  I2C? _i2c;
  ScienceLab? _scienceLab;
  Function(String)? onSensorError;

  Object? _lastUpdatePeriod;

  bool get sensorAvailable => _sensorAvailable;
  bool get isRecording => _isRecording;

  CCS811Provider(this._configProvider) {
    _lastUpdatePeriod = _configProvider.config.updatePeriod;
    _configProvider.addListener(_onConfigChanged);
  }

  void _onConfigChanged() {
    if (_sensorAvailable) {
      final currentPeriod = _configProvider.config.updatePeriod;
      if (currentPeriod != _lastUpdatePeriod) {
        _lastUpdatePeriod = currentPeriod;
        _reinitializeSensors();
      }
    }
  }

  void _reinitializeSensors() {
    disposeSensors();
    initializeSensors(
      onError: onSensorError,
      i2c: _i2c,
      scienceLab: _scienceLab,
    );
  }

  Future<void> initializeSensors({
    Function(String)? onError,
    I2C? i2c,
    ScienceLab? scienceLab,
  }) async {
    onSensorError = onError;
    _i2c = i2c;
    _scienceLab = scienceLab;

    if (_i2c == null || _scienceLab == null || !_scienceLab!.isConnected()) {
      onSensorError?.call(appLocalizations.pslabNotConnected);
      return;
    }

    try {
      _ccs811 = await CCS811.create(_i2c!, _scienceLab!);
      _sensorAvailable = true;
      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

      _startDataCollection();
      notifyListeners();
    } catch (e) {
      logger.e("Error initializing CCS811: $e");
      onSensorError?.call("Failed to initialize CCS811: $e");
      _sensorAvailable = false;
    }
  }

  void _startDataCollection() {
    int interval = _configProvider.config.updatePeriod;
    _dataTimer?.cancel();
    _dataTimer = Timer.periodic(Duration(milliseconds: interval), (
      timer,
    ) async {
      if (!_isReading) {
        await _readData();
      }
    });
  }

  bool _isReading = false;

  Future<void> _readData() async {
    if (_ccs811 == null || !_sensorAvailable || _isReading) return;

    _isReading = true;
    try {
      final data = await _ccs811!.getRawData();
      _currentECO2 = data['eCO2'] ?? 0;
      _currentTVOC = data['TVOC'] ?? 0;
      _currentTime =
          (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;

      _updateCharts();
      _recordDataIfEnabled();
      notifyListeners();
    } catch (e) {
      logger.e("Error reading CCS811 data: $e");
    } finally {
      _isReading = false;
    }
  }

  void _updateCharts() {
    _eCO2Data.add(_currentECO2.toDouble());
    _tvocData.add(_currentTVOC.toDouble());
    _timeData.add(_currentTime);

    if (_eCO2Data.length > _chartMaxLength) {
      _eCO2Data.removeAt(0);
      _tvocData.removeAt(0);
      _timeData.removeAt(0);
    }

    eCO2ChartData.clear();
    tvocChartData.clear();

    for (int i = 0; i < _eCO2Data.length; i++) {
      eCO2ChartData.add(FlSpot(_timeData[i], _eCO2Data[i]));
      tvocChartData.add(FlSpot(_timeData[i], _tvocData[i]));
    }
  }

  void _recordDataIfEnabled() {
    if (_isRecording) {
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
      _recordedData.add([
        now.millisecondsSinceEpoch.toString(),
        dateFormat.format(now),
        _currentECO2.toString(),
        _currentTVOC.toString(),
        _configProvider.config.includeLocationData
            ? currentPosition?.latitude.toString() ?? 0
            : 0,
        _configProvider.config.includeLocationData
            ? currentPosition?.longitude.toString() ?? 0
            : 0,
      ]);
    }
  }

  Future<void> startRecording() async {
    if (_configProvider.config.includeLocationData) {
      await _startGeoLocationUpdates();
    }
    _isRecording = true;
    _recordedData = [
      ['Timestamp', 'DateTime', 'eCO2', 'TVOC', 'Latitude', 'Longitude'],
    ];
    notifyListeners();
  }

  void stopRecording() {
    _isRecording = false;
    _locationStream?.cancel();
    notifyListeners();
  }

  List<List<dynamic>> getRecordedData() => _recordedData;

  Future<void> _startGeoLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      logger.w('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        logger.w('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      logger.w(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
      return;
    }

    _locationStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).listen((Position position) {
          currentPosition = position;
        });
  }

  void disposeSensors() {
    _dataTimer?.cancel();
    _dataTimer = null;
    _locationStream?.cancel();
    _sensorAvailable = false;
    _ccs811 = null;
  }

  @override
  void dispose() {
    _configProvider.removeListener(_onConfigChanged);
    disposeSensors();
    super.dispose();
  }

  // Getters
  int get currentECO2 => _currentECO2;
  int get currentTVOC => _currentTVOC;

  List<FlSpot> getECO2ChartData() => eCO2ChartData;
  List<FlSpot> getTVOCChartData() => tvocChartData;

  double getMinTime() => _timeData.isNotEmpty ? _timeData.first : 0;
  double getMaxTime() => _timeData.isNotEmpty ? _timeData.last : 0;
  double getTimeInterval() => 10;
}
