import 'package:pslab/src/rust/api/labrador.dart' as rust_labrador;
import 'wave_generator_interface.dart';

class LabradorWaveGenerator implements WaveGeneratorInterface {
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
    if (freq1 > 0) {
      rust_labrador.labradorGenerateAnalogWave(
          channel: 1,
          frequencyHz: freq1,
          waveType: waveType1,
          amplitudeV: amplitude1,
          offsetV:
              0.0
          );
    }

    if (freq2 > 0) {
      rust_labrador.labradorGenerateAnalogWave(
          channel: 2,
          frequencyHz: freq2,
          waveType: waveType2,
          amplitudeV: amplitude2,
          offsetV: 0.0);
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
    if (duty1 > 0) {
      rust_labrador.labradorGenerateAnalogWave(
          channel: 1,
          frequencyHz: freq,
          waveType: "square",
          amplitudeV: 3.3,
          offsetV: 0.0);
    }
  }
}
