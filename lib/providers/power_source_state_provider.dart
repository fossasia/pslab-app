import 'package:flutter/material.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/providers/locator.dart';

enum Pin {
  pv1,
  pv2,
  pv3,
  pcs,
}

class PowerSourceStateProvider extends ChangeNotifier {
  late double voltagePV1;
  late double voltagePV2;
  late double voltagePV3;
  late double currentPCS;

  late List<double> rangePV1;
  late List<double> rangePV2;
  late List<double> rangePV3;
  late List<double> rangePCS;

  late double step;

  late ScienceLab _scienceLab;

  PowerSourceStateProvider() {
    voltagePV1 = -5.00;
    voltagePV2 = -3.30;
    voltagePV3 = 0.00;
    currentPCS = 0.00;

    rangePV1 = [-5.00, 5.00];
    rangePV2 = [-3.30, 3.30];
    rangePV3 = [0.00, 3.30];
    rangePCS = [0.00, 3.30];

    step = 0.01;

    _scienceLab = getIt.get<ScienceLab>();
  }

  double valueToIndex(double value, Pin pin) {
    List<double> range;
    int sections;
    switch (pin) {
      case Pin.pv1:
        range = rangePV1;
        sections = 1000;
        break;
      case Pin.pv2:
        range = rangePV2;
        sections = 660;
        break;
      case Pin.pv3:
        range = rangePV3;
        sections = 330;
        break;
      case Pin.pcs:
        range = rangePCS;
        sections = 330;
        break;
    }
    final clampedValue = value.clamp(range[0], range[1]);
    return ((clampedValue - range[0]) / (range[1] - range[0])) * sections;
  }

  double indexToValue(double index, Pin pin) {
    List<double> range;
    int sections;
    switch (pin) {
      case Pin.pv1:
        range = rangePV1;
        sections = 1000;
        break;
      case Pin.pv2:
        range = rangePV2;
        sections = 660;
        break;
      case Pin.pv3:
        range = rangePV3;
        sections = 330;
        break;
      case Pin.pcs:
        range = rangePCS;
        sections = 330;
        break;
    }
    final clampedIndex = index.clamp(0, sections);
    return (clampedIndex / sections) * (range[1] - range[0]) + range[0];
  }

  Future<void> setPV1(double value) async {
    final clampedValue = value.clamp(rangePV1[0], rangePV1[1]);
    voltagePV1 = clampedValue;
    voltagePV3 = (3.3 / 2) * (1 + (voltagePV1 / 5.0));
    await _scienceLab.setPV1(voltagePV1);
    notifyListeners();
  }

  Future<void> setPV2(double value) async {
    final clampedValue = value.clamp(rangePV2[0], rangePV2[1]);
    voltagePV2 = clampedValue;
    currentPCS = (3.3 - voltagePV2) / 2;
    await _scienceLab.setPV2(voltagePV2);
    notifyListeners();
  }

  Future<void> setPV3(double value) async {
    final clampedValue = value.clamp(rangePV3[0], rangePV3[1]);
    voltagePV3 = clampedValue;
    voltagePV1 = 5 * (2 * voltagePV3 / 3.3 - 1);
    await _scienceLab.setPV3(voltagePV3);
    notifyListeners();
  }

  Future<void> setPCS(double value) async {
    final clampedValue = value.clamp(rangePCS[0], rangePCS[1]);
    currentPCS = clampedValue;
    voltagePV2 = 3.3 - 2 * currentPCS;
    await _scienceLab.setPCS(currentPCS);
    notifyListeners();
  }

  Future<void> setValue(double value, Pin pin) async {
    switch (pin) {
      case Pin.pv1:
        await setPV1(value);
        break;
      case Pin.pv2:
        await setPV2(value);
        break;
      case Pin.pv3:
        await setPV3(value);
        break;
      case Pin.pcs:
        await setPCS(value);
        break;
    }
  }

  double getValue(Pin pin) {
    switch (pin) {
      case Pin.pv1:
        return voltagePV1;
      case Pin.pv2:
        return voltagePV2;
      case Pin.pv3:
        return voltagePV3;
      case Pin.pcs:
        return currentPCS;
    }
  }
}
