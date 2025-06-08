import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';
import '../others/science_lab_common.dart';

class RoboticArmStateProvider extends ChangeNotifier {
  final List<double> servoValues = [0, 0, 0, 0];
  final int totalTimelineItems = 60;
  final double scrollAmountPerTick = 120;
  final List<List<double>> timelineDegrees =
      List.generate(60, (_) => List.filled(4, 0));
  int timelinePosition = 0;
  bool isPlaying = false;

  late ScienceLab scienceLab;
  Timer? _debounceTimer;
  Timer? _timelineTimer;
  final ScrollController timelineScrollController = ScrollController();

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
      try {
        await scienceLab.servo4(
          servoValues[0],
          servoValues[1],
          servoValues[2],
          servoValues[3],
        );
      } catch (e) {
        logger.e(e);
      }
    });
  }

  void togglePlayPause() {
    if (isPlaying) {
      _timelineTimer?.cancel();
      isPlaying = false;
      notifyListeners();
    } else {
      _timelineTimer =
          Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (timelinePosition >= totalTimelineItems) {
          stopScrolling(resetPosition: false);
          return;
        }

        timelineScrollController.animateTo(
          timelineScrollController.offset + scrollAmountPerTick,
          duration: const Duration(milliseconds: 50),
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
            );
          } catch (e) {
            logger.e(e);
          }
        }

        timelinePosition++;
        notifyListeners();
      });

      isPlaying = true;
      notifyListeners();
    }
  }

  void stopScrolling({bool resetPosition = true}) {
    _timelineTimer?.cancel();
    isPlaying = false;
    timelinePosition = 0;
    notifyListeners();

    if (resetPosition) {
      timelineScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 50),
        curve: Curves.easeOut,
      );
    }
  }
}
