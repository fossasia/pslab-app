import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/sensors/max30102.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/models/chart_data_points.dart';

class MAX30102Provider extends ChangeNotifier {
  MAX30102? _sensor;
  bool _isInitialized = false;
  bool _isDisposed = false;

  bool isRunning = false;
  bool isLooping = true;
  bool _isFetching = false;

  int _timegapMs = 200;
  int get timegapMs => _timegapMs < 200 ? 200 : _timegapMs;

  static const int internalSamplingsMs = 40;
  static const int minSamplesForCalc = 10;
  static const double fingerThreshold = 30000.0;

  int numberOfReadings = 100;
  int _currentStep = 0;
  Timer? _timer;
  int _startTimeMs = 0;

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

  final List<int> _sampleTimestampsMs = [];

  double _beatAvg = 0;
  double _spo2Avg = 0;

  Future<void> initializeSensors({
    required Function(String) onError,
    I2C? i2c,
    ScienceLab? scienceLab,
  }) async {
    if (i2c == null || scienceLab == null) {
      onError("Not Connected");
      return;
    }
    try {
      _sensor = await MAX30102.create(i2c, scienceLab);
      _isInitialized = true;
      if (!_isDisposed) notifyListeners();
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
    _isFetching = false;
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;

    _beatAvg = 0;
    _spo2Avg = 0;

    _timer = Timer.periodic(
      const Duration(milliseconds: internalSamplingsMs),
      (timer) async {
        if (_isFetching || _isDisposed) return;
        _isFetching = true;

        try {
          await _fetchData();
        } catch (e) {
          if (e.toString().contains("Expected")) {
            logger.w('MAX30102 dropped frame. Skipping gracefully...');
          } else {
            logger.e("Error fetching MAX30102 data: $e");
          }
        } finally {
          _isFetching = false;
        }
      },
    );

    if (!_isDisposed) notifyListeners();
  }

  void stopDataCollection() {
    isRunning = false;
    _timer?.cancel();
    if (!_isDisposed) notifyListeners();
  }

  Future<void> _fetchData() async {
    if (_isDisposed) return;

    var data = await _sensor!.getRawData();
    _redValue = (data['red'] ?? 0.0).toDouble();
    _irValue = (data['ir'] ?? 0.0).toDouble();

    if (_redValue >= 262140 || _irValue >= 262140) return;

    int nowMs = DateTime.now().millisecondsSinceEpoch;
    double currentTimeSec = (nowMs - _startTimeMs) / 1000.0;

    if (_irValue < fingerThreshold) {
      _calculatedBPM = 0;
      _calculatedSpO2 = 0;
      _beatAvg = 0;
      _spo2Avg = 0;
      _sampleTimestampsMs.clear();
      redData.clear();
      irData.clear();
      if (!_isDisposed) notifyListeners();
      return;
    }

    redData.add(ChartDataPoint(currentTimeSec, _redValue));
    irData.add(ChartDataPoint(currentTimeSec, _irValue));
    _sampleTimestampsMs.add(nowMs);

    if (redData.length > numberOfReadings) {
      redData.removeAt(0);
      irData.removeAt(0);
      _sampleTimestampsMs.removeAt(0);
    }
    if (irData.length >= minSamplesForCalc) {
      _calculateSpO2AndWindowBPM();
    }

    bpmData.add(ChartDataPoint(currentTimeSec, _calculatedBPM.toDouble()));
    spo2Data.add(ChartDataPoint(currentTimeSec, _calculatedSpO2.toDouble()));

    if (bpmData.length > numberOfReadings) {
      bpmData.removeAt(0);
      spo2Data.removeAt(0);
    }

    _currentStep++;

    if (!isLooping && _currentStep >= numberOfReadings) {
      stopDataCollection();
    }

    if (!_isDisposed) notifyListeners();
  }

  void _calculateSpO2AndWindowBPM() {
    final int windowSize = min(irData.length, 30);
    final int startIdx = irData.length - windowSize;

    double dcRed = 0.0;
    double dcIr = 0.0;
    for (int i = startIdx; i < irData.length; i++) {
      dcRed += redData[i].y;
      dcIr += irData[i].y;
    }
    dcRed /= windowSize;
    dcIr /= windowSize;

    double acRedSq = 0.0;
    double acIrSq = 0.0;
    for (int i = startIdx; i < irData.length; i++) {
      double rDiff = redData[i].y - dcRed;
      double irDiff = irData[i].y - dcIr;
      acRedSq += rDiff * rDiff;
      acIrSq += irDiff * irDiff;
    }

    double acRed = sqrt(acRedSq / windowSize);
    double acIr = sqrt(acIrSq / windowSize);

    if (dcRed <= 0 || dcIr <= 0 || acRed <= 0 || acIr <= 0) return;

    double r = (acRed / dcRed) / (acIr / dcIr);
    double spo2 = -45.060 * r * r + 30.354 * r + 94.845;
    int newSpO2 = spo2.clamp(70.0, 100.0).round();

    _spo2Avg =
        (_spo2Avg == 0) ? newSpO2.toDouble() : (_spo2Avg * 0.7 + newSpO2 * 0.3);
    _calculatedSpO2 = _spo2Avg.round();
    final List<double> detrended = List.filled(windowSize, 0.0);
    for (int i = 0; i < windowSize; i++) {
      int left = max(0, i - 2);
      int right = min(windowSize - 1, i + 2);
      double localSum = 0.0;
      for (int j = left; j <= right; j++) {
        localSum += irData[startIdx + j].y;
      }
      double localMean = localSum / (right - left + 1);
      detrended[i] = -(irData[startIdx + i].y - localMean);
    }

    final List<int> peakIndices = [];
    for (int i = 1; i < windowSize - 1; i++) {
      if (detrended[i] > 0 &&
          detrended[i] > detrended[i - 1] &&
          detrended[i] >= detrended[i + 1]) {
        peakIndices.add(i);
      }
    }
    if (peakIndices.length < 2) {
      peakIndices.clear();
      for (int i = 1; i < windowSize; i++) {
        if (detrended[i - 1] <= 0 && detrended[i] > 0) {
          peakIndices.add(i);
        }
      }
    }

    if (peakIndices.length >= 2) {
      int firstSampleIdx = startIdx + peakIndices.first;
      int lastSampleIdx = startIdx + peakIndices.last;

      int totalTimeMs = _sampleTimestampsMs[lastSampleIdx] -
          _sampleTimestampsMs[firstSampleIdx];
      int numIntervals = peakIndices.length - 1;

      if (totalTimeMs > 0 && numIntervals > 0) {
        double avgPeakIntervalMs = totalTimeMs / numIntervals;
        double rawBpm = 60000.0 / avgPeakIntervalMs;
        while (rawBpm > 10.0 && rawBpm < 55.0) {
          rawBpm *= 2.0;
        }
        while (rawBpm > 165.0) {
          rawBpm /= 2.0;
        }

        double validBpm = rawBpm.clamp(50.0, 160.0);
        _beatAvg =
            (_beatAvg == 0) ? validBpm : (_beatAvg * 0.7 + validBpm * 0.3);
        _calculatedBPM = _beatAvg.round();
        logger.i(
            "BPM Calculated: $_calculatedBPM (rawpeaks: ${peakIndices.length})");
      }
    }
  }

  void toggleLooping() {
    isLooping = !isLooping;
    if (!_isDisposed) notifyListeners();
  }

  void setTimegap(int gap) {
    _timegapMs = gap < 200 ? 200 : gap;
    if (!_isDisposed) notifyListeners();
  }

  void setNumberOfReadings(int num) {
    numberOfReadings = num;
    if (!_isDisposed) notifyListeners();
  }

  void clearData() {
    redData.clear();
    irData.clear();
    bpmData.clear();
    spo2Data.clear();
    _sampleTimestampsMs.clear();
    _currentStep = 0;
    _redValue = 0.0;
    _irValue = 0.0;
    _calculatedBPM = 0;
    _calculatedSpO2 = 0;
    _beatAvg = 0;
    _spo2Avg = 0;

    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
