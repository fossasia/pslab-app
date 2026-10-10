import 'dart:math';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';
import 'oscilloscope_interface.dart';

class PSLabOscilloscope implements OscilloscopeInterface {
  final ScienceLab scienceLab;
  bool _ch2Enabled = false;
  bool _isAc = false;

  PSLabOscilloscope(this.scienceLab);

  @override
  Future<void> configureChannel(int channel, bool enabled) async {
    logger.d("OSC_HAL: Configuring CH$channel to Enabled = $enabled");
    if (channel == 2) _ch2Enabled = enabled;
  }

  @override
  Future<void> setGain(int channel, double gain) async {
    int gainCode = 0;
    if (gain >= 8) {
      gainCode = 3;
    } else if (gain >= 4) {
      gainCode = 2;
    } else if (gain >= 2) {
      gainCode = 1;
    }

    String chName = channel == 1 ? 'CH1' : 'CH2';
    logger.d("OSC_HAL: Setting Gain for $chName to ${gain}x (Code: $gainCode)");
    await scienceLab.setGain(chName, gainCode, true);
  }

  @override
  void setAcCoupled(bool isAc) {
    logger.d("OSC_HAL: Setting AC Coupling to $isAc");
    _isAc = isAc;
  }

  @override
  Future<List<double>> fetchSamples(int numToGet, int channel) async {
    String chName = channel == 1 ? 'CH1' : 'CH2';

    await scienceLab.captureTraces(
      _ch2Enabled ? 2 : 1,
      numToGet,
      2.0,
      chName,
      false,
      null,
    );

    final trace = await scienceLab.fetchTrace(channel);
    List<double> samples = trace['y'] ?? [];

    if (samples.isEmpty) {
      logger.w("OSC_HAL: FETCH FAILED! trace['y'] for $chName returned an empty list.");
      return samples;
    }

    double minVal = samples.reduce(min);
    double maxVal = samples.reduce(max);
    double meanVal = samples.reduce((a, b) => a + b) / samples.length;
    double vPP = maxVal - minVal;

    logger.i("OSC_HAL: $chName Stats -> "
        "Count: ${samples.length} | "
        "Min: ${minVal.toStringAsFixed(3)}V | "
        "Max: ${maxVal.toStringAsFixed(3)}V | "
        "Mean: ${meanVal.toStringAsFixed(3)}V | "
        "Vpp: ${vPP.toStringAsFixed(3)}V");

    if (vPP < 0.05) {
      logger.w("OSC_HAL: LOW AMPLITUDE WARNING on $chName! Vpp is only ${vPP.toStringAsFixed(3)}V. The wave will appear almost flat/invisible.");
    }
    if (_isAc) {
      samples = samples.map((v) => v - meanVal).toList();
      logger.d("OSC_HAL: Applied AC Coupling (shifted by -${meanVal.toStringAsFixed(3)}V)");
    }

    return samples;
  }
}