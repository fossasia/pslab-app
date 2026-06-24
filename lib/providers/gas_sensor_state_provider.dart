import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/sensors/ccs811.dart';
import 'package:pslab/providers/gas_sensor_config_provider.dart';

import '../l10n/app_localizations.dart';
import 'locator.dart';

class GasSensorStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  ScienceLab? _scienceLab;
  CCS811? _ccs811;
  GasSensorConfigProvider? _configProvider;

  Function(String)? onSensorError;
  Function? onPlaybackEnd;

  String _lastActiveSensor = '';
  double _currentPpm = 0.0;
  Timer? _readTimer;

  final List<double> _ppmData = [];
  final List<double> _timeData = [];
  final List<FlSpot> _chartData = [];

  double _startTime = 0;
  double _currentTime = 0;
  final int _maxLength = 80;

  double _ppmMin = double.infinity;
  double _ppmMax = 0;
  double _ppmSum = 0;
  int _dataCount = 0;

  bool _isSensorAvailable = false;
  bool _isInitialized = false;
  bool _isFetching = false;
  bool _isCalibrating = false;

  bool _isRecording = false;
  List<List<dynamic>> _recordedData = [];
  bool _isPlayingBack = false;
  List<List<dynamic>>? _playbackData;
  int _playbackIndex = 0;
  Timer? _playbackTimer;
  bool _isPlaybackPaused = false;
  int? _playbackStartTimestamp;
  Position? currentPosition;
  StreamSubscription? _locationStream;

  bool get isPlayingBack => _isPlayingBack;
  bool get isPlaybackPaused => _isPlaybackPaused;
  bool get isRecording => _isRecording;

  final double _rLoad = 10.0;
  double _r0 = 41.7;
  final double _vcc = 5.0;

  final double _paramA = 109.0;
  final double _paramB = -2.88;

  void setConfigProvider(GasSensorConfigProvider configProvider) {
    _configProvider = configProvider;
  }

  double get _correction {
    double t = 20.0;
    double h = 0.65;
    double a = 3.28e-4;
    double b = -2.55e-2;
    double c = 1.38;
    double d = -2.24e-1;
    return (a * pow(t, 2)) + (b * t) + c + (d * (h - 0.65));
  }

  double _calculateRs(double voltage) {
    if (voltage <= 0.01) voltage = 0.01;
    return ((_vcc / voltage) - 1) * _rLoad / _correction;
  }

  void clearData() {
    _ppmData.clear();
    _timeData.clear();
    _chartData.clear();
    _ppmSum = 0;
    _dataCount = 0;
    _currentPpm = 0.0;
    _ppmMin = double.infinity;
    _ppmMax = 0.0;
    _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _currentTime = 0;
    notifyListeners();
  }

  Future<void> _startGeoLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      logger.w('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        logger.w('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      logger.w('Location permissions are permanently denied.');
      return;
    }

    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      currentPosition = position;
    });
  }

  Future<void> startRecording() async {
    if (!isSensorAvailable()) return;

    if (_configProvider?.config.includeLocationData == true) {
      await _startGeoLocationUpdates();
    }
    _isRecording = true;
    _recordedData = [
      ['Timestamp', 'DateTime', 'PPM/eCO2', 'Latitude', 'Longitude']
    ];
    notifyListeners();
  }

  List<List<dynamic>> stopRecording() {
    _locationStream?.cancel();
    _isRecording = false;
    notifyListeners();
    return _recordedData;
  }

  void startPlayback(List<List<dynamic>> data) {
    if (data.length <= 2) return;
    _playbackStartTimestamp = int.tryParse(data[2][0].toString())?.toInt();
    _isPlayingBack = true;
    _isPlaybackPaused = false;
    _playbackData = data;
    _playbackIndex = 1;

    _readTimer?.cancel();

    clearData();
    _startPlaybackTimer();
    notifyListeners();
  }

  void _startPlaybackTimer() {
    if (_playbackIndex >= _playbackData!.length) {
      stopPlayback();
      return;
    }

    final currentRow = _playbackData![_playbackIndex];
    if (currentRow.length > 2) {
      _currentPpm = double.tryParse(currentRow[2].toString()) ?? 0.0;
      final timestamp = int.tryParse(currentRow[0].toString())?.toInt();
      if (timestamp != null && _playbackStartTimestamp != null) {
        _currentTime = (timestamp - _playbackStartTimestamp!) / 1000.0;
      }
      _updateData();
      _playbackIndex++;
      notifyListeners();
    } else {
      _playbackIndex++;
      notifyListeners();
    }

    Duration interval = const Duration(seconds: 1);

    if (_playbackIndex < _playbackData!.length && _playbackIndex > 1) {
      try {
        final currentTimestamp =
            int.tryParse(_playbackData![_playbackIndex - 1][0].toString());
        final nextTimestamp =
            int.tryParse(_playbackData![_playbackIndex][0].toString());

        if (currentTimestamp != null && nextTimestamp != null) {
          final timeDiff = nextTimestamp - currentTimestamp;
          interval = Duration(milliseconds: timeDiff);
          if (interval.inMilliseconds < 100) {
            interval = const Duration(milliseconds: 100);
          } else if (interval.inMilliseconds > 10000) {
            interval = const Duration(seconds: 10);
          }
        }
      } catch (e) {
        interval = const Duration(seconds: 1);
      }
    }

    _playbackTimer = Timer(interval, () {
      if (_isPlayingBack && !_isPlaybackPaused) {
        _startPlaybackTimer();
      }
    });
  }

  Future<void> stopPlayback() async {
    _isPlayingBack = false;
    _isPlaybackPaused = false;
    _playbackTimer?.cancel();
    _playbackData = null;
    _playbackIndex = 0;

    clearData();
    onPlaybackEnd?.call();
  }

  void pausePlayback() {
    if (_isPlayingBack) {
      _isPlaybackPaused = true;
      _playbackTimer?.cancel();
      notifyListeners();
    }
  }

  void resumePlayback() {
    if (_isPlayingBack && _isPlaybackPaused) {
      _isPlaybackPaused = false;
      _startPlaybackTimer();
      notifyListeners();
    }
  }

  Future<void> initializeSensors() async {
    if (_isInitialized) return;

    try {
      _scienceLab = getIt.get<ScienceLab>();

      if (_scienceLab != null && _scienceLab!.isConnected()) {
        _isSensorAvailable = true;
        _isCalibrating = true;
        notifyListeners();

        await calibrateInFreshAir();
        _isCalibrating = false;

        startReadingData();
        logger.d('Gas sensors initialized successfully');
      } else {
        _isSensorAvailable = false;
        logger.w("ScienceLab not connected");
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      logger.e("Error initializing Gas sensors: $e");
      _isSensorAvailable = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> calibrateInFreshAir() async {
    if (_scienceLab == null || !_scienceLab!.isConnected()) return;
    List<double> rsReadings = [];

    for (int i = 0; i < 10; i++) {
      double volt = await _scienceLab!.getVoltage(appLocalizations.ch1, 1);
      if (volt > 4.99) volt = 4.99;
      rsReadings.add(_calculateRs(volt));
      await Future.delayed(const Duration(milliseconds: 100));
    }

    double avgRs = rsReadings.reduce((a, b) => a + b) / rsReadings.length;
    double ratioFactor = pow((400.0 / _paramA), (1.0 / -_paramB)).toDouble();
    _r0 = avgRs * ratioFactor;
    notifyListeners();
  }

  void startReadingData() async {
    _readTimer?.cancel();
    if (_configProvider == null || _isPlayingBack) return;

    final int intervalMs = _configProvider!.config.updatePeriod;
    final activeSensor = _configProvider!.config.activeSensor;

    if (_lastActiveSensor != activeSensor) {
      clearData();
      _lastActiveSensor = activeSensor;
    }

    if (activeSensor == 'CCS811' && _ccs811 == null && _scienceLab != null) {
      try {
        final i2c = I2C(_scienceLab!.mPacketHandler);
        _ccs811 = await CCS811.create(i2c, _scienceLab!);
      } catch (e) {
        logger.e("CCS811 Initialization Failed: $e");
        onSensorError?.call(appLocalizations.i2cError);
        _ccs811 = null;
        return;
      }
    }

    _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

    _readTimer =
        Timer.periodic(Duration(milliseconds: intervalMs), (timer) async {
      if (!isSensorAvailable() ||
          _isFetching ||
          _isCalibrating ||
          _isPlayingBack) {
        return;
      }

      _isFetching = true;

      try {
        double estimatedPpm = 0.0;

        if (activeSensor == 'CCS811' && _ccs811 != null) {
          final raw = await _ccs811!.getRawData();
          if (raw['eCO2'] == 65535) {
            throw Exception(appLocalizations.i2cError);
          }
          estimatedPpm = raw['eCO2']?.toDouble() ?? 0.0;
        } else if (activeSensor == 'MQ-135') {
          double volt = await _scienceLab!.getVoltage(appLocalizations.ch1, 1);
          if (volt > 4.99) volt = 4.99;
          double ratio = _calculateRs(volt) / _r0;
          estimatedPpm = _paramA * pow(ratio, _paramB);
        } else {
          return;
        }

        if (estimatedPpm < 0 || estimatedPpm.isNaN) estimatedPpm = 0;
        if (estimatedPpm > 10000) estimatedPpm = 10000;

        _currentPpm = estimatedPpm;
        _currentTime =
            (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;

        _updateData();
        notifyListeners();
      } catch (e) {
        logger.e("Gas sensor read error: $e");
        timer.cancel();
        onSensorError?.call(e.toString().replaceAll("Exception: ", ""));
      } finally {
        _isFetching = false;
      }
    });
  }

  void _updateData() {
    final double rawPpm = _currentPpm;
    final time = _currentTime;

    if (_isRecording) {
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
      _recordedData.add([
        now.millisecondsSinceEpoch.toString(),
        dateFormat.format(now),
        rawPpm.toStringAsFixed(2),
        _configProvider?.config.includeLocationData == true
            ? currentPosition?.latitude.toString() ?? 0
            : 0,
        _configProvider?.config.includeLocationData == true
            ? currentPosition?.longitude.toString() ?? 0
            : 0
      ]);
    }

    _ppmData.add(rawPpm);
    _timeData.add(time);
    _ppmSum += rawPpm;
    _dataCount++;

    if (_ppmData.length > _maxLength) {
      final removedValue = _ppmData.removeAt(0);
      _timeData.removeAt(0);
      _ppmSum -= removedValue;
      _dataCount--;
    }

    if (_ppmData.isNotEmpty) {
      _ppmMin = _ppmData.reduce(min);
      _ppmMax = _ppmData.reduce(max);
    }

    _chartData.clear();
    for (int i = 0; i < _ppmData.length; i++) {
      _chartData.add(FlSpot(_timeData[i], _ppmData[i]));
    }
  }

  void disposeSensors() {
    _locationStream?.cancel();
    _playbackTimer?.cancel();
    _readTimer?.cancel();
    _isInitialized = false;
  }

  @override
  void dispose() {
    disposeSensors();
    super.dispose();
  }

  bool isSensorAvailable() =>
      _isSensorAvailable && _scienceLab != null && _scienceLab!.isConnected();

  double getCurrentPpm() => _currentPpm;
  double getMinPpm() => _ppmMin == double.infinity ? 0 : _ppmMin;
  double getMaxPpm() => _ppmMax;
  double getAveragePpm() => _dataCount > 0 ? _ppmSum / _dataCount : 0.0;
  List<FlSpot> getChartData() =>
      _chartData.isEmpty ? [const FlSpot(0, 0)] : _chartData;
  double getCurrentTime() => _currentTime;
  double getMaxTime() => _timeData.isNotEmpty ? _timeData.last : 0;
  double getMinTime() => _timeData.isNotEmpty ? _timeData.first : 0;
  bool isInitialized() => _isInitialized;
  bool isCalibrating() => _isCalibrating;

  double getTimeInterval() {
    if (_currentTime <= 10) return 2;
    if (_currentTime <= 30) return 5;
    if (_currentTime <= 80) return 10;
    return 20;
  }
}
