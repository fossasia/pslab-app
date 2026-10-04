import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/providers/locator.dart';
import 'hardware_board.dart';
import 'oscilloscope_interface.dart';
import 'multimeter_interface.dart';
import 'wave_generator_interface.dart';
import 'pslab_oscilloscope.dart';
import 'pslab_multimeter.dart';
import 'pslab_wave_generator.dart';

class PSLabHardwareBoard implements HardwareBoard {
  final String version;
  final int vid;
  final int pid;

  late final PSLabOscilloscope _oscilloscope;
  late final PSLabMultimeter _multimeter;
  late final PSLabWaveGenerator _waveGenerator;

  PSLabHardwareBoard({
    required this.version,
    required this.vid,
    required this.pid,
  }) {
    final scienceLab = getIt.get<ScienceLab>();
    _oscilloscope = PSLabOscilloscope(scienceLab);
    _multimeter = PSLabMultimeter(scienceLab);
    _waveGenerator = PSLabWaveGenerator(scienceLab);
  }

  @override
  String get boardName => version;

  @override
  bool get isConnected => getIt.get<ScienceLab>().isConnected();

  @override
  OscilloscopeInterface? get oscilloscope => _oscilloscope;

  @override
  MultimeterInterface? get multimeter => _multimeter;

  @override
  WaveGeneratorInterface? get waveGenerator => _waveGenerator;

  @override
  Future<void> disconnect() async {}
}
