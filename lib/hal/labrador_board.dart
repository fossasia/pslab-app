import 'package:pslab/src/rust/api/labrador.dart' as rust_labrador;
import 'package:pslab/src/rust/api/simple.dart' as rust_simple;
import 'hardware_board.dart';
import 'oscilloscope_interface.dart';
import 'multimeter_interface.dart';
import 'wave_generator_interface.dart';
import 'labrador_oscilloscope.dart';
import 'labrador_multimeter.dart';
import 'labrador_wave_generator.dart';

class LabradorHardwareBoard implements HardwareBoard {
  final String version;
  final int vid;
  final int pid;

  final LabradorOscilloscope _oscilloscope = LabradorOscilloscope();
  final LabradorMultimeter _multimeter = LabradorMultimeter();
  final LabradorWaveGenerator _waveGenerator = LabradorWaveGenerator();
  bool _connected = true;

  LabradorHardwareBoard({
    required this.version,
    required this.vid,
    required this.pid,
  });

  @override
  String get boardName => version;

  @override
  bool get isConnected => _connected;

  @override
  OscilloscopeInterface? get oscilloscope => _oscilloscope;

  @override
  MultimeterInterface? get multimeter => _multimeter;

  @override
  WaveGeneratorInterface? get waveGenerator => _waveGenerator;

  @override
  Future<void> disconnect() async {
    rust_labrador.labradorStopStreaming();
    rust_simple.closeUsb();
    _connected = false;
  }
}
