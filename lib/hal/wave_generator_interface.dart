abstract class WaveGeneratorInterface {
  Future<void> generateAnalogWaves({
    required double freq1,
    required double freq2,
    required double phase,
    required String waveType1,
    required String waveType2,
    required double amplitude1,
    required double amplitude2,
  });

  Future<void> generateDigitalPwms({
    required double freq,
    required double duty1,
    required double phase2,
    required double duty2,
    required double phase3,
    required double duty3,
    required double phase4,
    required double duty4,
  });
}
