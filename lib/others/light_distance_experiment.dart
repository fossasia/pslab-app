import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/experiment_step.dart';
import '../models/experiment_config.dart';
import '../providers/locator.dart';

AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

class MoveTowardsLightStep extends ExperimentStep {
  MoveTowardsLightStep()
    : super(id: 'move_towards', instruction: appLocalizations.moveTowardsLight);

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

class MoveAwayFromLightStep extends ExperimentStep {
  MoveAwayFromLightStep()
    : super(id: 'move_away', instruction: appLocalizations.moveAwayFromLight);

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

class StabilizeReadingStep extends ExperimentStep {
  StabilizeReadingStep()
    : super(id: 'stabilize', instruction: appLocalizations.holdPosition);

  @override
  bool checkCondition(List<double> values, List<double> timeData) {
    if (values.length < 5) return false;

    final lastFive = values.sublist(values.length - 5);
    final average = lastFive.reduce((a, b) => a + b) / lastFive.length;

    for (double value in lastFive) {
      if ((value - average).abs() / average > 0.1) {
        return false;
      }
    }

    return true;
  }
}

final lightDistanceExperiment = ExperimentConfig(
  id: 'light_distance',
  title: appLocalizations.lightIntensityVsDistance,
  description: appLocalizations.lightIntensityVsDistanceDesc,
  icon: Icons.lightbulb,
  targetScreen: '/luxmeter',
  guideSteps: [
    {
      'title': appLocalizations.setUp,
      'content': appLocalizations.lightExperimentSetUpContent,
      'image': 'assets/images/lightDistance1.gif',
    },
    {
      'title': appLocalizations.preparation,
      'content': appLocalizations.lightExperimentPreparationContent,
      'image': 'assets/images/lightDistance2.gif',
    },
    {
      'title': appLocalizations.instructions,
      'content': appLocalizations.lightExperimentInstructionContent,
      'image': 'assets/images/lightDistance3.gif',
    },
  ],
  experimentSteps: [
    StabilizeReadingStep(),
    MoveTowardsLightStep(),
    StabilizeReadingStep(),
    MoveAwayFromLightStep(),
    StabilizeReadingStep(),
  ],
);
