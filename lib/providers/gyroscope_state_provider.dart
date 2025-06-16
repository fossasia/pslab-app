import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:pslab/others/logger_service.dart';

class GyroscopeProvider extends ChangeNotifier {
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  GyroscopeEvent _gyroscopeEvent = GyroscopeEvent(0, 0, 0, DateTime.now());

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

  double get xValue => _gyroscopeEvent.x;
  double get yValue => _gyroscopeEvent.y;
  double get zValue => _gyroscopeEvent.z;

  double get xMin => _xMin;
  double get xMax => _xMax;
  double get yMin => _yMin;
  double get yMax => _yMax;
  double get zMin => _zMin;
  double get zMax => _zMax;

  bool get isListening => _gyroscopeSubscription != null;

  void initializeSensors() {
    if (_gyroscopeSubscription != null) return;

    _gyroscopeSubscription = gyroscopeEventStream().listen(
      (event) {
        _gyroscopeEvent = event;
        _updateData();
        notifyListeners();
      },
      onError: (error) {
        logger.e("Gyroscope error: $error");
      },
      cancelOnError: true,
    );
  }

  void disposeSensors() {
    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = null;
  }

  void _updateData() {
    final x = _gyroscopeEvent.x;
    final y = _gyroscopeEvent.y;
    final z = _gyroscopeEvent.z;

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
    disposeSensors();
    super.dispose();
  }
}
