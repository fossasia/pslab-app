import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/multimeter_config_provider.dart';

class MultimeterStateProvider extends ChangeNotifier {
  MultimeterConfigProvider? _configProvider;
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  late List<String> knobMarker;
  late int _selectedIndex = 0;
  late ScienceLab _scienceLab;
  late bool isSwitchChecked;
  late String value;
  late String unit;

  late bool _isProcessing;
  Timer? _timer;

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

  Position? currentPosition;
  StreamSubscription? _locationStream;

  MultimeterStateProvider() {
    _selectedIndex = 0;
    _scienceLab = getIt<ScienceLab>();
    isSwitchChecked = false;
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
    notifyListeners();
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
        'Location permissions are permanently denied, we cannot request permissions.',
      );
      return;
    }

    _locationStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).listen((Position position) {
          currentPosition = position;
        });
  }

  int getSelectedIndex() => _selectedIndex;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void toggleSwitch(bool value) {
    isSwitchChecked = value;
    notifyListeners();
  }

  Future<void> logData() async {
    _timer = Timer.periodic(
      Duration(milliseconds: _configProvider!.config.updatePeriod),
      (timer) async {
        if (_isProcessing) {
          return;
        }
        _isProcessing = true;

        if (_scienceLab.isConnected()) {
          switch (_selectedIndex) {
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
              String resistanceValue;
              String resistanceUnit;
              if (avgResistance == null) {
                resistanceValue = "Infinity";
                resistanceUnit = "\u2126";
              } else {
                if (avgResistance > 10e5) {
                  resistanceValue = (avgResistance / 10e5).toStringAsFixed(2);
                  resistanceUnit = "M\u2126";
                } else if (avgResistance > 10e2) {
                  resistanceValue = (avgResistance / 10e2).toStringAsFixed(2);
                  resistanceUnit = "k\u2126";
                } else if (avgResistance > 1) {
                  resistanceValue = avgResistance.toStringAsFixed(2);
                  resistanceUnit = "\u2126";
                } else {
                  resistanceValue = "Cannot measure!";
                  resistanceUnit = "\u2126";
                }
              }
              value = resistanceValue;
              unit = resistanceUnit;
              break;
            case 4:
              double? capacitance = await _scienceLab.getCapacitance();
              String capacitanceValue;
              String capacitanceUnit;
              if (capacitance == null) {
                capacitanceValue = "Cannot measure!";
                capacitanceUnit = "pF";
              } else {
                if (capacitance < 1e-9) {
                  capacitanceValue = (capacitance / 1e-12).toStringAsFixed(2);
                  capacitanceUnit = "pF";
                } else if (capacitance < 1e-6) {
                  capacitanceValue = (capacitance / 1e-9).toStringAsFixed(2);
                  capacitanceUnit = "nF";
                } else if (capacitance < 1e-3) {
                  capacitanceValue = (capacitance / 1e-6).toStringAsFixed(2);
                  capacitanceUnit = "\u00B5F";
                } else if (capacitance < 1e-1) {
                  capacitanceValue = (capacitance / 1e-3).toStringAsFixed(2);
                  capacitanceUnit = "mF";
                } else {
                  capacitanceValue = capacitance.toStringAsFixed(2);
                  capacitanceUnit = "F";
                }
              }
              value = capacitanceValue;
              unit = capacitanceUnit;
              break;
            case 5:
              await getIDData();
              break;
            case 6:
              await getIDData();
              break;
            case 7:
              await getIDData();
              break;
            case 8:
              await getIDData();
              break;
            default:
              double? voltage = await _scienceLab.getVoltage(
                knobMarker[_selectedIndex],
                1,
              );
              String voltageValue = voltage.toStringAsFixed(2);
              String voltageUnit = appLocalizations.unitVolts;
              value = voltageValue;
              unit = voltageUnit;
          }
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
                  : 0,
            ]);
          }
          notifyListeners();
          _isProcessing = false;
        }
      },
    );
  }

  Future<void> getIDData() async {
    try {
      if (!isSwitchChecked) {
        double frequency = await _scienceLab.getFrequency(
          knobMarker[_selectedIndex],
        );
        value = frequency.toStringAsFixed(2);
        unit = appLocalizations.unitHz;
      } else {
        await _scienceLab.countPulses(knobMarker[_selectedIndex]);
        int pulseCount = await _scienceLab.readPulseCount();
        value = pulseCount.toString();
        unit = "";
      }
    } catch (e) {
      value = "Cannot measure!";
      unit = "null";
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
      logger.e(
        'Skipping playback row at index $_playbackIndex due to insufficient columns (found ${currentRow.length}, expected at least 3',
      );
      _playbackIndex++;
      notifyListeners();
    }

    Duration interval = const Duration(seconds: 1);

    if (_playbackIndex < _playbackData!.length && _playbackIndex > 1) {
      try {
        final currentTimestamp = int.tryParse(
          _playbackData![_playbackIndex - 1][0].toString(),
        );
        final nextTimestamp = int.tryParse(
          _playbackData![_playbackIndex][0].toString(),
        );

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
        'Longitude',
      ],
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
    super.dispose();
  }
}
