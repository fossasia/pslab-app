import 'dart:collection';

class DigitalChannel {
  static const int everyEdge = 1;
  static const int disabled = 0;
  static const int everySixteenthRisingEdge = 5;
  static const int everyFourthRisingEdge = 4;
  static const int everyRisingEdge = 3;
  static const int everyFallingEdge = 2;
  static List<String> digitalChannelNames = [
    'LA1',
    'LA2',
    'LA3',
    'LA4',
    'RES',
    'EXT',
    'FRQ'
  ];
  late String channelName, dataType;
  late int initialStateOverride,
      channelNumber,
      length,
      prescaler,
      trigger,
      dLength,
      plotLength,
      maxTime,
      mode;
  late List<double> xAxis, yAxis, timestamps;
  late bool initialState;
  late double gain, maxT;

  DigitalChannel(this.channelNumber) {
    channelName = digitalChannelNames[channelNumber];
    gain = 0;
    xAxis = List.filled(20000, 0.0);
    yAxis = List.filled(20000, 0.0);
    timestamps = List.filled(10000, 0.0);
    length = 100;
    initialState = false;
    prescaler = 0;
    dataType = 'int';
    trigger = 0;
    dLength = 0;
    plotLength = 0;
    maxT = 0;
    maxTime = 0;
    initialStateOverride = 0;
    mode = everyEdge;
  }

  void loadData(
      LinkedHashMap<String, int> initialStates, List<double> timestamps) {
    if (initialStateOverride != 0) {
      initialState = (initialStateOverride - 1) == 1;
      initialStateOverride = 0;
    } else {
      final int s = initialStates[channelName]!;
      initialState = s == 1;
    }
    this.timestamps.setRange(0, timestamps.length, timestamps);
    dLength = timestamps.length;
    double factor;
    switch (prescaler) {
      case 0:
        factor = 64;
        break;
      case 1:
        factor = 8;
        break;
      case 2:
        factor = 4;
        break;
      default:
        factor = 1;
        break;
    }
    for (int i = 0; i < this.timestamps.length; i++) {
      this.timestamps[i] /= factor;
    }
    if (dLength > 0) {
      maxT = this.timestamps[this.timestamps.length - 1];
    } else {
      maxT = 0;
    }
  }

  void generateAxes() {
    int high = 1, low = 0, state;
    if (initialState) {
      state = low;
    } else {
      state = high;
    }

    if (mode == disabled) {
      xAxis[0] = 0;
      yAxis[0] = 0;
      plotLength = 1;
    } else if (mode == everyEdge) {
      xAxis[0] = 0;
      yAxis[0] = state as double;
      int length = 0;
      for (int i = 1, j = 1; i < dLength; i++, j++) {
        xAxis[j] = timestamps[i];
        yAxis[j] = state as double;
        if (state == high) {
          state = low;
        } else {
          state = high;
        }
        j++;
        xAxis[j] = timestamps[i];
        yAxis[j] = state as double;
        length = j;
      }
      plotLength = length;
    } else if (mode == everyFallingEdge) {
      xAxis[0] = 0;
      yAxis[0] = high as double;
      int length = 0;
      for (int i = 1, j = 1; i < dLength; i++, j++) {
        xAxis[j] = timestamps[i];
        yAxis[j] = high as double;
        j++;
        xAxis[j] = timestamps[i];
        yAxis[j] = low as double;
        j++;
        xAxis[j] = timestamps[i];
        yAxis[j] = high as double;
        length = j;
      }
      state = high;
      plotLength = length;
    } else if (mode == everyRisingEdge ||
        mode == everyFourthRisingEdge ||
        mode == everySixteenthRisingEdge) {
      xAxis[0] = 0;
      yAxis[0] = low as double;
      int length = 0;
      for (int i = 1, j = 1; i < dLength; i++, j++) {
        xAxis[j] = timestamps[i];
        yAxis[j] = low as double;
        j++;
        xAxis[j] = timestamps[i];
        yAxis[j] = high as double;
        j++;
        xAxis[j] = timestamps[i];
        yAxis[j] = low as double;
        length = j;
      }
      state = low;
      plotLength = length;
    }
  }
}
