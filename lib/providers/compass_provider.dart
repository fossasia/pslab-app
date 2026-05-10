import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:pslab/others/logger_service.dart';

import '../l10n/app_localizations.dart';
import 'locator.dart';
import 'compass_config_provider.dart';

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

  bool _isRecording = false;
  List<List<dynamic>> _recordedData = [];
  Timer? _recordTimer;

  bool _isPlayingBack = false;
  List<List<dynamic>>? _playbackData;
  int _playbackIndex = 0;
  Timer? _playbackTimer;
  bool _isPlaybackPaused = false;
  Function? onPlaybackEnd;
  double _playbackDegree = 0.0;

  CompassConfigProvider? _configProvider;
  Position? currentPosition;
  StreamSubscription? _locationStream;

  MagnetometerEvent get magnetometerEvent => _magnetometerEvent;
  AccelerometerEvent get accelerometerEvent => _accelerometerEvent;
  String get selectedAxis => _selectedAxis;
  double get currentDegree => _currentDegree;
  int get direction => _direction;
  double get smoothedHeading => _smoothedHeading;
  bool get isRecording => _isRecording;
  bool get isPlayingBack => _isPlayingBack;
  bool get isPlaybackPaused => _isPlaybackPaused;

  void setConfigProvider(CompassConfigProvider configProvider) {
    _configProvider = configProvider;
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
    _playbackTimer?.cancel();
  }

  Future<void> startPlayback(List<List<dynamic>> data) async {
    if (data.length <= 1) return;
    _isPlayingBack = true;
    _isPlaybackPaused = false;
    _playbackTimer?.cancel();
    _playbackData = data;
    _playbackIndex = 1;
    disposeSensors();
    _startPlaybackTimer();
    notifyListeners();
  }

  void _startPlaybackTimer() {
    if (_playbackIndex >= _playbackData!.length) {
      stopPlayback();
      return;
    }

    final currentRow = _playbackData![_playbackIndex];
    if (currentRow.length > 5) {
      final bx = double.tryParse(currentRow[2].toString()) ?? 0.0;
      final by = double.tryParse(currentRow[3].toString()) ?? 0.0;
      final bz = double.tryParse(currentRow[4].toString()) ?? 0.0;
      final degree = double.tryParse(currentRow[5].toString()) ?? 0.0;

      _magnetometerEvent = MagnetometerEvent(bx, by, bz, DateTime.now());
      _playbackDegree = degree;

      if (_selectedAxis == 'Z') {
        _currentDegree = -((_playbackDegree - 90) * pi / 180);
      } else {
        _currentDegree = -(_playbackDegree * pi / 180);
      }

      _playbackIndex++;
      notifyListeners();
    } else if (currentRow.length > 4) {
      final bx = double.tryParse(currentRow[2].toString()) ?? 0.0;
      final by = double.tryParse(currentRow[3].toString()) ?? 0.0;
      final bz = double.tryParse(currentRow[4].toString()) ?? 0.0;

      _magnetometerEvent = MagnetometerEvent(bx, by, bz, DateTime.now());
      _accelerometerEvent = AccelerometerEvent(0, 0, 9.8, DateTime.now());

      _updateCompassDirection();
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
    _playbackData = null;
    _playbackIndex = 0;
    _playbackDegree = 0.0;
    _magnetometerEvent = MagnetometerEvent(0, 0, 0, DateTime.now());
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

  Future<void> startRecording() async {
    if (_configProvider?.config.includeLocationData == true) {
      await _startGeoLocationUpdates();
    }
    _isRecording = true;
    _recordedData = [
      [
        'Timestamp',
        'DateTime',
        'Bx',
        'By',
        'Bz',
        'Degree',
        'Latitude',
        'Longitude'
      ]
    ];

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
      _recordedData.add([
        now.millisecondsSinceEpoch.toString(),
        dateFormat.format(now),
        _magnetometerEvent.x.toStringAsFixed(2),
        _magnetometerEvent.y.toStringAsFixed(2),
        _magnetometerEvent.z.toStringAsFixed(2),
        getDegreeForAxis(_selectedAxis).toStringAsFixed(1),
        _configProvider?.config.includeLocationData == true
            ? currentPosition?.latitude.toString() ?? 0
            : 0,
        _configProvider?.config.includeLocationData == true
            ? currentPosition?.longitude.toString() ?? 0
            : 0
      ]);
    });
    notifyListeners();
  }

  List<List<dynamic>> stopRecording() {
    _isRecording = false;
    _recordTimer?.cancel();
    _locationStream?.cancel();
    notifyListeners();
    return _recordedData;
  }

  @override
  void dispose() {
    disposeSensors();
    _recordTimer?.cancel();
    _locationStream?.cancel();
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
    if (_isPlayingBack) {
      return _playbackDegree;
    }

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
