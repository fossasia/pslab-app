import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:pslab/others/logger_service.dart';

import '../l10n/app_localizations.dart';
import 'locator.dart';

class CompassProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  MagnetometerEvent _magnetometerEvent =
      MagnetometerEvent(0, 0, 0, DateTime.now());
  AccelerometerEvent _accelerometerEvent =
      AccelerometerEvent(0, 0, 0, DateTime.now());
  StreamSubscription? _magnetometerSubscription;
  StreamSubscription? _accelerometerSubscription;
  String _selectedAxis = 'X';
  double _currentDegree = 0.0;
  int _direction = 0;
  double _smoothedHeading = 0.0;

  MagnetometerEvent get magnetometerEvent => _magnetometerEvent;
  AccelerometerEvent get accelerometerEvent => _accelerometerEvent;
  String get selectedAxis => _selectedAxis;
  double get currentDegree => _currentDegree;
  int get direction => _direction;
  double get smoothedHeading => _smoothedHeading;

  void initializeSensors() {
    _magnetometerSubscription = magnetometerEventStream().listen(
      (event) {
        _magnetometerEvent = event;
        _updateCompassDirection();
        notifyListeners();
      },
      onError: (error) {
        logger.e("${appLocalizations.magnetometerError}: $error");
      },
      cancelOnError: false,
    );

    _accelerometerSubscription = accelerometerEventStream().listen(
      (event) {
        _accelerometerEvent = event;
        _updateCompassDirection();
        notifyListeners();
      },
      onError: (error) {
        logger.e("${appLocalizations.accelerometerError}: $error");
      },
      cancelOnError: false,
    );
  }

  void disposeSensors() {
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
  }

  @override
  void dispose() {
    disposeSensors();
    super.dispose();
  }

  void _updateCompassDirection() {
    double radians = _getRadiansForAxis(_selectedAxis);
    double degrees = radians * (180 / pi);
    if (degrees < 0) {
      degrees += 360;
    }

    degrees = (degrees - 90) % 360;
    if (degrees < 0) {
      degrees += 360;
    }

    const double alpha = 0.45;
    double angleDiff = degrees - _smoothedHeading;
    if (angleDiff > 180) {
      angleDiff -= 360;
    } else if (angleDiff < -180) {
      angleDiff += 360;
    }
    _smoothedHeading = _smoothedHeading + alpha * angleDiff;
    if (_smoothedHeading >= 360) {
      _smoothedHeading -= 360;
    } else if (_smoothedHeading < 0) {
      _smoothedHeading += 360;
    }
    switch (_selectedAxis) {
      case 'X':
        _currentDegree = -(_smoothedHeading * pi / 180);
        break;
      case 'Y':
        _currentDegree = ((_smoothedHeading - 10) * pi / 180);
        break;
      case 'Z':
        _currentDegree = -((_smoothedHeading + 90) * pi / 180);
        break;
    }
  }

  double _getRadiansForAxis(String axis) {
    double ax = _accelerometerEvent.x;
    double ay = _accelerometerEvent.y;
    double az = _accelerometerEvent.z;
    double mx = _magnetometerEvent.x;
    double my = _magnetometerEvent.y;
    double mz = _magnetometerEvent.z;

    double pitch = atan2(ay, sqrt(ax * ax + az * az));
    double roll = atan2(-ax, az);

    double xH = mx * cos(pitch) + mz * sin(pitch);
    double yH = mx * sin(roll) * sin(pitch) +
        my * cos(roll) -
        mz * sin(roll) * cos(pitch);
    double zH = -mx * cos(roll) * sin(pitch) +
        my * sin(roll) +
        mz * cos(roll) * cos(pitch);

    switch (axis) {
      case 'X':
        return atan2(yH, xH);
      case 'Y':
        return atan2(-xH, zH);
      case 'Z':
        return atan2(yH, -zH);
      default:
        return atan2(yH, xH);
    }
  }

  double getDegreeForAxis(String axis) {
    double radians = _getRadiansForAxis(axis);
    double degree = radians * (180 / pi);

    switch (axis) {
      case 'X':
        degree = (degree - 90) % 360;
        break;
      case 'Y':
        degree = (-degree + 100) % 360;
        break;
      case 'Z':
        degree = (degree + 90) % 360;
        break;
    }

    return degree < 0 ? degree + 360 : degree;
  }

  void onAxisSelected(String axis) {
    _selectedAxis = axis;
    switch (axis) {
      case 'X':
        _direction = 0;
        break;
      case 'Y':
        _direction = 1;
        break;
      case 'Z':
        _direction = 2;
        break;
    }
    notifyListeners();
  }
}
