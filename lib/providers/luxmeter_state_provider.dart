import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:light/light.dart';

import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/luxmeter_config_provider.dart';
import 'package:pslab/providers/locator.dart';

import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/sensors/bh1750.dart';
import 'package:pslab/communication/sensors/tsl2561.dart';

class LuxMeterStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  double _currentLux = 0.0;
  StreamSubscription? _lightSubscription;
  Timer? _timeTimer;
  Timer? _luxTimer;

  final List<double> _luxData = [];
  final List<double> _timeData = [];
  final List<FlSpot> luxChartData = [];

  Light? _light;
  I2C? _i2c;
  ScienceLab? _scienceLab;

  BH1750? _bh1750;
  TSL2561? _tsl2561;

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

  Position? currentPosition;
  StreamSubscription? _locationStream;

  void setConfigProvider(LuxMeterConfigProvider configProvider) {
    _configProvider = configProvider;
    _configProvider?.addListener(_onConfigChanged);
    _onConfigChanged();
  }

  LuxMeterConfigProvider? get configProvider => _configProvider;

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

  void _onConfigChanged() async {
    if (_configProvider == null) return;
    final activeSensor = _configProvider!.config.activeSensor;

    disposeSensors();
    _resetLuxData();

    if (activeSensor == "In-built Sensor") {
      initializeInbuiltSensor(onError: onSensorError);
    } else if (activeSensor == "BH1750") {
      try {
        await initializeBH1750Sensor(onError: onSensorError);
      } catch (e) {
        _handleSensorError("BH1750 init failed: $e");
      }
    } else if (activeSensor == "TSL2561") {
      try {
        await initializeTSL2561Sensor(onError: onSensorError);
      } catch (e) {
        _handleSensorError("TSL2561 init failed: $e");
      }
    }
  }

  void initializeInbuiltSensor({Function(String)? onError}) {
    onSensorError = onError;
    try {
      _light = Light();
      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

      int intervalMs = _configProvider?.config.updatePeriod ?? 1000;

      double lastLux = 0.0;

      _lightSubscription = _light!.lightSensorStream.listen(
        (int luxValue) {
          lastLux = luxValue.toDouble();
          if (!_sensorAvailable) {
            _sensorAvailable = true;
          }
        },
        onError: (error) {
          logger.e("${appLocalizations.lightSensorError} $error");
          _handleSensorError(error);
        },
        cancelOnError: false,
      );

      _timeTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
        _currentTime =
            (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;
        _currentLux = lastLux;
        _updateData();
        notifyListeners();
      });
    } catch (e) {
      logger.e("${appLocalizations.lightSensorInitialError} $e");
      _handleSensorError(e);
    }
  }

  Future<void> initializeBH1750Sensor({Function(String)? onError}) async {
    onSensorError = onError;

    try {
      _scienceLab = getIt<ScienceLab>();
      if (_scienceLab == null || !_scienceLab!.isConnected()) {
        onSensorError?.call('ScienceLab not connected');
      }

      _i2c = I2C(_scienceLab!.mPacketHandler);
      _bh1750 = BH1750(_i2c!);

      int intervalMs = _configProvider?.config.updatePeriod ?? 1000;

      int gainValue = _configProvider?.config.sensorGain ?? 1000;
      String gainStr = "${gainValue}mLx";
      _bh1750!.setRange(gainStr);

      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

      int lastUpdate = 0;

      _luxTimer = Timer.periodic(Duration(milliseconds: 10), (timer) async {
        try {
          final lux = await _bh1750?.getRaw();
          if (lux != null) {
            _currentLux = lux;
            _sensorAvailable = true;

            double currentTime =
                (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;

            if ((currentTime * 1000 - lastUpdate) >= intervalMs) {
              lastUpdate = (currentTime * 1000).toInt();
              _currentTime = currentTime;
              _updateData();
              notifyListeners();
            }
          }
        } catch (e) {
          logger.e("BH1750 read error: $e");
          _handleSensorError(e);
        }
      });

      logger.d(
          'BH1750 initialized with gain $gainValue at interval $intervalMs ms');
    } catch (e) {
      logger.e("Error initializing BH1750: $e");
      _handleSensorError(e);
    }
  }

  Future<void> initializeTSL2561Sensor({Function(String)? onError}) async {
    onSensorError = onError;

    try {
      _scienceLab = getIt<ScienceLab>();
      if (_scienceLab == null || !_scienceLab!.isConnected()) {
        onSensorError?.call('ScienceLab not connected');
      }

      _i2c = I2C(_scienceLab!.mPacketHandler);
      _tsl2561 = TSL2561(_i2c!, _scienceLab!);

      int intervalMs = _configProvider?.config.updatePeriod ?? 1000;

      int gain = _configProvider?.config.sensorGain ?? 16;
      _tsl2561!.setGain(gain);

      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

      int lastUpdate = 0;

      _luxTimer = Timer.periodic(Duration(milliseconds: 10), (timer) async {
        try {
          final lux = await _tsl2561?.getRaw();
          if (lux != null) {
            _currentLux = lux;
            _sensorAvailable = true;

            double currentTime =
                (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;

            if ((currentTime * 1000 - lastUpdate) >= intervalMs) {
              lastUpdate = (currentTime * 1000).toInt();
              _currentTime = currentTime;
              _updateData();
              notifyListeners();
            }
          }
        } catch (e) {
          logger.e("TSL2561 read error: $e");
          _handleSensorError(e);
        }
      });

      logger
          .d('TSL2561 initialized with gain $gain at interval $intervalMs ms');
    } catch (e) {
      logger.e("Error initializing TSL2561: $e");
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
    _luxTimer?.cancel();

    _light = null;
    _bh1750 = null;
    _tsl2561 = null;
    _i2c = null;
    _scienceLab = null;
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
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
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
          _configProvider!.config.includeLocationData
              ? currentPosition?.latitude.toString() ?? 0
              : 0,
          _configProvider!.config.includeLocationData
              ? currentPosition?.longitude.toString() ?? 0
              : 0
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

  void _resetLuxData() {
    _luxData.clear();
    _timeData.clear();
    luxChartData.clear();
    _luxSum = 0;
    _dataCount = 0;
    _luxMin = 0;
    _luxMax = 0;
    _currentTime = 0;
    _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
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
