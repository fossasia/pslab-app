import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/multimeter_config_provider.dart';

class MultimeterStateProvider extends ChangeNotifier {
  MultimeterConfigProvider? _configProvider;
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  late List<String> knobMarker;
  late int _selectedIndex = 0;
  late ScienceLab _scienceLab;

  late bool isSwitchChecked;
  late bool isContinuityChecked;

  late String value;
  late String unit;

  late bool _isProcessing;
  bool _isDisposed = false;

  Timer? _timer;
  AudioStream? _audioStream;
  bool _isBeeping = false;
  double _audioAngle = 0.0;

  bool _isPlayingBack = false;
  bool get isPlayingBack => _isPlayingBack;
  bool _isPlaybackPaused = false;
  bool get isPlaybackPaused => _isPlaybackPaused;
  List<List<dynamic>>? _playbackData;
  int _playbackIndex = 0;
  Timer? _playbackTimer;
  Function? onPlaybackEnd;
  late bool _isRecording;
  bool get isRecording => _isRecording;
  List<List<dynamic>> _recordedData = [];
  int _currentPulseCount = 0;
  Position? currentPosition;
  StreamSubscription? _locationStream;

  MultimeterStateProvider() {
    _selectedIndex = 0;
    _scienceLab = getIt<ScienceLab>();
    isSwitchChecked = false;
    isContinuityChecked = false;
    value = appLocalizations.defaultValue;
    unit = appLocalizations.unitVolts;
    knobMarker = [
      appLocalizations.knobMarkerCh1,
      appLocalizations.knobMarkerCap,
      appLocalizations.knobMarkerVol,
      appLocalizations.knobMarkerRes,
      appLocalizations.knobMarkerCap,
      appLocalizations.knobMarkerLa1,
      appLocalizations.knobMarkerLa2,
      appLocalizations.knobMarkerLa3,
      appLocalizations.knobMarkerLa4,
      appLocalizations.knobMarkerCh3,
      appLocalizations.knobMarkerCh2,
    ];
    _isProcessing = false;
    _isRecording = false;
  }

  void setConfigProvider(MultimeterConfigProvider multimeterConfigProvider) {
    _configProvider = multimeterConfigProvider;
    _configProvider?.addListener(_onConfigChanged);
    _onConfigChanged();
  }

