import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import 'package:pslab/others/logger_service.dart';
import 'package:pslab/others/temperature_service.dart';
import 'package:pslab/providers/thermometer_config_provider.dart';

import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/sensors/sht21.dart';

import '../l10n/app_localizations.dart';
import 'locator.dart';

class ThermometerStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  ThermometerConfigProvider? _configProvider;

  String _currentActiveSensor = 'In-built Sensor';
  SHT21? _sht21Sensor;
  bool _isFetchingSHT = false;

  double _currentTemperature = 0.0;
  Timer? _timeTimer;
  StreamSubscription<double>? _temperatureSubscription;
  final List<double> _temperatureData = [];
  final List<double> _timeData = [];
  final List<FlSpot> temperatureChartData = [];

  double _startTime = 0;
  double _currentTime = 0;
  final int _maxLength = 50;
  double _temperatureMin = 0;
  double _temperatureMax = 0;
  double _temperatureSum = 0;
  int _dataCount = 0;
  int? _playbackStartTimestamp;

  bool _isSensorAvailable = false;
  bool _isInitialized = false;
  int _currentUpdatePeriod = 1000;

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
  Function? onPlaybackEnd;

  Position? currentPosition;
  StreamSubscription? _locationStream;

  void setConfigProvider(ThermometerConfigProvider provider) {
    _configProvider?.removeListener(_onConfigChanged);
    _configProvider = provider;
    _configProvider?.addListener(_onConfigChanged);
    _onConfigChanged();
  }

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

  void _onConfigChanged() {
    if (_configProvider != null) {
      int newPeriod = _configProvider!.config.updatePeriod;
      String newSensor = _configProvider!.config.activeSensor;

      bool needsTimerRestart = false;

      if (newPeriod != _currentUpdatePeriod) {
        _currentUpdatePeriod = newPeriod;
        needsTimerRestart = true;
      }

      if (newSensor != _currentActiveSensor || !_isSensorAvailable) {
        logger.d('Config triggered! Attempting to load: $newSensor');
        _currentActiveSensor = newSensor;

        if (_isInitialized && !_isPlayingBack) {
          _switchSensorSource();
        }
      }

      if (needsTimerRestart && _isInitialized && !_isPlayingBack) {
        _startTimeTracking();
      }

      _updateChartData();
      notifyListeners();
    }
  }

  double _convertTemp(double tempCelsius) {
    if (_configProvider?.config.unit == 'Fahrenheit') {
      return (tempCelsius * 9 / 5) + 32;
    }
    return tempCelsius;
  }

  Future<void> initializeSensors() async {
    if (_isInitialized) return;

    try {
      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

      _currentActiveSensor =
          _configProvider?.config.activeSensor ?? 'In-built Sensor';

      await _switchSensorSource();

      _startTimeTracking();
    } catch (e) {
      logger.e("${appLocalizations.temperatureSensorInitialError} $e");
      _isSensorAvailable = false;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _switchSensorSource() async {
    logger.d(' _switchSensorSource() called for: $_currentActiveSensor');
    try {
      await TemperatureService.stopTemperatureUpdates();
    } catch (e) {
      logger.w('Ignored native sensor stop error (Missing Plugin): $e');
    }

    _temperatureSubscription?.cancel();
    _sht21Sensor = null;

    if (_currentActiveSensor == 'In-built Sensor') {
      try {
        _isSensorAvailable =
            await TemperatureService.isTemperatureSensorAvailable();
        if (_isSensorAvailable) {
          final success = await TemperatureService.startTemperatureUpdates();
          if (success) {
            _startListeningToTemperature();
            logger.d('In-built sensor initialized successfully');
          } else {
            _isSensorAvailable = false;
          }
        }
      } catch (e) {
        _isSensorAvailable = false;
        logger.e('Failed to start in-built sensor: $e');
      }
    } else if (_currentActiveSensor == appLocalizations.sht21) {
      logger.d(' Starting SHT21 setup block...');
      try {
        ScienceLab? scienceLab;
        try {
          scienceLab = getIt<ScienceLab>();
        } catch (e) {
          logger.e('Failed to find ScienceLab in getIt locator: $e');
        }

        if (scienceLab == null) {
          _isSensorAvailable = false;
          logger.e('ScienceLab object is null!');
        } else if (!scienceLab.isConnected()) {
          _isSensorAvailable = false;
          logger.w(
              '🔌 ScienceLab device is NOT connected to the phone via USB/OTG.');
        } else {
          logger.d('ScienceLab connected. Initializing I2C...');

          I2C i2c = I2C(scienceLab.mPacketHandler);
          _sht21Sensor = SHT21(i2c);

          logger.d('Checking SHT21 hardware connection...');
          bool connected = await _sht21Sensor!.checkConnection();

          if (connected) {
            _isSensorAvailable = true;
            logger.d('SHT21 Hardware initialized successfully');
          } else {
            _isSensorAvailable = false;
            logger.e('SHT21 hardware connection failed (Check pins/wiring)');
          }
        }
      } catch (e) {
        _isSensorAvailable = false;
        logger.e('Error during SHT21 initialization: $e');
      }
    }

    if (!_isSensorAvailable) {
      logger.w(appLocalizations.temperatureSensorUnavailableMessage);
    }
    notifyListeners();
  }

  void _startListeningToTemperature() {
    _temperatureSubscription = TemperatureService.temperatureStream.listen(
      (temperature) {
        if (_isValidTemperature(temperature)) {
          _currentTemperature = temperature;
        }
      },
      onError: (error) => logger.e('Temperature stream error: $error'),
    );
  }

  bool _isValidTemperature(double temperature) {
    if (temperature.isNaN || temperature.isInfinite) return false;
    if (temperature < -273.15) return false;
    if (temperature > 200) return false;
    if (temperature.abs() > 1e10) return false;
    return true;
  }

  void _startTimeTracking() {
    _timeTimer?.cancel();
    _timeTimer = Timer.periodic(Duration(milliseconds: _currentUpdatePeriod),
        (timer) async {
      if (_currentActiveSensor == appLocalizations.sht21 &&
          _isSensorAvailable &&
          _sht21Sensor != null) {
        if (_isFetchingSHT) return;

        _isFetchingSHT = true;
        try {
          double temp = await _sht21Sensor!
              .getTemperature()
              .timeout(const Duration(milliseconds: 800));

          if (_isValidTemperature(temp)) {
            _currentTemperature = temp;
          }
        } on TimeoutException catch (_) {
          logger.e("SHT21 Read Error: I2C Timeout (Check wires!)");
        } catch (e) {
          logger.e("SHT21 Read Error: $e");
        } finally {
          _isFetchingSHT = false;
        }
      }

      _currentTime =
          (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;
      _updateData();
      notifyListeners();
    });
  }

  void disposeSensors() {
    _timeTimer?.cancel();
    _temperatureSubscription?.cancel();
    if (_currentActiveSensor == appLocalizations.inBuiltSensor) {
      try {
        TemperatureService.stopTemperatureUpdates();
      } catch (e) {
        logger.w('Ignored native sensor stop error on dispose: $e');
      }
    }
    _isInitialized = false;
  }

  Future<void> startRecording() async {
    if (_configProvider?.config.includeLocationData == true) {
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

  void startPlayback(List<List<dynamic>> data) {
    if (data.length <= 2) return;
    _playbackStartTimestamp = int.tryParse(data[2][0].toString())?.toInt();

    _isPlayingBack = true;
    _isPlaybackPaused = false;
    _playbackData = data;
    _playbackIndex = 1;

    disposeSensors();
    _resetTemperatureData();
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
      _currentTemperature = double.tryParse(currentRow[2].toString()) ?? 0.0;
      final timestamp = int.tryParse(currentRow[0].toString())?.toInt();
      if (timestamp != null && _playbackStartTimestamp != null) {
        _currentTime = (timestamp - _playbackStartTimestamp!) / 1000.0;
      } else {
        _currentTime = (_playbackIndex - 1).toDouble();
      }
      _updateData();
      _playbackIndex++;
      notifyListeners();
    } else {
      logger.e(
          'Skipping playback row at index $_playbackIndex due to insufficient columns');
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
    _playbackStartTimestamp = null;

    _resetTemperatureData();
    notifyListeners();
    onPlaybackEnd?.call();

    initializeSensors();
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

  void _resetTemperatureData() {
    _temperatureData.clear();
    _timeData.clear();
    temperatureChartData.clear();
    _temperatureSum = 0;
    _dataCount = 0;
    _temperatureMin = 0;
    _temperatureMax = 0;
    _currentTime = 0;
    _currentTemperature = 0;
    _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
  }

  @override
  void dispose() {
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
    _playbackTimer?.cancel();
    _configProvider?.removeListener(_onConfigChanged);
    disposeSensors();
    super.dispose();
  }

  void _updateData() {
    final double? rawTemp =
        (_isSensorAvailable || _isPlayingBack) ? _currentTemperature : null;
    final time = _currentTime;

    if (rawTemp != null) {
      if (_isRecording) {
        final now = DateTime.now();
        final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

        final tempToRecord = _convertTemp(rawTemp);

        _recordedData.add([
          now.millisecondsSinceEpoch.toString(),
          dateFormat.format(now),
          tempToRecord.toStringAsFixed(2),
          _configProvider?.config.includeLocationData == true
              ? currentPosition?.latitude.toString() ?? 0
              : 0,
          _configProvider?.config.includeLocationData == true
              ? currentPosition?.longitude.toString() ?? 0
              : 0
        ]);
      }

      _temperatureData.add(rawTemp);
      _timeData.add(time);
      _temperatureSum += rawTemp;
      _dataCount++;
    }

    if (_temperatureData.length > _maxLength) {
      final removedValue = _temperatureData.removeAt(0);
      _timeData.removeAt(0);
      _temperatureSum -= removedValue;
      _dataCount--;
    }

    if (_temperatureData.isNotEmpty) {
      _temperatureMin = _temperatureData.reduce(min);
      _temperatureMax = _temperatureData.reduce(max);
    }

    _updateChartData();
  }

  void _updateChartData() {
    temperatureChartData.clear();
    for (int i = 0; i < _temperatureData.length; i++) {
      temperatureChartData
          .add(FlSpot(_timeData[i], _convertTemp(_temperatureData[i])));
    }
  }

  double getCurrentTemperature() => _convertTemp(_currentTemperature);
  double getMinTemperature() => _convertTemp(_temperatureMin);
  double getMaxTemperature() => _convertTemp(_temperatureMax);
  double getAverageTemperature() =>
      _dataCount > 0 ? _convertTemp(_temperatureSum / _dataCount) : 0.0;
  List<FlSpot> getTemperatureChartData() => temperatureChartData;
  int getDataLength() => temperatureChartData.length;
  double getCurrentTime() => _currentTime;
  double getMaxTime() => _timeData.isNotEmpty ? _timeData.last : 0;
  double getMinTime() => _timeData.isNotEmpty ? _timeData.first : 0;
  bool isSensorAvailable() => _isSensorAvailable;
  bool isInitialized() => _isInitialized;

  double getTimeInterval() {
    if (_currentTime <= 10) return 2;
    if (_currentTime <= 30) return 5;
    return 10;
  }
}
