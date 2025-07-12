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
    double factor = 64;
    List<double> diff = [];
    for (int i = 0; i < this.timestamps.length - 1; i++) {
      diff.add(this.timestamps[i + 1] - this.timestamps[i]);
    }
    for (int i = 0; i < diff.length; i++) {
      if (diff[i] < 0) {
        for (int j = i + 1; j < this.timestamps.length; j++) {
          this.timestamps[j] += ((1 << 16) - 1);
        }
      }
    }
    for (int i = 0; i < this.timestamps.length; i++) {
      this.timestamps[i] = (this.timestamps[i]) / factor;
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
      yAxis[0] = state.toDouble();
      int j = 1;
      for (int i = 1; i < dLength; i++, j++) {
        xAxis[j] = timestamps[i];
        yAxis[j] = state.toDouble();
        if (state == high) {
          state = low;
        } else {
          state = high;
        }
        j++;
        xAxis[j] = timestamps[i];
        yAxis[j] = state.toDouble();
      }
      plotLength = j;
    } else if (mode == everyFallingEdge) {
      xAxis[0] = 0;
      yAxis[0] = high.toDouble();
      int j = 1;
      for (int i = 1; i < dLength; i++, j++) {
        xAxis[j] = timestamps[i];
        yAxis[j] = high.toDouble();
        j++;
        xAxis[j] = timestamps[i];
        yAxis[j] = low.toDouble();
        j++;
        xAxis[j] = timestamps[i];
        yAxis[j] = high.toDouble();
      }
      state = high;
      plotLength = j;
    } else if (mode == everyRisingEdge ||
        mode == everyFourthRisingEdge ||
        mode == everySixteenthRisingEdge) {
      xAxis[0] = 0;
      yAxis[0] = low.toDouble();
      int j = 1;
      for (int i = 1, j = 1; i < dLength; i++, j++) {
        xAxis[j] = timestamps[i];
        yAxis[j] = low.toDouble();
        j++;
        xAxis[j] = timestamps[i];
        yAxis[j] = high.toDouble();
        j++;
        xAxis[j] = timestamps[i];
        yAxis[j] = low.toDouble();
      }
      state = low;
      plotLength = j;
    }
  }

  List<double> getXAxis() {
    return xAxis.sublist(0, plotLength);
  }

  List<double> getYAxis() {
    return yAxis.sublist(0, plotLength);
  }
}
