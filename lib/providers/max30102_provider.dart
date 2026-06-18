import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/sensors/max30102.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/models/chart_data_points.dart';

class MAX30102Provider extends ChangeNotifier {
  MAX30102? _sensor;
  bool _isInitialized = false;

  bool isRunning = false;
  bool isLooping = true;

  int _timegapMs = 200;
  int get timegapMs => _timegapMs < 200 ? 200 : _timegapMs;

  int numberOfReadings = 100;
  int _currentStep = 0;
  Timer? _timer;

  double _redValue = 0.0;
  double _irValue = 0.0;
  double get redValue => _redValue;
  double get irValue => _irValue;

  int _calculatedBPM = 0;
  int _calculatedSpO2 = 0;
  int get calculatedBPM => _calculatedBPM;
  int get calculatedSpO2 => _calculatedSpO2;

  List<ChartDataPoint> redData = [];
  List<ChartDataPoint> irData = [];

  List<ChartDataPoint> bpmData = [];
  List<ChartDataPoint> spo2Data = [];

  Future<void> initializeSensors({
    required Function(String) onError,
    I2C? i2c,
    ScienceLab? scienceLab,
  }) async {
    if (i2c == null || scienceLab == null) {
      onError(appLocalizations.notConnected);
      return;
    }
    try {
      _sensor = await MAX30102.create(i2c, scienceLab);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      logger.e("Error initializing MAX30102: $e");
      onError(e.toString());
    }
  }

  void toggleDataCollection() {
    if (isRunning) {
      stopDataCollection();
    } else {
      startDataCollection();
    }
  }

  void startDataCollection() {
    if (!_isInitialized || _sensor == null) return;

    isRunning = true;
    _timer = Timer.periodic(Duration(milliseconds: timegapMs), (timer) {
      _fetchData();
    });

    notifyListeners();
  }

  void stopDataCollection() {
    isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  Future<void> _fetchData() async {
    try {
      var data = await _sensor!.getRawData();
      _redValue = data['red'] ?? 0.0;
      _irValue = data['ir'] ?? 0.0;

      if (_redValue >= 262140 || _irValue >= 262140) {
        return;
      }

      redData.add(ChartDataPoint(_currentStep.toDouble(), _redValue));
      irData.add(ChartDataPoint(_currentStep.toDouble(), _irValue));

      if (redData.length > numberOfReadings) {
        redData.removeAt(0);
        irData.removeAt(0);
      }

      _calculateMetrics();

      bpmData.add(
          ChartDataPoint(_currentStep.toDouble(), _calculatedBPM.toDouble()));
      spo2Data.add(
          ChartDataPoint(_currentStep.toDouble(), _calculatedSpO2.toDouble()));

      if (bpmData.length > numberOfReadings) {
        bpmData.removeAt(0);
        spo2Data.removeAt(0);
      }

      _currentStep++;

      if (!isLooping && _currentStep >= numberOfReadings) {
        stopDataCollection();
      }

      notifyListeners();
    } catch (e) {
      logger.e("Error fetching MAX30102 data: $e");
    }
  }

  void _calculateMetrics() {
    int requiredSamples = numberOfReadings ~/ 4;
    if (irData.length < requiredSamples) {
      logger.d(
          "Buffer filling: ${irData.length}/$requiredSamples before math starts.");
      return;
    }

    if (_irValue < 50000) {
      logger.d(" No finger detected. IR Value: ${_irValue.toInt()}");
      _calculatedBPM = 0;
      _calculatedSpO2 = 0;
      return;
    }

    try {
      double dcRed =
          redData.map((e) => e.y).reduce((a, b) => a + b) / redData.length;
      double dcIr =
          irData.map((e) => e.y).reduce((a, b) => a + b) / irData.length;

      double maxRed = redData.map((e) => e.y).reduce(max);
      double minRed = redData.map((e) => e.y).reduce(min);
      double acRed = maxRed - minRed;

      double maxIr = irData.map((e) => e.y).reduce(max);
      double minIr = irData.map((e) => e.y).reduce(min);
      double acIr = maxIr - minIr;

      if (dcRed > 0 && dcIr > 0 && acRed > 0 && acIr > 0) {
        double ratio = (acRed / dcRed) / (acIr / dcIr);
        double spo2 = 110.0 - (25.0 * ratio);
        _calculatedSpO2 = spo2.clamp(70.0, 99.0).toInt();
      }

      int peakCount = 0;
      int lastPeakIndex = -1;

      for (int i = 1; i < irData.length - 1; i++) {
        if (irData[i].y > irData[i - 1].y && irData[i].y > irData[i + 1].y) {
          if (lastPeakIndex == -1 || (i - lastPeakIndex) >= 2) {
            peakCount++;
            lastPeakIndex = i;
          }
        }
      }

      double timeWindowMinutes = (irData.length * timegapMs) / 60000.0;
      int newBpm = 0;
      if (timeWindowMinutes > 0) {
        newBpm = (peakCount / timeWindowMinutes).toInt();

        if (newBpm >= 40 && newBpm <= 180) {
          _calculatedBPM = newBpm;
          logger.i("BPM ACCEPTED: $_calculatedBPM");
        }
      }
    } catch (e) {
      logger.e("DSP Error: $e");
    }
  }

  void toggleLooping() {
    isLooping = !isLooping;
    notifyListeners();
  }

  void setTimegap(int gap) {
    _timegapMs = gap < 200 ? 200 : gap;
    notifyListeners();
  }

  void setNumberOfReadings(int num) {
    numberOfReadings = num;
    notifyListeners();
  }

  void clearData() {
    redData.clear();
    irData.clear();
    bpmData.clear();
    spo2Data.clear();
    _currentStep = 0;
    _redValue = 0.0;
    _irValue = 0.0;
    _calculatedBPM = 0;
    _calculatedSpO2 = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
