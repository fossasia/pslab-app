import 'package:pslab/communication/science_lab.dart';
import 'multimeter_interface.dart';

class PSLabMultimeter implements MultimeterInterface {
  final ScienceLab scienceLab;
  MultimeterMode _mode = MultimeterMode.voltage;

  PSLabMultimeter(this.scienceLab);

  @override
  Future<void> setMode(MultimeterMode mode) async {
    _mode = mode;
  }

  @override
  Future<MultimeterReading> readMeasurement() async {
    switch (_mode) {
      case MultimeterMode.voltage:
        final v = await scienceLab.getVoltage('CH1', 10);
        return MultimeterReading(value: v, unit: 'V', min: v, max: v, rms: v);

      case MultimeterMode.current:
        final v = await scienceLab.getVoltage('CH1', 10);
        final i = (v / 1000.0) * 1000.0;
        return MultimeterReading(value: i, unit: 'mA', min: i, max: i, rms: i);

      case MultimeterMode.resistance:
        final r = await scienceLab.getResistance();
        if (r == null) {
          return MultimeterReading(value: double.infinity, unit: 'Ω');
        }
        if (r > 1000) {
          return MultimeterReading(value: r / 1000.0, unit: 'kΩ');
        }
        return MultimeterReading(value: r, unit: 'Ω');
    }
  }
}
