import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/others/science_lab_common.dart';
import 'package:vibration/vibration.dart';

import '../others/csv_service.dart';

class RoboticArmStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final CsvService _csvService = CsvService();

  final List<double> servoValues = [0, 0, 0, 0];
  List<List<double?>> timelineDegrees = [];
  List<List<double?>> pwmData = [];
  int timelinePosition = 0;
  bool isPlaying = false;
  bool _showControlBox = false;
  bool feedbackEnabled = false;
  bool manualEnabled = false;

  late ScienceLab scienceLab;
  Timer? _debounceTimer;
  Timer? _timelineTimer;
  final ScrollController timelineScrollController = ScrollController();

  late String _selectedFrequency;
  late String _selectedMaxAngle;
  late String _selectedDuration;

  int get maxAngle => int.tryParse(_selectedMaxAngle) ?? 180;
  String get selectedFrequency => _selectedFrequency;
  String get selectedMaxAngle => _selectedMaxAngle;
  String get selectedDuration => _selectedDuration;
  bool get showControlBox => _showControlBox;

  int get totalTimelineItems =>
      _selectedDuration == appLocalizations.duration2Min ? 120 : 60;

  VoidCallback? onPlaybackEnd;

  RoboticArmStateProvider() {
    _selectedFrequency = appLocalizations.frequency50Hz;
    _selectedMaxAngle = appLocalizations.angle180;
    _selectedDuration = appLocalizations.duration1Min;
    _initTimelineDegrees();
  }

  void _initTimelineDegrees() {
    timelineDegrees =
        List.generate(totalTimelineItems, (_) => List.filled(4, null));
  }

  void setSelectedDuration(String value) {
    if (_selectedDuration != value) {
      _selectedDuration = value;
      timelinePosition = 0;
      _initTimelineDegrees();
      notifyListeners();
    }
  }

  void setSelectedFrequency(String value) {
    _selectedFrequency = value;
    notifyListeners();
  }

  void setSelectedMaxAngle(String value) {
    _selectedMaxAngle = value;
    notifyListeners();
  }

  void setManualEnabled(bool value) {
    manualEnabled = value;
    notifyListeners();
  }

  void setFeedbackEnabled(bool value) {
    feedbackEnabled = value;
    notifyListeners();
  }

  void clearTimelineDegrees() {
    for (int i = 0; i < timelineDegrees.length; i++) {
      for (int j = 0; j < timelineDegrees[i].length; j++) {
        timelineDegrees[i][j] = null;
      }
    }
    notifyListeners();
  }

  Future<void> initialize() async {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    scienceLab =
        ScienceLabCommon(ScienceLabCommon.communicationHandler).getScienceLab();
    await scienceLab.connect();
  }

  void disposeResources() {
    _timelineTimer?.cancel();
    _debounceTimer?.cancel();
    timelineScrollController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void updateServoValue(int index, double value) {
    servoValues[index] = value;
    notifyListeners();
    _sendAllServoCommands();
  }

  void updateTimelineDegree(int timeIndex, int servoIndex, double value) {
    timelineDegrees[timeIndex][servoIndex] = value;
    notifyListeners();
  }

  void _sendAllServoCommands() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      if (!manualEnabled) return;
      if (scienceLab.isConnected()) {
        try {
          await scienceLab.servo4(
            servoValues[0],
            servoValues[1],
            servoValues[2],
            servoValues[3],
            maxAngle: maxAngle,
            frequency:
                selectedFrequency == appLocalizations.frequency50Hz ? 50 : 100,
          );
        } catch (e) {
          logger.e(e);
        }
      }
    });
  }

  void togglePlayPause({required double scrollAmountPerTick}) {
    if (isPlaying) {
      _timelineTimer?.cancel();
      isPlaying = false;
      notifyListeners();
    } else {
      timelineScrollController.jumpTo(timelinePosition * scrollAmountPerTick);

      _timelineTimer =
          Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (manualEnabled) return;

        if (timelinePosition >= totalTimelineItems) {
          stopScrolling(resetPosition: false);
          return;
        }

        final offsetBefore = timelineScrollController.offset;
        timelineScrollController.animateTo(
          offsetBefore + scrollAmountPerTick,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );

        final angles = timelineDegrees[timelinePosition];
        if (scienceLab.isConnected()) {
          try {
            await scienceLab.servo4(
              angles[0],
              angles[1],
              angles[2],
              angles[3],
              maxAngle: maxAngle,
              frequency: selectedFrequency == appLocalizations.frequency50Hz
                  ? 50
                  : 100,
            );
          } catch (e) {
            logger.e('Servo command failed: $e');
          }
        }

        if (feedbackEnabled && (await Vibration.hasVibrator())) {
          Vibration.vibrate(duration: 50);
        }

        timelinePosition++;
        notifyListeners();
      });

      isPlaying = true;
      notifyListeners();
    }
  }

  void toggleControlBox() {
    _showControlBox = !_showControlBox;
    notifyListeners();
  }

  void hideControlBox() {
    _showControlBox = false;
    notifyListeners();
  }

  Future<void> exportTimelineToCsv({
    required String instrumentName,
    required String fileName,
  }) async {
    List<List<dynamic>> csvData = [];

    csvData
        .add(['Timestamp', 'Servo1', 'Servo2', 'Servo3', 'Servo4', 'DateTime']);

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

    for (int i = 0; i < timelineDegrees.length; i++) {
      final row = timelineDegrees[i];
      final timestamp = i;
      final dateTime = dateFormat.format(DateTime.now());

      csvData.add([
        timestamp,
        row[0]?.toString() ?? 'null',
        row[1]?.toString() ?? 'null',
        row[2]?.toString() ?? 'null',
        row[3]?.toString() ?? 'null',
        dateTime
      ]);
    }

    await _csvService.saveCsvFile(instrumentName, fileName, csvData);
  }

  Future<void> importTimelineFromCsv(List<List<dynamic>> csv) async {
    if (csv.length <= 2) return;

    final dataRows = csv.skip(1).toList();

    for (int i = 0; i < totalTimelineItems; i++) {
      if (i < dataRows.length && dataRows[i].length >= 5) {
        final row = dataRows[i];
        timelineDegrees[i] = [
          double.tryParse(row[1].toString()),
          double.tryParse(row[2].toString()),
          double.tryParse(row[3].toString()),
          double.tryParse(row[4].toString()),
        ];
      } else {
        timelineDegrees[i] = [null, null, null, null];
      }
    }

    notifyListeners();
  }

  void stopScrolling({bool resetPosition = true}) {
    _timelineTimer?.cancel();
    isPlaying = false;
    notifyListeners();
    pwmData = timelineDegrees.take(timelinePosition).toList();
    if (resetPosition) {
      timelineScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 50),
        curve: Curves.easeOut,
      );
    }
    if (timelinePosition > 0) {
      onPlaybackEnd?.call();
    }
    timelinePosition = 0;
  }

  Map<String, dynamic> generateSummary(
    int servoIndex,
    int maxAngle,
  ) {
    const int base = 750;
    int frequency =
        selectedFrequency == appLocalizations.frequency50Hz ? 50 : 100;
    int range = maxAngle == 360 ? 3800 : 1900;
    int period = 1000000 ~/ frequency;
    double periodMs = period / 1000;

    List<FlSpot> spots = [];
    List<double> dutyCycles = [];
    List<double> angleList = [];
    List<Map<String, dynamic>> dutyLabelPoints = [];

    double time = 0;

    for (final entry in pwmData) {
      final angle = entry[servoIndex];

      if (angle == null) {
        time += periodMs;
        continue;
      }

      angleList.add(angle);

      final pulseHigh = base + ((angle * range) ~/ maxAngle);
      final highMs = pulseHigh / 1000;

      final duty = (pulseHigh / period) * 100;
      dutyCycles.add(duty);

      final mid = time + highMs / 2;
      dutyLabelPoints.add({
        'x': mid,
        'label': '${duty.toStringAsFixed(1)}${appLocalizations.percentage}',
      });

      spots.add(FlSpot(time, 0));
      spots.add(FlSpot(time, 1));
      spots.add(FlSpot(time + highMs, 1));
      spots.add(FlSpot(time + highMs, 0));
      spots.add(FlSpot(time + periodMs, 0));

      time += periodMs;
    }

    double avgDuty = 0, minDuty = 0, maxDuty = 0;
    double avgAngle = 0, minAngle = 0, maxAngleVal = 0;

    if (dutyCycles.isNotEmpty) {
      avgDuty = dutyCycles.reduce((a, b) => a + b) / dutyCycles.length;
      minDuty = dutyCycles.reduce((a, b) => a < b ? a : b);
      maxDuty = dutyCycles.reduce((a, b) => a > b ? a : b);
    }

    if (angleList.isNotEmpty) {
      avgAngle = angleList.reduce((a, b) => a + b) / angleList.length;
      minAngle = angleList.reduce((a, b) => a < b ? a : b);
      maxAngleVal = angleList.reduce((a, b) => a > b ? a : b);
    }

    return {
      'spots': spots,
      'avgDuty': avgDuty,
      'minDuty': minDuty,
      'maxDuty': maxDuty,
      'dutyList': dutyCycles,
      'avgAngle': avgAngle,
      'minAngle': minAngle,
      'maxAngle': maxAngleVal,
      'dutyLabelPoints': dutyLabelPoints,
    };
  }
}
