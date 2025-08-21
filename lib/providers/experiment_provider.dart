import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:pslab/models/experiment_config.dart';
import 'package:pslab/models/experiment_step.dart';

enum ExperimentState {
  idle,
  running,
  stepCompleted,
  finished,
}

class ExperimentProvider extends ChangeNotifier {
  ExperimentConfig? _currentExperiment;
  int _currentStepIndex = 0;
  ExperimentState _state = ExperimentState.idle;
  Timer? _stepTimer;
  DateTime? _stepStartTime;

  ExperimentConfig? get currentExperiment => _currentExperiment;
  int get currentStepIndex => _currentStepIndex;
  ExperimentState get state => _state;

  ExperimentStep? get currentStep => _currentExperiment != null &&
          _currentStepIndex < _currentExperiment!.experimentSteps.length
      ? _currentExperiment!.experimentSteps[_currentStepIndex]
      : null;

  void startExperiment(ExperimentConfig experiment) {
    _currentExperiment = experiment;
    _currentStepIndex = 0;
    _state = ExperimentState.running;
    _stepStartTime = DateTime.now();
    notifyListeners();
  }

  void checkStepCondition(List<double> values, List<double> timeData) {
    if (_state != ExperimentState.running || currentStep == null) return;

    if (_stepStartTime != null &&
        DateTime.now().difference(_stepStartTime!).inSeconds < 3) {
      return;
    }

    if (currentStep!.checkCondition(values, timeData)) {
      _state = ExperimentState.stepCompleted;

      _stepTimer = Timer(const Duration(seconds: 2), () {
        nextStep();
      });

      notifyListeners();
    }
  }

  void nextStep() {
    _stepTimer?.cancel();

    if (_currentStepIndex <
        (_currentExperiment?.experimentSteps.length ?? 0) - 1) {
      _currentStepIndex++;
      _state = ExperimentState.running;
      _stepStartTime = DateTime.now();
    } else {
      _state = ExperimentState.finished;
    }

    notifyListeners();
  }

  void stopExperiment() {
    _stepTimer?.cancel();
    _currentExperiment = null;
    _currentStepIndex = 0;
    _state = ExperimentState.idle;
    _stepStartTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }
}
