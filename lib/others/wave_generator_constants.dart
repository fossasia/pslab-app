import 'package:pslab/providers/wave_generator_state_provider.dart';

class WaveGeneratorConstants {
  final Map<WaveConst, Map<WaveConst, int>> wave = {
    WaveConst.wave1: {
      WaveConst.frequency: WaveData.freqMin.value,
      WaveConst.waveType: WaveGeneratorStateProvider.sin,
    },
    WaveConst.wave2: {
      WaveConst.phase: WaveData.phaseMin.value,
      WaveConst.frequency: WaveData.freqMin.value,
      WaveConst.waveType: WaveGeneratorStateProvider.sin,
    },
    WaveConst.waveType: {},
    WaveConst.sqr1: {
      WaveConst.frequency: WaveData.freqMin.value,
      WaveConst.duty: WaveData.dutyMin.value,
    },
    WaveConst.sqr2: {
      WaveConst.phase: WaveData.phaseMin.value,
      WaveConst.duty: WaveData.dutyMin.value,
    },
    WaveConst.sqr3: {
      WaveConst.phase: WaveData.phaseMin.value,
      WaveConst.duty: WaveData.dutyMin.value,
    },
    WaveConst.sqr4: {
      WaveConst.phase: WaveData.phaseMin.value,
      WaveConst.duty: WaveData.dutyMin.value,
    },
  };

  WaveConst modeSelected = WaveConst.square;

  final Map<String, int> state = {
    'SQR1': 0,
    'SQR2': 0,
    'SQR3': 0,
    'SQR4': 0,
  };
}
