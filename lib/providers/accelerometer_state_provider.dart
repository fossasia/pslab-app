import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/accelerometer_config_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:intl/intl.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/sensors/mpu6050.dart';
import 'package:pslab/providers/locator.dart';
// import 'package:pslab/communication/sensors/mpu925x.dart'; // TODO: Uncomment when merged

class AccelerometerStateProvider extends ChangeNotifier {
  AccelerometerEvent _accelerometerEvent =
      AccelerometerEvent(0, 0, 0, DateTime.now());
  StreamSubscription? _accelerometerSubscription;
  Timer? _externalSensorTimer;
  int _debugLogCounter = 0;

  MPU6050? _mpu6050;
  // MPU925X? _mpu925x; // TODO: Uncomment when merged

  final List<double> _xData = [];
  final List<double> _yData = [];
  final List<double> _zData = [];

  final List<FlSpot> xData = [const FlSpot(0, 0)];
  final List<FlSpot> yData = [const FlSpot(0, 0)];
  final List<FlSpot> zData = [const FlSpot(0, 0)];

  final int _maxLength = 50;
  double _xMin = 0, _xMax = 0;
  double _yMin = 0, _yMax = 0;
  double _zMin = 0, _zMax = 0;
  bool _isRecording = false;
  bool _isPlayingBack = false;
  List<List<dynamic>>? _playbackData;
  int _playbackIndex = 0;
  Timer? _playbackTimer;
  bool _isPlaybackPaused = false;
  List<List<dynamic>> _recordedData = [];

  bool get isRecording => _isRecording;
  bool get isPlayingBack => _isPlayingBack;
  bool get isPlaybackPaused => _isPlaybackPaused;

  AccelerometerConfigProvider? _configProvider;
  StreamSubscription? _locationStream;
  Position? currentPosition;
  Function? onPlaybackEnd;

  double? get _currentHighLimit => _configProvider?.config.highLimit.toDouble();
  double? get _currentLowLimit => _configProvider?.config.lowLimit.toDouble();

  void setConfigProvider(AccelerometerConfigProvider configProvider) {
    _configProvider = configProvider;
  }

  AccelerometerConfigProvider? get configProvider => _configProvider;

