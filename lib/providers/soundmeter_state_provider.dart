import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:flutter/foundation.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/others/audio_jack.dart';

class SoundMeterStateProvider extends ChangeNotifier {
  double _currentDb = 0.0;
  Timer? _timeTimer;
  Timer? _audioTimer;
  final List<double> _dbData = [];
  final List<double> _timeData = [];
  final List<FlSpot> dbChartData = [];
  AudioJack? _audioJack;
  double _startTime = 0;
  double _currentTime = 0;
  final int _maxLength = 50;
  double _dbMin = 0;
  double _dbMax = 0;
  double _dbSum = 0;
  int _dataCount = 0;

  void initializeSensors() async {
    try {
      _audioJack = AudioJack();
      await _audioJack!.initialize();
      await _audioJack!.start();

      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

      _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _currentTime =
            (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;
        _updateData();
        notifyListeners();
      });

      _audioTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_audioJack != null && _audioJack!.isListening()) {
          final audioData = _audioJack!.read();
          if (audioData.isNotEmpty) {
            _currentDb = _calculateDecibels(audioData);
            notifyListeners();
          }
        }
      });
    } catch (e) {
      logger.e("$soundMeterInitialError $e");
    }
  }

  double _calculateDecibels(List<double> audioData) {
    if (audioData.isEmpty) return 0.0;

    double sum = 0;
    for (double sample in audioData) {
      sum += sample * sample;
    }
    double rms = sqrt(sum / audioData.length);

    if (rms <= 0) return 0.0;

    double dbFS = 20 * log(rms) / ln10;

    double dbSPL = dbFS + 94;

    return dbSPL.clamp(20.0, 120.0);
  }

  void disposeSensors() async {
    _timeTimer?.cancel();
    _audioTimer?.cancel();
    await _audioJack?.close();
    _audioJack = null;
  }

  @override
  void dispose() {
    disposeSensors();
    super.dispose();
  }

  void _updateData() {
    final db = _currentDb;
    final time = _currentTime;
    _dbData.add(db);
    _timeData.add(time);
    _dbSum += db;
    _dataCount++;
    if (_dbData.length > _maxLength) {
      final removedValue = _dbData.removeAt(0);
      _timeData.removeAt(0);
      _dbSum -= removedValue;
      _dataCount--;
    }
    if (_dbData.isNotEmpty) {
      _dbMin = _dbData.reduce(min);
      _dbMax = _dbData.reduce(max);
    }
    dbChartData.clear();
    for (int i = 0; i < _dbData.length; i++) {
      dbChartData.add(FlSpot(_timeData[i], _dbData[i]));
    }
    notifyListeners();
  }

  double getCurrentDb() => _currentDb;
  double getMinDb() => _dbMin;
  double getMaxDb() => _dbMax;
  double getAverageDb() => _dataCount > 0 ? _dbSum / _dataCount : 0.0;
  List<FlSpot> getDbChartData() => dbChartData;
  int getDataLength() => dbChartData.length;
  double getCurrentTime() => _currentTime;
  double getMaxTime() => _timeData.isNotEmpty ? _timeData.last : 0;
  double getMinTime() => _timeData.isNotEmpty ? _timeData.first : 0;
  double getTimeInterval() {
    if (_currentTime <= 10) return 2;
    if (_currentTime <= 30) return 5;
    return 10;
  }
}
