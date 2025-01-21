import 'package:flutter/material.dart';

class OscilloscopeStateProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  bool? isCH1Selected = false;
  bool? isCH2Selected = false;
  bool? isCH3Selected = false;
  bool? isMICSelected = false;
  bool? isInBuiltMICSelected = false;
  bool? isAudioInputSelected = false;

  double yAxisRange = 16;

  int get selectedIndex => _selectedIndex;

  void updateSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
