import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/communication/science_lab.dart';

import '../l10n/app_localizations.dart';
import 'locator.dart';

class GasSensorStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  ScienceLab? _scienceLab;

  double _currentPpm = 0.0;
  Timer? _readTimer;

  final List<double> _ppmData = [];
  final List<double> _timeData = [];
  final List<FlSpot> _gasChartData = [];

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

  final double _rLoad = 10.0;
  double _r0 = 41.7;
  final double _vcc = 5.0;

  final double _paramA = 109.0;
  final double _paramB = -2.88;

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

  Future<void> initializeSensors() async {
    if (_isInitialized) return;

    try {
      _scienceLab = getIt.get<ScienceLab>();

      if (_scienceLab != null && _scienceLab!.isConnected()) {
        _isSensorAvailable = true;
        _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

        _isCalibrating = true;
        notifyListeners();

        await calibrateInFreshAir();

        _isCalibrating = false;

        _startReadingGasData();
        logger.d('Gas sensor initialized successfully');
      } else {
        _isSensorAvailable = false;
        logger.w("ScienceLab not connected");
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      logger.e("Error initializing gas sensor: $e");
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

      double rs = _calculateRs(volt);
      rsReadings.add(rs);

      await Future.delayed(const Duration(milliseconds: 100));
    }

    double avgRs = rsReadings.reduce((a, b) => a + b) / rsReadings.length;

    double ratioFactor = pow((400.0 / _paramA), (1.0 / -_paramB)).toDouble();
    _r0 = avgRs * ratioFactor;

    notifyListeners();
  }

  void _startReadingGasData() {
    _readTimer?.cancel();

    _readTimer =
        Timer.periodic(const Duration(milliseconds: 2000), (timer) async {
      if (!_isSensorAvailable ||
          _scienceLab == null ||
          _isFetching ||
          _isCalibrating) {
        return;
      }

      _isFetching = true;

      try {
        double volt = await _scienceLab!.getVoltage(appLocalizations.ch1, 1);
        if (volt > 4.99) volt = 4.99;

        double rs = _calculateRs(volt);
        double ratio = rs / _r0;
        double ppm = _paramA * pow(ratio, _paramB);

        if (ppm < 0 || ppm.isNaN) ppm = 0;
        if (ppm > 10000) ppm = 10000;

        logger.d(
            "READING: Volt: ${volt.toStringAsFixed(3)}V | Rs: ${rs.toStringAsFixed(2)} | R0: ${_r0.toStringAsFixed(2)} | Ratio: ${ratio.toStringAsFixed(3)} | Est PPM: ${ppm.toStringAsFixed(1)}");

        _currentPpm = ppm;
        _currentTime =
            (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;

        _updateData();
        notifyListeners();
      } catch (e) {
        logger.e("Gas sensor read error: $e");
      } finally {
        _isFetching = false;
      }
    });
  }

  void disposeSensors() {
    _readTimer?.cancel();
    _isInitialized = false;
  }

  @override
  void dispose() {
    disposeSensors();
    super.dispose();
  }

  void _updateData() {
    _ppmData.add(_currentPpm);
    _timeData.add(_currentTime);
    _ppmSum += _currentPpm;
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

    _gasChartData.clear();
    for (int i = 0; i < _ppmData.length; i++) {
      _gasChartData.add(FlSpot(_timeData[i], _ppmData[i]));
    }
  }

  double getCurrentPpm() => _currentPpm;
  double getMinPpm() => _ppmMin == double.infinity ? 0 : _ppmMin;
  double getMaxPpm() => _ppmMax;
  double getAveragePpm() => _dataCount > 0 ? _ppmSum / _dataCount : 0.0;
  List<FlSpot> getGasChartData() =>
      _gasChartData.isEmpty ? [const FlSpot(0, 0)] : _gasChartData;
  int getDataLength() => _gasChartData.length;
  double getCurrentTime() => _currentTime;
  double getMaxTime() => _timeData.isNotEmpty ? _timeData.last : 0;
  double getMinTime() => _timeData.isNotEmpty ? _timeData.first : 0;
  bool isSensorAvailable() => _isSensorAvailable;
  bool isInitialized() => _isInitialized;

  bool isCalibrating() => _isCalibrating;

  double getTimeInterval() {
    if (_currentTime <= 10) return 2;
    if (_currentTime <= 30) return 5;
    if (_currentTime <= 80) return 10;
    return 20;
  }
}
