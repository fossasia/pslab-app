import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/sensors/bmp180.dart';
import 'package:pslab/providers/barometer_config_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';

class BarometerStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  double _currentPressure = 0.0;
  double _currentTemperature = 0.0;
  double? _currentAltitude;
  Timer? _timeTimer;
  Timer? _dataTimer;
  final List<double> _pressureData = [];
  final List<double> _timeData = [];
  final List<FlSpot> pressureChartData = [];
  double _startTime = 0;
  double _currentTime = 0;
  final int _chartMaxLength = 50;
  double _pressureMin = 0;
  double _pressureMax = 0;
  double _pressureSum = 0;
  int _dataCount = 0;
  bool _sensorAvailable = false;
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

  StreamSubscription? _barometerSubscription;

  BMP180? _bmp180Sensor;
  I2C? _i2c;
  ScienceLab? _scienceLab;

  final BarometerConfigProvider _configProvider;
  String _currentSensorType = 'In-built Sensor';

  Function(String)? onSensorError;
  Function? onPlaybackEnd;

  BarometerStateProvider(this._configProvider) {
    _configProvider.addListener(_onConfigChanged);
    _currentSensorType = _configProvider.config.activeSensor;
  }

  void _onConfigChanged() {
    final newSensorType = _configProvider.config.activeSensor;
    if (_currentSensorType != newSensorType) {
      logger
          .d("Sensor type changed from $_currentSensorType to $newSensorType");
      _currentSensorType = newSensorType;
      _reinitializeSensors();
    }
  }

  void _reinitializeSensors() {
    logger.d("Reinitializing sensors for $_currentSensorType");
    disposeSensors();
    _clearData();
    initializeSensors(
        onError: onSensorError, i2c: _i2c, scienceLab: _scienceLab);
  }

  void _clearData() {
    _pressureData.clear();
    _timeData.clear();
    pressureChartData.clear();
    _pressureSum = 0;
    _dataCount = 0;
    _pressureMin = 0;
    _pressureMax = 0;
    _currentPressure = 0.0;
    _currentTemperature = 0.0;
    _currentAltitude = null;
    _sensorAvailable = false;
    notifyListeners();
  }

  void initializeSensors(
      {Function(String)? onError, I2C? i2c, ScienceLab? scienceLab}) {
    onSensorError = onError;
    _i2c = i2c;
    _scienceLab = scienceLab;

    try {
      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _currentTime =
            (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;
        if (_sensorAvailable) {
          _updateData();
        }
        notifyListeners();
      });

      if (_currentSensorType == 'In-built Sensor') {
        _initializeBuiltInSensor();
      } else if (_currentSensorType == 'BMP180') {
        _initializeBMP180Sensor();
      }
    } catch (e) {
      logger.e("${appLocalizations.barometerSensorInitialError} $e");
      _handleSensorError(e);
    }
  }

  void _initializeBuiltInSensor() {
    Timer sensorTimeout = Timer(const Duration(seconds: 3), () {
      if (!_sensorAvailable) {
        _handleSensorError(appLocalizations.barometerSensorError);
      }
    });

    _barometerSubscription = barometerEventStream().listen(
      (BarometerEvent event) {
        _currentPressure = event.pressure / 1013.25;
        _currentAltitude = _pressureToAltitude(_currentPressure);
        _currentTemperature = 0.0;

        if (!_sensorAvailable) {
          _sensorAvailable = true;
          sensorTimeout.cancel();
          _startDataCollection();
        }
        notifyListeners();
      },
      onError: (error) {
        logger.e("${appLocalizations.barometerSensorError} $error");
        sensorTimeout.cancel();
        _handleSensorError(error);
      },
      cancelOnError: false,
    );
  }

  Future<bool> _checkBMP180Connection() async {
    if (_i2c == null) return false;

    try {
      int chipId = await _i2c!.readByte(BMP180.address, 0xD0);
      logger.d("BMP180 Chip ID: 0x${chipId.toRadixString(16)}");
      return chipId == 0x55;
    } catch (e) {
      logger.e("Error checking BMP180 connection: $e");
      return false;
    }
  }

  void _initializeBMP180Sensor() async {
    logger.d("Checking BMP180 sensor connection...");

    if (_i2c == null || _scienceLab == null) {
      logger.e("I2C or ScienceLab not provided for BMP180 sensor");
      _handleSensorError("I2C or ScienceLab not provided for BMP180 sensor");
      return;
    }

    if (!_scienceLab!.isConnected()) {
      logger.e("ScienceLab not connected");
      _handleSensorError("ScienceLab not connected");
      return;
    }
    bool isConnected = await _checkBMP180Connection();
    if (!isConnected) {
      logger.e(
          "BMP180 sensor not found at address 0x${BMP180.address.toRadixString(16)}");
      _handleSensorError("BMP180 sensor not connected or not responding");
      return;
    }

    try {
      _bmp180Sensor = await BMP180.create(_i2c!, _scienceLab!);
      _sensorAvailable = true;
      _startDataCollection();
      logger.d("BMP180 sensor initialized successfully");

      await _readBMP180Data();
      notifyListeners();
    } catch (e) {
      logger.e("Error initializing BMP180 sensor: $e");
      _handleSensorError("Failed to initialize BMP180 sensor: $e");
    }
  }

  void _startDataCollection() {
    if (_currentSensorType == 'BMP180') {
      final updatePeriod = _configProvider.config.updatePeriod;
      logger
          .d("Starting BMP180 data collection with period: ${updatePeriod}ms");

      _dataTimer?.cancel();
      _dataTimer =
          Timer.periodic(Duration(milliseconds: updatePeriod), (timer) async {
        await _readBMP180Data();
      });
    }
  }

  Future<void> _readBMP180Data() async {
    if (_bmp180Sensor == null || !_sensorAvailable) {
      logger.w("BMP180 sensor not available for reading");
      return;
    }

    try {
      final data = await _bmp180Sensor!.getRawData();
      _currentTemperature = data['temperature'] ?? 0.0;
      _currentPressure = (data['pressure'] ?? 0.0) / 101325.0;
      _currentAltitude = data['altitude'];

      logger.d(
          "BMP180 data - Temp: $_currentTemperature°C, Pressure: $_currentPressure atm, Altitude: $_currentAltitude m");
      notifyListeners();
    } catch (e) {
      logger.e("Error reading BMP180 data: $e");
      _handleSensorError("Error reading BMP180 data: $e");
    }
  }

  void _handleSensorError(dynamic error) {
    _sensorAvailable = false;
    onSensorError?.call(appLocalizations.barometerNotAvailable);
    logger.e("${appLocalizations.barometerSensorError} $error");
  }

  void startPlayback(List<List<dynamic>> data) {
    if (data.length <= 1) return;

    _isPlayingBack = true;
    _isPlaybackPaused = false;
    _playbackData = data;
    _playbackIndex = 1;

    _timeTimer?.cancel();
    _dataTimer?.cancel();

    _pressureData.clear();
    pressureChartData.clear();
    _timeData.clear();
    _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _currentTime = 0;
    _pressureSum = 0;
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
      _currentPressure = double.tryParse(currentRow[2].toString()) ?? 0.0;
      if (currentRow.length > 3) {
        _currentAltitude = double.tryParse(currentRow[3].toString());
      }
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

    _pressureData.clear();
    pressureChartData.clear();
    _timeData.clear();
    _pressureSum = 0;
    _dataCount = 0;
    _currentPressure = 0.0;
    _currentTemperature = 0.0;
    _currentAltitude = null;
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

  void disposeSensors() {
    logger.d("Disposing sensors...");
    _barometerSubscription?.cancel();
    _barometerSubscription = null;
    _timeTimer?.cancel();
    _timeTimer = null;
    _dataTimer?.cancel();
    _dataTimer = null;
    _playbackTimer?.cancel();
    _bmp180Sensor = null;
    _sensorAvailable = false;
  }

  @override
  void dispose() {
    _configProvider.removeListener(_onConfigChanged);
    _playbackTimer?.cancel();
    disposeSensors();
    super.dispose();
  }

  void _updateData() {
    if (!_sensorAvailable && !_isPlayingBack) return;

    final pressure = _currentPressure;
    final time = _currentTime;
    if (_isRecording) {
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
      _recordedData.add([
        now.millisecondsSinceEpoch.toString(),
        dateFormat.format(now),
        pressure.toStringAsFixed(2),
        getCurrentAltitude().toStringAsFixed(2),
        0,
        0
      ]);
    }
    _pressureData.add(pressure);
    _timeData.add(time);
    _pressureSum += pressure;
    _dataCount++;

    if (_pressureData.length > _chartMaxLength) {
      final removedValue = _pressureData.removeAt(0);
      _timeData.removeAt(0);
      _pressureSum -= removedValue;
      _dataCount--;
    }

    if (_pressureData.isNotEmpty) {
      _pressureMin = _pressureData.reduce(min);
      _pressureMax = _pressureData.reduce(max);
    }

    pressureChartData.clear();
    for (int i = 0; i < _pressureData.length; i++) {
      pressureChartData.add(FlSpot(_timeData[i], _pressureData[i]));
    }
    notifyListeners();
  }

  double _pressureToAltitude(double pressureAtm) {
    const double seaLevelPressureAtm = 1.0;
    const double temperatureK = 288.15;
    const double lapseRate = 0.0065;
    const double gasConstant = 287.05;
    const double gravity = 9.80665;

    if (pressureAtm <= 0) return 0.0;

    double altitude = (temperatureK / lapseRate) *
        (1 -
            pow(pressureAtm / seaLevelPressureAtm,
                (gasConstant * lapseRate) / gravity));

    return altitude;
  }

  void startRecording() {
    _isRecording = true;
    _recordedData = [
      ['Timestamp', 'DateTime', 'Pressure', 'Altitude', 'Latitude', 'Longitude']
    ];
    notifyListeners();
  }

  List<List<dynamic>> stopRecording() {
    _isRecording = false;
    notifyListeners();
    return _recordedData;
  }

  double getCurrentPressure() => _currentPressure;
  double getMinPressure() => _pressureMin;
  double getMaxPressure() => _pressureMax;
  double getAveragePressure() =>
      _dataCount > 0 ? _pressureSum / _dataCount : 0.0;

  double getCurrentAltitude() {
    if (_currentSensorType == 'BMP180' && _currentAltitude != null) {
      return _currentAltitude!;
    }
    return _pressureToAltitude(_currentPressure);
  }

  double getMinAltitude() =>
      _pressureMin > 0 ? _pressureToAltitude(_pressureMin) : 0.0;
  double getMaxAltitude() =>
      _pressureMax > 0 ? _pressureToAltitude(_pressureMax) : 0.0;
  double getAverageAltitude() => _pressureToAltitude(getAveragePressure());

  double getCurrentTemperature() => _currentTemperature;
  bool hasTemperatureData() => _currentSensorType == 'BMP180';

  double getMaxAltitudeForChart() =>
      _pressureMax > 0 ? _pressureToAltitude(0) : 10000.0;
  double getMinAltitudeForChart() =>
      _pressureMin > 0 ? _pressureToAltitude(_pressureMax * 1.1) : 0.0;
  double getAltitudeInterval() {
    double maxAlt = getMaxAltitudeForChart();
    return maxAlt > 0 ? (maxAlt / 5) : 2000;
  }

  List<FlSpot> getPressureChartData() => pressureChartData;
  int getDataLength() => pressureChartData.length;
  double getCurrentTime() => _currentTime;
  double getMaxTime() => _timeData.isNotEmpty ? _timeData.last : 0;
  double getMinTime() => _timeData.isNotEmpty ? _timeData.first : 0;
  double getTimeInterval() {
    if (_currentTime <= 10) return 2;
    if (_currentTime <= 30) return 5;
    return 10;
  }

  bool get sensorAvailable => _sensorAvailable;
  String get currentSensorType => _currentSensorType;
  bool get isBMP180Active => _currentSensorType == 'BMP180';
  bool get isBuiltInActive => _currentSensorType == 'In-built Sensor';
}
