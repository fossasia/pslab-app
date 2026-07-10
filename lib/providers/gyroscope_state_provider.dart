import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pslab/providers/gyroscope_config_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:intl/intl.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/sensors/mpu6050.dart';
import 'package:pslab/providers/locator.dart';
// import 'package:pslab/communication/sensors/mpu925x.dart'; // TODO: Uncomment when merged

class GyroscopeProvider extends ChangeNotifier {
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  GyroscopeEvent _gyroscopeEvent = GyroscopeEvent(0, 0, 0, DateTime.now());
  Timer? _externalSensorTimer;
  int _debugLogCounter = 0;

  MPU6050? _mpu6050;
  // MPU925X? _mpu925x; // TODO: Uncomment when merged

  final List<double> _xData = [];
  final List<double> _yData = [];
  final List<double> _zData = [];

  final List<FlSpot> xData = [];
  final List<FlSpot> yData = [];
  final List<FlSpot> zData = [];

  final int _maxLength = 50;
  double _xMin = 0, _xMax = 0;
  double _yMin = 0, _yMax = 0;
  double _zMin = 0, _zMax = 0;

  bool _isRecording = false;
  List<List<dynamic>> _recordedData = [];

  bool _isPlayingBack = false;
  List<List<dynamic>>? _playbackData;
  int _playbackIndex = 0;
  Timer? _playbackTimer;
  bool _isPlaybackPaused = false;

  double get xValue => _gyroscopeEvent.x;
  double get yValue => _gyroscopeEvent.y;
  double get zValue => _gyroscopeEvent.z;

  double get xMin => _xMin;
  double get xMax => _xMax;
  double get yMin => _yMin;
  double get yMax => _yMax;
  double get zMin => _zMin;
  double get zMax => _zMax;

  bool get isListening =>
      _gyroscopeSubscription != null || _externalSensorTimer != null;
  bool get isRecording => _isRecording;
  bool get isPlayingBack => _isPlayingBack;
  bool get isPlaybackPaused => _isPlaybackPaused;

  GyroscopeConfigProvider? _configProvider;
  double? get _currentHighLimit => _configProvider?.config.highLimit.toDouble();
  double? get _currentLowLimit => _configProvider?.config.lowLimit.toDouble();
  Position? currentPosition;
  StreamSubscription? _locationStream;

  Function? onPlaybackEnd;

  void setConfigProvider(GyroscopeConfigProvider configProvider) {
    _configProvider = configProvider;
  }

  GyroscopeConfigProvider? get configProvider => _configProvider;

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

  Future<void> initializeSensors({I2C? i2c, ScienceLab? scienceLab}) async {
    logger.i("=> initializeSensors() triggered! (Gyroscope)");

    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = null;
    _externalSensorTimer?.cancel();
    _externalSensorTimer = null;

    String selectedSensor =
        _configProvider?.config.activeSensor ?? 'In-built Sensor';
    logger.i("Active Sensor from Config: $selectedSensor");

    if (selectedSensor == 'In-built Sensor') {
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          logger.i("Starting Built-in Gyroscope Stream...");
          _gyroscopeSubscription = gyroscopeEventStream().listen(
            (event) {
              _gyroscopeEvent = event;
              _updateData();
              notifyListeners();
            },
            onError: (error) {
              logger.e("Built-in Gyroscope error: $error");
            },
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

        int period = _configProvider?.config.updatePeriod ?? 1000;
        logger.i("Starting external sensor polling timer. Period: $period ms");

        _debugLogCounter = 0;
        _externalSensorTimer =
            Timer.periodic(Duration(milliseconds: period), (timer) async {
          await _fetchExternalSensorData();
        });
      } catch (e) {
        logger.e(
            'HARDWARE FAIL: Could not mount external I2C gyroscope ($selectedSensor). Error: $e');
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
        // rawData = await _mpu925x!.getRawData();
      } else {
        return;
      }

      if (_debugLogCounter % 10 == 0) {
        logger.d("POLL SUCCESS ($selectedSensor): $rawData");
      }
      _debugLogCounter++;

      double x = rawData['gx'] ?? 0.0;
      double y = rawData['gy'] ?? 0.0;
      double z = rawData['gz'] ?? 0.0;

      _gyroscopeEvent = GyroscopeEvent(x, y, z, DateTime.now());
      _updateData();
      notifyListeners();
    } catch (e) {
      logger.e('POLL ERROR: Failed to read raw data from $selectedSensor: $e');
    }
  }

  void disposeSensors() {
    logger.i("Disposing sensor streams/timers...");
    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = null;
    _externalSensorTimer?.cancel();
    _externalSensorTimer = null;
  }

  void startPlayback(List<List<dynamic>> data) {
    if (data.length <= 1) {
      logger.w("Playback skipped: insufficient data (length <= 1)");
      return;
    }

    _isPlayingBack = true;
    _isPlaybackPaused = false;
    _playbackData = data;
    _playbackIndex = 1;
    disposeSensors();
    _xData.clear();
    _yData.clear();
    _zData.clear();
    xData.clear();
    yData.clear();
    zData.clear();
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

      _gyroscopeEvent = GyroscopeEvent(x, y, z, DateTime.now());
      _updateData();
      _playbackIndex++;
      notifyListeners();
    } else {
      logger.e(
          'Skipping playback row at index $_playbackIndex due to insufficient columns.');
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

    _xData.clear();
    _yData.clear();
    _zData.clear();
    xData.clear();
    yData.clear();
    zData.clear();

    _gyroscopeEvent = GyroscopeEvent(0, 0, 0, DateTime.now());

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
    final gain = (_configProvider?.config.sensorGain ?? 1).toDouble();
    final bool shouldClip = !_isPlayingBack;

    final double x;
    final double y;
    final double z;

    if (shouldClip && highLimit != null && lowLimit != null) {
      x = (_gyroscopeEvent.x * gain).clamp(-lowLimit, highLimit).toDouble();
      y = (_gyroscopeEvent.y * gain).clamp(-lowLimit, highLimit).toDouble();
      z = (_gyroscopeEvent.z * gain).clamp(-lowLimit, highLimit).toDouble();
    } else {
      x = _gyroscopeEvent.x * gain;
      y = _gyroscopeEvent.y * gain;
      z = _gyroscopeEvent.z * gain;
    }

    _gyroscopeEvent = GyroscopeEvent(x, y, z, DateTime.now());
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

    if (_xData.isNotEmpty) {
      _xMin = _xData.reduce(min);
      _xMax = _xData.reduce(max);
    }
    if (_yData.isNotEmpty) {
      _yMin = _yData.reduce(min);
      _yMax = _yData.reduce(max);
    }
    if (_zData.isNotEmpty) {
      _zMin = _zData.reduce(min);
      _zMax = _zData.reduce(max);
    }

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
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
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
        return _gyroscopeEvent.x;
      case 'y':
        return _gyroscopeEvent.y;
      case 'z':
        return _gyroscopeEvent.z;
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

  @override
  void dispose() {
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
    _playbackTimer?.cancel();
    disposeSensors();
    super.dispose();
  }
}
