import 'dart:math';
import 'dart:typed_data';
import 'package:pslab/src/rust/api/labrador.dart' as rust_labrador;
import 'multimeter_interface.dart';

class LabradorMultimeter implements MultimeterInterface {
  MultimeterMode currentMode = MultimeterMode.voltage;
  final double vcc = 3.3;
  final double seriesResistance = 1000.0;
  final double frontendGain = 0.1;

  @override
  Future<void> setMode(MultimeterMode mode) async {
    currentMode = mode;
    rust_labrador.labradorStartMultimeter();
  }

  @override
  Future<MultimeterReading> readMeasurement() async {
    final rawBytes = rust_labrador.labradorFetchRawBytes(channel: 1, numBytes: 1024);

    if (rawBytes.length < 1024) {
      return MultimeterReading(value: 0.0, unit: "V");
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(rawBytes));
    final numSamples = rawBytes.length ~/ 2;

    double sum = 0.0;
    double sumSq = 0.0;
    double vMin = 999.0;
    double vMax = -999.0;

    for (int i = 0; i < numSamples; i++) {
      int rawSample16 = byteData.getInt16(i * 2, Endian.little);
      int sample12 = rawSample16 >> 4;
      double v = (sample12 * (vcc / 2.0)) / (frontendGain * 2048.0);

      sum += v;
      sumSq += v * v;
      if (v < vMin) vMin = v;
      if (v > vMax) vMax = v;
    }

    final double vMean = sum / numSamples;
    final double vRms = sqrt(sumSq / numSamples);

    switch (currentMode) {
      case MultimeterMode.voltage:
        return MultimeterReading(
          value: vMean,
          unit: "V",
          min: vMin,
          max: vMax,
          rms: vRms,
        );

      case MultimeterMode.current:
        final double currentAmps = vMean / seriesResistance;
        return MultimeterReading(
          value: currentAmps * 1000.0,
          unit: "mA",
          min: (vMin / seriesResistance) * 1000.0,
          max: (vMax / seriesResistance) * 1000.0,
          rms: (vRms / seriesResistance) * 1000.0,
        );

      case MultimeterMode.resistance:
        if ((vcc - vMean).abs() < 0.01) {
          return MultimeterReading(value: double.infinity, unit: "Ω");
        }
        final double r = (vMean * seriesResistance) / (vcc - vMean);
        if (r > 1000) {
          return MultimeterReading(value: r / 1000.0, unit: "kΩ");
        }
        return MultimeterReading(value: r, unit: "Ω");
    }
  }
}