import 'package:pslab/src/rust/api/labrador.dart' as rust_labrador;
import 'oscilloscope_interface.dart';

class LabradorOscilloscope implements OscilloscopeInterface {
  final double vcc = 3.3;
  final double ch1Ref = 1.65;
  final double ch2Ref = 1.65;
  final double frontendGainCh1 = 0.1;
  final double frontendGainCh2 = 0.1;

  double currentScopeGain = 1.0;
  bool isAcCoupled = false;
  bool ch2Enabled = false;
  bool isTriggerEnabled = false;
  static int _activeChannels = -1;
  static double _activeGain = -1.0;

  static List<double> _lastValidFrameCh1 = [];
  static List<double> _lastValidFrameCh2 = [];

  @override
  Future<void> configureChannel(int channel, bool enabled) async {
    if (channel == 2) ch2Enabled = enabled;

    int targetChannels = ch2Enabled ? 2 : 1;

    if (targetChannels != _activeChannels || currentScopeGain != _activeGain) {
      _activeChannels = targetChannels;
      _activeGain = currentScopeGain;

      rust_labrador.labradorStartOscilloscope(
        channels: _activeChannels,
        gain: _activeGain,
      );
    }
  }

  @override
  Future<void> setGain(int channel, double gain) async {
    currentScopeGain = gain;

    int targetChannels = ch2Enabled ? 2 : 1;
    if (targetChannels != _activeChannels || currentScopeGain != _activeGain) {
      _activeChannels = targetChannels;
      _activeGain = currentScopeGain;

      rust_labrador.labradorStartOscilloscope(
        channels: _activeChannels,
        gain: _activeGain,
      );
    }
  }

  @override
  void setAcCoupled(bool isAc) {
    isAcCoupled = isAc;
  }

  @override
  Future<List<double>> fetchSamples(int numToGet, int channel) async {
    final rawBytes = rust_labrador.labradorFetchInterpolated(
      channel: channel,
      sampleWindowSecs: 0.005,
      numSamples: numToGet * 2,
      delayOffsetSecs: 0.0,
    );

    final double ref = channel == 1 ? ch1Ref : ch2Ref;

    if (rawBytes.isEmpty || rawBytes.length < numToGet) {
      List<double> cache = channel == 1 ? _lastValidFrameCh1 : _lastValidFrameCh2;
      if (cache.length == numToGet) return cache;
      return List<double>.filled(numToGet, ref);
    }

    const double top = 128.0;
    final double frontendGain = channel == 1 ? frontendGainCh1 : frontendGainCh2;

    final voltages = List<double>.filled(rawBytes.length, 0.0);
    double accumulated = 0.0;

    for (int i = 0; i < rawBytes.length; i++) {
      double signedSample = rawBytes[i];
      double rawV = (signedSample * (vcc / 2.0)) / (frontendGain * currentScopeGain * top);
      rawV += ref;

      double calibratedV = (rawV - 0.23) * (3.3 / (2.56 - 0.23));
      voltages[i] = calibratedV;
      accumulated += calibratedV;
    }

    double meanVal = accumulated / voltages.length;
    if (isAcCoupled) {
      for (int i = 0; i < voltages.length; i++) {
        voltages[i] -= meanVal;
      }
    }

    double triggerLevel = 1.65;
    int startIndex = voltages.length - numToGet;
    for (int i = voltages.length - numToGet - 1; i >= 1; i--) {
      if (voltages[i - 1] < triggerLevel && voltages[i] >= triggerLevel) {
        startIndex = i;
        break;
      }
    }
    if (startIndex + numToGet > voltages.length) {
      startIndex = voltages.length - numToGet;
    }

    List<double> finalFrame = voltages.sublist(startIndex, startIndex + numToGet);

    if (channel == 1) {
      _lastValidFrameCh1 = finalFrame;
    } else {
      _lastValidFrameCh2 = finalFrame;
    }

    return finalFrame;
  }
}