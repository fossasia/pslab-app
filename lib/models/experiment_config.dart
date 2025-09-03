import 'package:flutter/cupertino.dart';

import 'experiment_step.dart';

class ExperimentConfig {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<Map<String, String>> guideSteps;
  final List<ExperimentStep> experimentSteps;
  final String targetScreen;

  ExperimentConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.guideSteps,
    required this.experimentSteps,
    required this.targetScreen,
  });
}
