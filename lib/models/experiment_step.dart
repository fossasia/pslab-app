abstract class ExperimentStep {
  final String id;
  final String instruction;
  final Duration? timeout;

  ExperimentStep({
    required this.id,
    required this.instruction,
    this.timeout,
  });

  bool checkCondition(List<double> values, List<double> timeData);
}