  Future<void> _startGeoLocationUpdates() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      await _locationStream?.cancel();

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 5,
      );

      _locationStream = Stream.periodic(const Duration(seconds: 6))
          .asyncMap((_) =>
              Geolocator.getCurrentPosition(locationSettings: locationSettings))
          .listen((Position position) {
        currentPosition = position;
      });
    } catch (e) {
      logger.e('Error starting location updates: $e');
    }
  }

  Future<void> initializeSensors({I2C? i2c, ScienceLab? scienceLab}) async {
    logger.i("=> initializeSensors() triggered!");

    _accelerometerSubscription?.cancel();
    _externalSensorTimer?.cancel();

    String selectedSensor =
        _configProvider?.config.activeSensor ?? 'In-built Sensor';
    logger.i("Active Sensor from Config: $selectedSensor");

    if (selectedSensor == 'In-built Sensor') {
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          logger.i("Starting Built-in Accelerometer Stream...");
          _accelerometerSubscription = accelerometerEventStream().listen(
            (event) {
              _accelerometerEvent = event;
              _updateData();
              notifyListeners();
            },
            onError: (error) =>
                logger.e("Built-in Accelerometer error: $error"),
            cancelOnError: true,
          );
        } catch (e) {
          logger.w("Failed to start built-in stream: $e");
        }
      } else {
        logger.w(
            "Ignoring Built-in Sensor: Not supported on Desktop environments.");
      }
    } else {
      logger.i("Attempting to mount External I2C Sensor: $selectedSensor");

      if (scienceLab == null) {
        try {
          scienceLab = getIt.get<ScienceLab>();
        } catch (e) {
          logger.e("Failed to fetch ScienceLab from locator: $e");
        }
      }

      if (i2c == null && scienceLab != null && scienceLab.isConnected()) {
        i2c = I2C(scienceLab.mPacketHandler);
      }

      if (i2c == null || scienceLab == null || !scienceLab.isConnected()) {
        logger.w("ABORT: PSLab device is disconnected or I2C unavailable.");
        return;
      }

      try {
        if (selectedSensor == 'MPU6050') {
          logger.i("Creating MPU6050 hardware instance...");
          _mpu6050 = await MPU6050.create(i2c, scienceLab);
          logger.i("MPU6050 Instance created successfully!");
        } else if (selectedSensor == 'MPU925X') {
          // _mpu925x = await MPU925X.create(i2c, scienceLab);
        }

        int period = _configProvider?.config.updatePeriod ?? 500;
        logger.i("Starting external sensor polling timer. Period: $period ms");

        _debugLogCounter = 0;
        _externalSensorTimer =
            Timer.periodic(Duration(milliseconds: period), (timer) async {
          await _fetchExternalSensorData();
        });
      } catch (e) {
        logger.e(
            'HARDWARE FAIL: Could not mount external I2C sensor ($selectedSensor). Error: $e');
      }
    }
  }

  Future<void> _fetchExternalSensorData() async {
    if (_isPlayingBack) return;
    String selectedSensor =
        _configProvider?.config.activeSensor ?? 'In-built Sensor';
    Map<String, double> rawData = {};

    try {
      if (selectedSensor == 'MPU6050' && _mpu6050 != null) {
        rawData = await _mpu6050!.getRawData();
      } else if (selectedSensor == 'MPU925X') {
        // rawData = await _mpu925x!.getRawData(); // TODO: Uncomment when merged
      } else {
        return;
      }

      if (_debugLogCounter % 10 == 0) {
        logger.d("POLL SUCCESS ($selectedSensor): $rawData");
      }
      _debugLogCounter++;

      double x = rawData['ax'] ?? 0.0;
      double y = rawData['ay'] ?? 0.0;
      double z = rawData['az'] ?? 0.0;

      _accelerometerEvent = AccelerometerEvent(x, y, z, DateTime.now());
      _updateData();
      notifyListeners();
    } catch (e) {
      logger.e('POLL ERROR: Failed to read raw data from $selectedSensor: $e');
    }
  }

  void disposeSensors() {
    logger.i("Disposing sensor streams/timers...");
    _accelerometerSubscription?.cancel();
    _externalSensorTimer?.cancel();
    _playbackTimer?.cancel();
  }

  @override
  void dispose() {
    _locationStream?.cancel();
    disposeSensors();
    super.dispose();
  }

  Future<void> startPlayback(List<List<dynamic>> data) async {
    if (data.length <= 1) return;
    _isPlayingBack = true;
    _isPlaybackPaused = false;
    disposeSensors();
    _xData.clear();
    _yData.clear();
    _zData.clear();
    xData.clear();
    yData.clear();
    zData.clear();
    _playbackData = data;
    _playbackIndex = 1;
    _startPlaybackTimer();
    notifyListeners();
  }

  void _startPlaybackTimer() {
    if (_playbackIndex >= _playbackData!.length) {
      stopPlayback();
      return;
    }

    final currentRow = _playbackData![_playbackIndex];
    if (currentRow.length > 4) {
      final x = double.tryParse(currentRow[2].toString()) ?? 0.0;
      final y = double.tryParse(currentRow[3].toString()) ?? 0.0;
      final z = double.tryParse(currentRow[4].toString()) ?? 0.0;

      _accelerometerEvent = AccelerometerEvent(x, y, z, DateTime.now());
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
          final clampedTimeDiff = timeDiff.clamp(100, 10000);
          interval = Duration(milliseconds: clampedTimeDiff);
        }
      } catch (_) {}
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
    _playbackData = null;
    _playbackIndex = 0;
    _xData.clear();
    _yData.clear();
    _zData.clear();
    xData.clear();
    yData.clear();
    zData.clear();
    _accelerometerEvent = AccelerometerEvent(0, 0, 0, DateTime.now());
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

  void _updateData() {
    final highLimit = _currentHighLimit;
    final lowLimit = _currentLowLimit;
    final gain = (_configProvider?.config.sensorGain ?? 1.0).toDouble();
    final bool shouldClip = !_isPlayingBack;

    double x = _accelerometerEvent.x * gain;
    double y = _accelerometerEvent.y * gain;
    double z = _accelerometerEvent.z * gain;

    if (shouldClip && highLimit != null && lowLimit != null) {
      x = x.clamp(-lowLimit, highLimit);
      y = y.clamp(-lowLimit, highLimit);
      z = z.clamp(-lowLimit, highLimit);
    }

    _accelerometerEvent = AccelerometerEvent(x, y, z, DateTime.now());

    if (_isRecording) {
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
      _recordedData.add([
        now.millisecondsSinceEpoch.toString(),
        dateFormat.format(now),
        x.toStringAsFixed(6),
        y.toStringAsFixed(6),
        z.toStringAsFixed(6),
        _configProvider!.config.includeLocationData
            ? currentPosition?.latitude.toString() ?? 0
            : 0,
        _configProvider!.config.includeLocationData
            ? currentPosition?.longitude.toString() ?? 0
            : 0
      ]);
    }

    _xData.add(x);
    _yData.add(y);
    _zData.add(z);

    if (_xData.length > _maxLength) _xData.removeAt(0);
    if (_yData.length > _maxLength) _yData.removeAt(0);
    if (_zData.length > _maxLength) _zData.removeAt(0);

    _xMin = _xData.reduce(min);
    _xMax = _xData.reduce(max);
    _yMin = _yData.reduce(min);
    _yMax = _yData.reduce(max);
    _zMin = _zData.reduce(min);
    _zMax = _zData.reduce(max);

    xData.clear();
    yData.clear();
    zData.clear();

    for (int i = 0; i < _xData.length; i++) {
      xData.add(FlSpot(i.toDouble(), _xData[i]));
      yData.add(FlSpot(i.toDouble(), _yData[i]));
      zData.add(FlSpot(i.toDouble(), _zData[i]));
    }
  }

  Future<void> startRecording() async {
    if (_configProvider!.config.includeLocationData) {
      await _startGeoLocationUpdates();
    }
    _isRecording = true;
    _recordedData = [
      [
        'Timestamp',
        'DateTime',
        'ReadingsX',
        'ReadingsY',
        'ReadingsZ',
        'Latitude',
        'Longitude'
      ]
    ];
    notifyListeners();
  }

  List<List<dynamic>> stopRecording() {
    _locationStream?.cancel();
    _isRecording = false;
    notifyListeners();
    return _recordedData;
  }

  List<FlSpot> getAxisData(String axis) {
    switch (axis) {
      case 'x':
        return xData;
      case 'y':
        return yData;
      case 'z':
        return zData;
      default:
        return [];
    }
  }

  double getMin(String axis) {
    switch (axis) {
      case 'x':
        return _xMin;
      case 'y':
        return _yMin;
      case 'z':
        return _zMin;
      default:
        return 0.0;
    }
  }

  double getMax(String axis) {
    switch (axis) {
      case 'x':
        return _xMax;
      case 'y':
        return _yMax;
      case 'z':
        return _zMax;
      default:
        return 0.0;
    }
  }

  double getCurrent(String axis) {
    switch (axis) {
      case 'x':
        return _accelerometerEvent.x;
      case 'y':
        return _accelerometerEvent.y;
      case 'z':
        return _accelerometerEvent.z;
      default:
        return 0.0;
    }
  }

  int getDataLength(String axis) {
    switch (axis) {
      case 'x':
        return xData.length;
      case 'y':
        return yData.length;
      case 'z':
        return zData.length;
      default:
        return 0;
    }
  }
}