  void _onConfigChanged() async {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    logData();
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
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).listen((Position position) {
      currentPosition = position;
    });
  }

  int getSelectedIndex() => _selectedIndex;

  void setSelectedIndex(int index) {
    if (_selectedIndex == index) return;

    _selectedIndex = index;
    _currentPulseCount = 0;
    isSwitchChecked = false;
    setContinuitySwitch(false);
    value = "---";
    if (index >= 5 && index <= 8) {
      unit = appLocalizations.unitHz;
    } else if (index == 3) {
      unit = "\u2126";
    } else if (index == 1 || index == 4) {
      unit = "F";
    } else {
      unit = appLocalizations.unitVolts;
    }
    notifyListeners();
    logData();
  }

  void stepMode(int direction) {
    final count = knobMarker.length;
    setSelectedIndex((_selectedIndex + direction + count) % count);
  }

  void setSwitch(bool checked) {
    isSwitchChecked = checked;
    if (isSwitchChecked) {
      _currentPulseCount = 0;
    }
    notifyListeners();
  }

  void setContinuitySwitch(bool checked) {
    isContinuityChecked = checked;
    if (!checked) {
      _stopBeepingStream();
      _audioStream?.uninit();
      _audioStream = null;
    } else {
      if (_audioStream == null) {
        _audioStream = getAudioStream();
        _audioStream!
            .init(bufferMilliSec: 1000, channels: 1, sampleRate: 44100);
        _audioStream!.resume();
      }
    }
    notifyListeners();
  }

  Future<void> _startBeepingStream() async {
    if (_isBeeping) return;
    _isBeeping = true;

    if (_audioStream == null) {
      _audioStream = getAudioStream();
      _audioStream!.init(bufferMilliSec: 1000, channels: 1, sampleRate: 44100);
      _audioStream!.resume();
    }

    final int bufferSize = 4096;
    final double bufferDurationMs = (bufferSize / 44100.0) * 1000.0;
    final Float32List buffer = Float32List(bufferSize);

    double generatedAudioMs = 0.0;
    Stopwatch stopwatch = Stopwatch()..start();
    _audioAngle = 0.0;

    while (_isBeeping && _audioStream != null) {
      double elapsedRealTimeMs = stopwatch.elapsedMilliseconds.toDouble();

      if (generatedAudioMs - elapsedRealTimeMs < 300.0) {
        double increment = (2 * math.pi * 1000) / 44100.0;
        for (int i = 0; i < bufferSize; i++) {
          buffer[i] = 0.25 * math.sin(_audioAngle);
          _audioAngle += increment;
          if (_audioAngle >= 2 * math.pi) {
            _audioAngle -= 2 * math.pi;
          }
        }
        _audioStream!.push(buffer);
        generatedAudioMs += bufferDurationMs;
      } else {
        await Future.delayed(const Duration(milliseconds: 20));
      }

      if (elapsedRealTimeMs > generatedAudioMs) {
        generatedAudioMs = elapsedRealTimeMs;
      }
    }
  }

  void _stopBeepingStream() {
    _isBeeping = false;
  }

  void logData() {
    _timer?.cancel();
    if (_configProvider == null) return;
    _performMeasurement();
    _timer = Timer.periodic(
        Duration(milliseconds: _configProvider!.config.updatePeriod), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      _performMeasurement();
    });
  }

  Future<void> _performMeasurement() async {
    if (_isDisposed || _isProcessing || !_scienceLab.isConnected()) return;
    _isProcessing = true;
    int currentIndex = _selectedIndex;

    try {
      switch (currentIndex) {
        case 3:
          double? resistance;
          double? avgResistance = 0.0;
          int loops = 20;
          for (int i = 0; i < loops; i++) {
            resistance = await _scienceLab.getResistance();
            if (resistance == null) {
              avgResistance = null;
              break;
            } else {
              avgResistance = avgResistance! + resistance / loops;
            }
          }

          if (isContinuityChecked) {
            const double continuityThreshold = 50.0;
            if (avgResistance == null || avgResistance > continuityThreshold) {
              value = "OL";
              unit = "No Continuity";
              _stopBeepingStream();
            } else {
              value = avgResistance.toStringAsFixed(2);
              unit = "\u2126 (Continuity)";
              _startBeepingStream();
              HapticFeedback.heavyImpact();
            }
          } else {
            _stopBeepingStream();
            if (avgResistance == null) {
              value = "Infinity";
              unit = "\u2126";
            } else {
              if (avgResistance > 10e5) {
                value = (avgResistance / 10e5).toStringAsFixed(2);
                unit = "M\u2126";
              } else if (avgResistance > 10e2) {
                value = (avgResistance / 10e2).toStringAsFixed(2);
                unit = "k\u2126";
              } else if (avgResistance >= 0) {
                value = avgResistance.toStringAsFixed(2);
                unit = "\u2126";
              } else {
                value = "Cannot measure!";
                unit = "\u2126";
              }
            }
          }
          break;

        case 4:
        case 1:
          double? capacitance = await _scienceLab.getCapacitance();
          if (capacitance == null) {
            value = "Cannot measure!";
            unit = "pF";
          } else {
            if (capacitance < 1e-9) {
              value = (capacitance / 1e-12).toStringAsFixed(2);
              unit = "pF";
            } else if (capacitance < 1e-6) {
              value = (capacitance / 1e-9).toStringAsFixed(2);
              unit = "nF";
            } else if (capacitance < 1e-3) {
              value = (capacitance / 1e-6).toStringAsFixed(2);
              unit = "\u00B5F";
            } else if (capacitance < 1e-1) {
              value = (capacitance / 1e-3).toStringAsFixed(2);
              unit = "mF";
            } else {
              value = capacitance.toStringAsFixed(2);
              unit = "F";
            }
          }
          break;

        case 5:
        case 6:
        case 7:
        case 8:
          String channel = knobMarker[currentIndex];
          double frequency = await _scienceLab.getFrequency(channel);

          if (!isSwitchChecked) {
            value = frequency.toStringAsFixed(2);
            unit = appLocalizations.unitHz;
          } else {
            double elapsedSeconds =
                _configProvider!.config.updatePeriod / 1000.0;
            int newPulses = (frequency * elapsedSeconds).round();
            _currentPulseCount += newPulses;
            final formatter = NumberFormat('#,##0');
            value = formatter.format(_currentPulseCount);
            unit = "Pulses";
          }
          break;

        default:
          double? voltage =
              await _scienceLab.getVoltage(knobMarker[currentIndex], 1);
          value = voltage.toStringAsFixed(2);
          unit = appLocalizations.unitVolts;
      }

      if (_isDisposed) return;
      if (currentIndex == _selectedIndex) {
        if (_isRecording) {
          final now = DateTime.now();
          final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
          _recordedData.add([
            now.millisecondsSinceEpoch.toString(),
            dateFormat.format(now),
            _selectedIndex,
            value,
            unit,
            _configProvider!.config.includeLocationData
                ? currentPosition?.latitude.toString() ?? 0
                : 0,
            _configProvider!.config.includeLocationData
                ? currentPosition?.longitude.toString() ?? 0
                : 0
          ]);
        }
        notifyListeners();
      }
    } catch (e) {
      logger.e("Measurement error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  void _startPlaybackTimer() {
    if (_playbackIndex >= _playbackData!.length) {
      stopPlayback();
      return;
    }

    final currentRow = _playbackData![_playbackIndex];
    if (currentRow.length > 2) {
      _selectedIndex = int.tryParse(currentRow[2].toString()) ?? 0;
      value = currentRow[3].toString();
      unit = currentRow[4].toString();
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

    notifyListeners();
    onPlaybackEnd?.call();
  }

  void startPlayback(List<List<dynamic>> data) {
    if (data.length <= 1) return;

    _isPlayingBack = true;
    _isPlaybackPaused = false;
    _playbackData = data;
    _playbackIndex = 1;

    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }

    value = appLocalizations.defaultValue;
    unit = appLocalizations.unitVolts;
    _startPlaybackTimer();
    notifyListeners();
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

  Future<bool> startRecording() async {
    if (!_scienceLab.isConnected()) {
      return false;
    }
    if (_configProvider!.config.includeLocationData) {
      await _startGeoLocationUpdates();
    }
    _isRecording = true;
    _recordedData = [
      [
        'Timestamp',
        'DateTime',
        'Mode',
        'Reading',
        'Unit',
        'Latitude',
        'Longitude'
      ]
    ];
    notifyListeners();
    return true;
  }

  List<List<dynamic>> stopRecording() {
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
    _isRecording = false;
    notifyListeners();
    return _recordedData;
  }

  @override
  void dispose() {
    _isDisposed = true;

    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    if (_playbackTimer != null && _playbackTimer!.isActive) {
      _playbackTimer!.cancel();
    }
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
    _configProvider?.removeListener(_onConfigChanged);

    _stopBeepingStream();
    _audioStream?.uninit();

    super.dispose();
  }
}
