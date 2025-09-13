import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:light/light.dart';
import 'package:flutter/foundation.dart';
import 'package:pslab/providers/luxmeter_config_provider.dart';
import 'package:pslab/providers/locator.dart';

class LuxMeterStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  double _currentLux = 0.0;
  StreamSubscription? _lightSubscription;
  Timer? _timeTimer;
  final List<double> _luxData = [];
  final List<double> _timeData = [];
  final List<FlSpot> luxChartData = [];
  Light? _light;
  double _startTime = 0;
  double _currentTime = 0;
  final int _chartMaxLength = 50;
  double _luxMin = 0;
  double _luxMax = 0;
  double _luxSum = 0;
  int _dataCount = 0;
  bool _sensorAvailable = false;
  bool _isRecording = false;
  List<List<dynamic>> _recordedData = [];
  bool _isPlayingBack = false;
  List<List<dynamic>>? _playbackData;
  int _playbackIndex = 0;
  Timer? _playbackTimer;
  bool _isPlaybackPaused = false;
  bool get isPlayingBack => _isPlayingBack;
  bool get isPlaybackPaused => _isPlaybackPaused;
  bool get isRecording => _isRecording;

  LuxMeterConfigProvider? _configProvider;

  Function(String)? onSensorError;
  Function? onPlaybackEnd;

  void setConfigProvider(LuxMeterConfigProvider configProvider) {
    _configProvider = configProvider;
    _configProvider?.addListener(_onConfigChanged);
  }

  void _onConfigChanged() {
    if (_configProvider != null) {
      // TODO
    }
  }

  LuxMeterConfigProvider? get configProvider => _configProvider;

  void initializeSensors({Function(String)? onError}) {
    onSensorError = onError;

    try {
      _light = Light();
      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _currentTime =
            (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;
        _updateData();
        notifyListeners();
      });

      Timer sensorTimeout = Timer(const Duration(seconds: 3), () {
        if (!_sensorAvailable) {
          _handleSensorError(appLocalizations.lightSensorErrorLog);
        }
      });

      _lightSubscription = _light!.lightSensorStream.listen(
        (int luxValue) {
          _currentLux = luxValue.toDouble();
          if (!_sensorAvailable) {
            _sensorAvailable = true;
            sensorTimeout.cancel();
          }
          notifyListeners();
        },
        onError: (error) {
          logger.e("${appLocalizations.lightSensorError} $error");
          sensorTimeout.cancel();
          _handleSensorError(error);
        },
        cancelOnError: false,
      );
    } catch (e) {
      logger.e("${appLocalizations.lightSensorInitialError} $e");
      _handleSensorError(e);
    }
  }

  void _handleSensorError(dynamic error) {
    _sensorAvailable = false;
    onSensorError?.call(appLocalizations.noLightSensor);
    logger.e("${appLocalizations.lightSensorErrorDetails} $error");
  }

  void disposeSensors() {
    _lightSubscription?.cancel();
    _timeTimer?.cancel();
  }

  void startPlayback(List<List<dynamic>> data) {
    if (data.length <= 1) return;

    _isPlayingBack = true;
    _isPlaybackPaused = false;
    _playbackData = data;
    _playbackIndex = 1;

    _timeTimer?.cancel();
    _lightSubscription?.cancel();

    _luxData.clear();
    luxChartData.clear();
    _timeData.clear();
    _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _currentTime = 0;
    _luxSum = 0;
    _dataCount = 0;

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
      _currentLux = double.tryParse(currentRow[2].toString()) ?? 0.0;
      _currentTime = (_playbackIndex - 1).toDouble();
      _updateData();
      _playbackIndex++;
      notifyListeners();
    } else {
      logger.e(
          'Skipping playback row at index $_playbackIndex due to insufficient columns (found ${currentRow.length}, expected at least 3');
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

    _luxData.clear();
    luxChartData.clear();
    _timeData.clear();
    _luxSum = 0;
    _dataCount = 0;
    _currentLux = 0.0;
    _currentTime = 0;
    notifyListeners();
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

  @override
  void dispose() {
    _configProvider?.removeListener(_onConfigChanged);
    _playbackTimer?.cancel();
    disposeSensors();
    super.dispose();
  }

  void _updateData() {
    final lux = _sensorAvailable || _isPlayingBack ? _currentLux : null;
    final time = _currentTime;
    if (lux != null) {
      if (_isRecording) {
        final now = DateTime.now();
        final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
        _recordedData.add([
          now.millisecondsSinceEpoch.toString(),
          dateFormat.format(now),
          lux.toStringAsFixed(2),
          0,
          0
        ]);
      }

      _luxData.add(lux);
      _timeData.add(time);
      _luxSum += lux;
      _dataCount++;
    }
    if (_luxData.length > _chartMaxLength) {
      final removedValue = _luxData.removeAt(0);
      _timeData.removeAt(0);
      _luxSum -= removedValue;
      _dataCount--;
    }
    if (_luxData.isNotEmpty) {
      _luxMin = _luxData.reduce(min);
      _luxMax = _luxData.reduce(max);
    }
    luxChartData.clear();
    for (int i = 0; i < _luxData.length; i++) {
      luxChartData.add(FlSpot(_timeData[i], _luxData[i]));
    }
    notifyListeners();
  }

  void startRecording() {
    _isRecording = true;
    _recordedData = [
      ['Timestamp', 'DateTime', 'Readings', 'Latitude', 'Longitude']
    ];
    notifyListeners();
  }

  List<List<dynamic>> stopRecording() {
    _isRecording = false;
    notifyListeners();
    return _recordedData;
  }

  double getCurrentLux() => _currentLux;
  double getMinLux() => _luxMin;
  double getMaxLux() => _luxMax;
  double getAverageLux() => _dataCount > 0 ? _luxSum / _dataCount : 0.0;
  List<FlSpot> getLuxChartData() => luxChartData;
  int getDataLength() => luxChartData.length;
  double getCurrentTime() => _currentTime;
  double getMaxTime() => _timeData.isNotEmpty ? _timeData.last : 0;
  double getMinTime() => _timeData.isNotEmpty ? _timeData.first : 0;
  double getTimeInterval() {
    if (_currentTime <= 10) return 2;
    if (_currentTime <= 30) return 5;
    return 10;
  }
}
