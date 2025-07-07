import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/locator.dart';

class MultimeterStateProvider extends ChangeNotifier {
  late int _selectedIndex = 0;
  late ScienceLab _scienceLab;
  late bool isSwitchChecked;
  late int delay;
  late String value;
  late String unit;

  late bool _isProcessing;
  late Timer _timer;

  MultimeterStateProvider() {
    _selectedIndex = 0;
    _scienceLab = getIt<ScienceLab>();
    isSwitchChecked = false;
    delay = 1000;
    value = defaultValue;
    unit = unitVolts;

    _isProcessing = false;

    logData();
  }

  int getSelectedIndex() => _selectedIndex;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void toggleSwitch(bool value) {
    isSwitchChecked = value;
    notifyListeners();
  }

  Future<void> logData() async {
    _timer = Timer.periodic(Duration(milliseconds: delay), (timer) async {
      if (_isProcessing) {
        return;
      }
      _isProcessing = true;

      if (_scienceLab.isConnected()) {
        switch (_selectedIndex) {
          case 3:
            double? resistance;
            double? avgResistance = 0.0;
            int loops = 20;
            for (int i = 0; i < loops; i++) {
              resistance = await _scienceLab.getResistance();
              if (resistance == null) {
                avgResistance = null;
                break;
              } else {
                avgResistance = avgResistance! + resistance / loops;
              }
            }
            String resistanceValue;
            String resistanceUnit;
            if (avgResistance == null) {
              resistanceValue = "Infinity";
              resistanceUnit = "\u2126";
            } else {
              if (avgResistance > 10e5) {
                resistanceValue = (avgResistance / 10e5).toStringAsFixed(2);
                resistanceUnit = "M\u2126";
              } else if (avgResistance > 10e2) {
                resistanceValue = (avgResistance / 10e2).toStringAsFixed(2);
                resistanceUnit = "k\u2126";
              } else if (avgResistance > 1) {
                resistanceValue = avgResistance.toStringAsFixed(2);
                resistanceUnit = "\u2126";
              } else {
                resistanceValue = "Cannot measure!";
                resistanceUnit = "\u2126";
              }
            }
            value = resistanceValue;
            unit = resistanceUnit;
            break;
          case 4:
            double? capacitance = await _scienceLab.getCapacitance();
            String capacitanceValue;
            String capacitanceUnit;
            if (capacitance == null) {
              capacitanceValue = "Cannot measure!";
              capacitanceUnit = "pF";
            } else {
              if (capacitance < 1e-9) {
                capacitanceValue = (capacitance / 1e-12).toStringAsFixed(2);
                capacitanceUnit = "pF";
              } else if (capacitance < 1e-6) {
                capacitanceValue = (capacitance / 1e-9).toStringAsFixed(2);
                capacitanceUnit = "nF";
              } else if (capacitance < 1e-3) {
                capacitanceValue = (capacitance / 1e-6).toStringAsFixed(2);
                capacitanceUnit = "\u00B5F";
              } else if (capacitance < 1e-1) {
                capacitanceValue = (capacitance / 1e-3).toStringAsFixed(2);
                capacitanceUnit = "mF";
              } else {
                capacitanceValue = capacitance.toStringAsFixed(2);
                capacitanceUnit = "F";
              }
            }
            value = capacitanceValue;
            unit = capacitanceUnit;
            break;
          case 5:
            await getIDData();
            break;
          case 6:
            await getIDData();
            break;
          case 7:
            await getIDData();
            break;
          case 8:
            await getIDData();
            break;
          default:
            double? voltage =
                await _scienceLab.getVoltage(knobMarker[_selectedIndex], 1);
            String voltageValue = voltage.toStringAsFixed(2);
            String voltageUnit = unitVolts;
            value = voltageValue;
            unit = voltageUnit;
        }
        notifyListeners();
        _isProcessing = false;
      }
    });
  }

  Future<void> getIDData() async {
    try {
      if (!isSwitchChecked) {
        double frequency =
            await _scienceLab.getFrequency(knobMarker[_selectedIndex]);
        value = frequency.toStringAsFixed(2);
        unit = unitHz;
      } else {
        await _scienceLab.countPulses(knobMarker[_selectedIndex]);
        int pulseCount = await _scienceLab.readPulseCount();
        value = pulseCount.toString();
        unit = "";
      }
    } catch (e) {
      value = "Cannot measure!";
      unit = "null";
    }
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    super.dispose();
  }
}
