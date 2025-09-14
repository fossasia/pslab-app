import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/experiment_step.dart';
import '../models/experiment_config.dart';
import '../providers/locator.dart';

AppLocalizations appLocalizations = getIt.get();

class StabilizePressureReadingStep extends ExperimentStep {
  StabilizePressureReadingStep()
      : super(
          id: 'stabilize_pressure',
          instruction: appLocalizations.holdPositionForPressure,
        );
  @override
  bool checkCondition(List<double> values, List<double> timeData) {
    if (values.length < 5) return false;
    final lastFive = values.sublist(values.length - 5);
    final average = lastFive.reduce((a, b) => a + b) / lastFive.length;
    for (double value in lastFive) {
      if ((value - average).abs() / average > 0.005) {
        return false;
      }
    }
    return true;
  }
}

class MoveToHigherAltitudeStep extends ExperimentStep {
  MoveToHigherAltitudeStep()
      : super(
          id: 'move_higher',
          instruction: appLocalizations.moveToHigherAltitude,
        );
  @override
  bool checkCondition(List<double> values, List<double> timeData) {
    if (values.length < 5) return false;
    final lastFive = values.sublist(values.length - 5);
    int decreasingCount = 0;
    for (int i = 1; i < lastFive.length; i++) {
      if (lastFive[i] < lastFive[i - 1]) {
        decreasingCount++;
      }
    }
    return decreasingCount >= 3;
  }
}

class MoveToLowerAltitudeStep extends ExperimentStep {
  MoveToLowerAltitudeStep()
      : super(
          id: 'move_lower',
          instruction: appLocalizations.moveToLowerAltitude,
        );
  @override
  bool checkCondition(List<double> values, List<double> timeData) {
    if (values.length < 5) return false;
    final lastFive = values.sublist(values.length - 5);
    int increasingCount = 0;
    for (int i = 1; i < lastFive.length; i++) {
      if (lastFive[i] > lastFive[i - 1]) {
        increasingCount++;
      }
    }
    return increasingCount >= 3;
  }
}

final barometerPressureExperiment = ExperimentConfig(
  id: 'barometer_pressure',
  title: appLocalizations.pressureVsAltitude,
  description: appLocalizations.pressureVsAltitudeDesc,
  icon: Icons.compress,
  targetScreen: '/barometer',
  guideSteps: [
    {
      'title': appLocalizations.setUp,
      'content': appLocalizations.barometerExperimentSetUpContent,
      'image': 'assets/images/barometerExperiment1.gif',
    },
    {
      'title': appLocalizations.preparation,
      'content': appLocalizations.barometerExperimentPreparationContent,
      'image': 'assets/images/barometerExperiment2.gif',
    },
    {
      'title': appLocalizations.instructions,
      'content': appLocalizations.barometerExperimentInstructionContent,
      'image': 'assets/images/barometerExperiment3.gif',
    },
  ],
  experimentSteps: [
    StabilizePressureReadingStep(),
    MoveToHigherAltitudeStep(),
    StabilizePressureReadingStep(),
    MoveToLowerAltitudeStep(),
    StabilizePressureReadingStep(),
  ],
);
