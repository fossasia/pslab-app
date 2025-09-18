import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:flutter/foundation.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/others/audio_jack.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pslab/providers/soundmeter_config_provider.dart';

class SoundMeterStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  double _currentDb = 0.0;
  Timer? _timeTimer;
  Timer? _audioTimer;
  final List<double> _dbData = [];
  final List<double> _timeData = [];
  final List<FlSpot> dbChartData = [];
  AudioJack? _audioJack;
  double _startTime = 0;
  double _currentTime = 0;
  final int _chartMaxLength = 50;
  double _dbMin = 0;
  double _dbMax = 0;
  double _dbSum = 0;
  int _dataCount = 0;
  bool _isRecording = false;
  List<List<dynamic>> _recordedData = [];
  bool _isPlayingBack = false;
  List<List<dynamic>>? _playbackData;
  int _playbackIndex = 0;
  Timer? _playbackTimer;
  bool _isPlaybackPaused = false;
  bool get isRecording => _isRecording;
  bool get isPlayingBack => _isPlayingBack;
  bool get isPlaybackPaused => _isPlaybackPaused;

  SoundMeterConfigProvider? _configProvider;

  Function(String)? onSensorError;
  Function? onPlaybackEnd;

  Position? currentPosition;
  StreamSubscription? _locationStream;

  void setConfigProvider(SoundMeterConfigProvider configProvider) {
    _configProvider = configProvider;
  }

  SoundMeterConfigProvider? get configProvider => _configProvider;

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
          'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).listen((Position position) {
      currentPosition = position;
    });
  }

  void initializeSensors({Function(String)? onError}) async {
    onSensorError = onError;

    try {
      PermissionStatus microphonePermission =
          await Permission.microphone.status;

      if (microphonePermission != PermissionStatus.granted) {
        microphonePermission = await Permission.microphone.request();
      }
      if (microphonePermission != PermissionStatus.granted) {
        if (microphonePermission == PermissionStatus.permanentlyDenied) {
          _handleSensorError("Microphone permission is permanently denied.");
          return;
        } else {
          return;
        }
      }

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
      logger.e("${appLocalizations.soundMeterInitialError} $e");
      _handleSensorError(e);
    }
  }

  void _handleSensorError(dynamic error) {
    onSensorError?.call(appLocalizations.soundmeterSnackBarMessage);
    logger.e("${appLocalizations.soundMeterInitialError} $error");
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

  void startPlayback(List<List<dynamic>> data) {
    if (data.length <= 1) return;

    _isPlayingBack = true;
    _isPlaybackPaused = false;
    _playbackData = data;
    _playbackIndex = 1;

    _timeTimer?.cancel();
    _audioTimer?.cancel();

    _dbData.clear();
    dbChartData.clear();
    _timeData.clear();
    _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _currentTime = 0;
    _dbSum = 0;
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
      _currentDb = double.tryParse(currentRow[2].toString()) ?? 0.0;
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

    _dbData.clear();
    dbChartData.clear();
    _timeData.clear();
    _dbSum = 0;
    _dataCount = 0;
    _currentDb = 0.0;
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
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
    _playbackTimer?.cancel();
    disposeSensors();
    super.dispose();
  }

  void _updateData() {
    final db = _currentDb;
    final time = _currentTime;
    if (_isRecording) {
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
      _recordedData.add([
        now.millisecondsSinceEpoch.toString(),
        dateFormat.format(now),
        db.toStringAsFixed(2),
        _configProvider!.config.includeLocationData
            ? currentPosition?.latitude.toString() ?? 0
            : 0,
        _configProvider!.config.includeLocationData
            ? currentPosition?.longitude.toString() ?? 0
            : 0
      ]);
    }
    _dbData.add(db);
    _timeData.add(time);
    _dbSum += db;
    _dataCount++;
    if (_dbData.length > _chartMaxLength) {
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

  Future<void> startRecording() async {
    if (_configProvider!.config.includeLocationData) {
      await _startGeoLocationUpdates();
    }
    _isRecording = true;
    _recordedData = [
      ['Timestamp', 'DateTime', 'Readings', 'Latitude', 'Longitude']
    ];
    notifyListeners();
  }

  List<List<dynamic>> stopRecording() {
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
    _isRecording = false;
    notifyListeners();
    return _recordedData;
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
