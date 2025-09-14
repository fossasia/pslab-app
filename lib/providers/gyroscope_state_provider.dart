import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:intl/intl.dart';

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

  bool get isListening => _gyroscopeSubscription != null;
  bool get isRecording => _isRecording;
  bool get isPlayingBack => _isPlayingBack;
  bool get isPlaybackPaused => _isPlaybackPaused;

  Function? onPlaybackEnd;

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
          'Skipping playback row at index $_playbackIndex due to insufficient columns (found ${currentRow.length}, expected at least 5');
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
    final x = _gyroscopeEvent.x;
    final y = _gyroscopeEvent.y;
    final z = _gyroscopeEvent.z;

    if (_isRecording) {
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
      _recordedData.add([
        now.millisecondsSinceEpoch.toString(),
        dateFormat.format(now),
        x.toStringAsFixed(6),
        y.toStringAsFixed(6),
        z.toStringAsFixed(6),
        0,
        0
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
    notifyListeners();
  }

  void startRecording() {
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
    _playbackTimer?.cancel();
    disposeSensors();
    super.dispose();
  }
}
