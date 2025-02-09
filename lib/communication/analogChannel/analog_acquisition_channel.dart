import 'package:pslab/communication/analogChannel/analog_input_source.dart';

class AnalogAcquisitionChannel {
  late int _resolution;
  late AnalogInputSource _analogInputSource;
  late double calibrationRef196;
  late int length;
  late double _timebase;
  late int bufferIndex;
  final List<double> _xAxis = List.filled(10000, 0.0);
  List<double> yAxis = List.filled(10000, 0.0);

  AnalogAcquisitionChannel(String channel) {
    calibrationRef196 = 1;
    _resolution = 10;
    length = 100;
    _timebase = 1;
    bufferIndex = 0;
    _analogInputSource = AnalogInputSource('CH1');
  }

  List<double> fixValue(List<double> val) {
    List<double> calcData = List.filled(val.length, 0.0);
    if (_resolution == 12) {
      for (int i = 0; i < val.length; i++) {
        calcData[i] =
            calibrationRef196 * (_analogInputSource.calPoly12.evaluate(val[i]));
      }
    } else {
      for (int i = 0; i < val.length; i++) {
        calcData[i] =
            calibrationRef196 * (_analogInputSource.calPoly10.evaluate(val[i]));
      }
    }
    return calcData;
  }

  void setParams(String? channel, int length, int bufferIndex, double timebase,
      int resolution, AnalogInputSource? source, double? gain) {
    _analogInputSource = source!;
    if (resolution != -1) _resolution = resolution;
    if (length != -1) this.length = length;
    if (timebase != -1) _timebase = timebase;
    if (bufferIndex != -1) this.bufferIndex = bufferIndex;
    regenerateXAxis();
  }

  void regenerateXAxis() {
    for (int i = 0; i < length; i++) {
      _xAxis[i] = _timebase * i;
    }
  }

  List<double> getXAxis() {
    return List.from(_xAxis.getRange(0, length));
  }

  List<double> getYAxis() {
    return List.from(yAxis.getRange(0, length));
  }
}
