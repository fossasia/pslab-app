import 'package:pslab/communication/science_lab.dart';
import 'wave_generator_interface.dart';

class PSLabWaveGenerator implements WaveGeneratorInterface {
  final ScienceLab scienceLab;

  PSLabWaveGenerator(this.scienceLab);

  @override
  Future<void> generateAnalogWaves({
    required double freq1,
    required double freq2,
    required double phase,
    required String waveType1,
    required String waveType2,
    required double amplitude1,
    required double amplitude2,
  }) async {
    if (phase == 0.0) {
      await scienceLab.setSI1(freq1, waveType1, amplitudeVolt: amplitude1);
      await scienceLab.setSI2(freq2, waveType2, amplitudeVolt: amplitude2);
    } else {
      await scienceLab.setWaves(
        freq1,
        phase,
        freq2,
        waveType1,
        waveType2,
        amplitudeVolt1: amplitude1,
        amplitudeVolt2: amplitude2,
      );
    }
  }

  @override
  Future<void> generateDigitalPwms({
    required double freq,
    required double duty1,
    required double phase2,
    required double duty2,
    required double phase3,
    required double duty3,
    required double phase4,
    required double duty4,
  }) async {
    await scienceLab.sqrPWM(
      freq,
      duty1,
      phase2,
      duty2,
      phase3,
      duty3,
      phase4,
      duty4,
      false,
    );
  }
}
