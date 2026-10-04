enum MultimeterMode { voltage, current, resistance }

class MultimeterReading {
  final double value;
  final String unit;
  final double min;
  final double max;
  final double rms;

  MultimeterReading({
    required this.value,
    required this.unit,
    this.min = 0.0,
    this.max = 0.0,
    this.rms = 0.0,
  });
}

abstract class MultimeterInterface {
  Future<void> setMode(MultimeterMode mode);
  Future<MultimeterReading> readMeasurement();
}
