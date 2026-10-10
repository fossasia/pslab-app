import 'package:pslab/hal/wave_generator_interface.dart';

import 'oscilloscope_interface.dart';
import 'multimeter_interface.dart';

abstract class HardwareBoard {
  String get boardName;
  bool get isConnected;

  OscilloscopeInterface? get oscilloscope;
  MultimeterInterface? get multimeter;
  WaveGeneratorInterface? get waveGenerator;
  Future<void> disconnect();
}
