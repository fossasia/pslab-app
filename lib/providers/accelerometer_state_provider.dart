import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/accelerometer_config_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class AccelerometerStateProvider extends ChangeNotifier {
  AccelerometerEvent _accelerometerEvent =
      AccelerometerEvent(0, 0, 0, DateTime.now());
  StreamSubscription? _accelerometerSubscription;
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
  List<List<dynamic>> _recordedData = [];
  bool get isRecording => _isRecording;
  late AccelerometerConfigProvider _configProvider;
  StreamSubscription? _locationStream;

  Position? currentPosition;

  void setConfigProvider(AccelerometerConfigProvider configProvider) {
    _configProvider = configProvider;
  }

  AccelerometerConfigProvider? get configProvider => _configProvider;

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

  void initializeSensors() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      (event) {
        _accelerometerEvent = event;
        _updateData();
        notifyListeners();
      },
      onError: (error) {
        logger.e(
          "Accelerometer error: $error",
        );
      },
      cancelOnError: true,
    );
  }

  void disposeSensors() {
    _accelerometerSubscription?.cancel();
  }

  @override
  void dispose() {
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
    disposeSensors();
    super.dispose();
  }

  void _updateData() {
    final x = _accelerometerEvent.x;
    final y = _accelerometerEvent.y;
    final z = _accelerometerEvent.z;
    if (_isRecording) {
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
      _recordedData.add([
        now.millisecondsSinceEpoch.toString(),
        dateFormat.format(now),
        x.toStringAsFixed(6),
        y.toStringAsFixed(6),
        z.toStringAsFixed(6),
        _configProvider.config.includeLocationData
            ? currentPosition?.latitude.toString() ?? 0
            : 0,
        _configProvider.config.includeLocationData
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

    notifyListeners();
  }

  Future<void> startRecording() async {
    if (_configProvider.config.includeLocationData) {
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
