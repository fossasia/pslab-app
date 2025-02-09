import 'dart:core';

import 'package:data/data.dart';
import 'package:pslab/communication/analogChannel/analog_constants.dart';
import 'package:pslab/others/logger_service.dart';

class AnalogInputSource {
  late List<double> _gainValues, _range;
  bool gainEnabled = false, inverted = false, calibrationReady = false;
  double _gain = 0;
  late int gainPGA, chosa;
  final String _channelName;
  late Polynomial calPoly10;
  late Polynomial calPoly12;
  late Polynomial voltToCode10;
  late Polynomial voltToCode12;
  late List<double> adcShifts;
  late List<Polynomial> _polynomials;

  AnalogInputSource(this._channelName) {
    AnalogConstants analogConstants = AnalogConstants();
    adcShifts = [];
    _polynomials = [];
    _range = analogConstants.inputRanges[_channelName]!;
    _gainValues = analogConstants.gains;
    chosa = analogConstants.picADCMultiplex[_channelName]!;

    calPoly10 = Polynomial.fromCoefficients(DataType.float, [0, 3.3 / 1023, 0]);
    calPoly12 = Polynomial.fromCoefficients(DataType.float, [0, 3.3 / 4095, 0]);

    if (_range[1] - _range[0] < 0) {
      inverted = true;
    }
    if (_channelName == "CH1") {
      gainEnabled = true;
      gainPGA = 1;
      _gain = 0;
    } else if (_channelName == "CH2") {
      gainEnabled = true;
      gainPGA = 2;
      _gain = 0;
    }
    _gain = 0;
    regenerateCalibration();
  }

  bool setGain(int index) {
    if (!gainEnabled) {
      logger.e("$_channelName: Analog gain is not available");
      return false;
    }
    _gain = _gainValues[index];
    regenerateCalibration();
    return true;
  }

  void ignoreCalibration() {
    calibrationReady = false;
  }

  void regenerateCalibration() {
    double A, B, intercept, slope;
    B = _range[1];
    A = _range[0];
    if (_gain >= 0 && _gain <= 8) {
      _gain = _gainValues[_gain.round()];
      B /= _gain;
      A /= _gain;
    }
    slope = 2 * (B - A);
    intercept = 2 * A;
    if (!calibrationReady || _gain == 8) {
      calPoly10 = Polynomial.fromCoefficients(
          DataType.float, [0, slope / 1023, intercept]);
      calPoly12 = Polynomial.fromCoefficients(
          DataType.float, [0, slope / 4095, intercept]);
    }

    voltToCode10 = Polynomial.fromCoefficients(
        DataType.float, [0, 1023 / slope, -1023 * intercept / slope]);
    voltToCode12 = Polynomial.fromCoefficients(
        DataType.float, [0, 4095.0, -4095 * intercept / slope]);
  }

  List<double> cal12(List<double> raw) {
    List<double> calcData = List.filled(raw.length, 0.0);
    for (int i = 0; i < raw.length; i++) {
      double avgShifts =
          (adcShifts[raw[i].floor()] + adcShifts[raw[i].ceil()]) / 2;
      raw[i] -= 4095 * avgShifts / 3.3;
      calcData[i] = _polynomials[_gain as int].evaluate(raw[i]);
    }
    return calcData;
  }
}
