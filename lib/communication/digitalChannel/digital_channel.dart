import 'dart:collection';

class DigitalChannel {
  static const int EVERY_EDGE = 1;
  static const int DISABLED = 0;
  static const int EVERY_SIXTEENTH_RISING_EDGE = 5;
  static const int EVERY_FOURTH_RISING_EDGE = 4;
  static const int EVERY_RISING_EDGE = 3;
  static const int EVERY_FALLING_EDGE = 2;
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
    mode = EVERY_EDGE;
  }

  void loadData(
      LinkedHashMap<String, int> initialStates, List<double> timestamps) {
    if (initialStateOverride != 0) {
      initialState = (initialStateOverride - 1) == 1;
      initialStateOverride = 0;
    } else {
      final int? s = initialStates[channelName]!;
      initialState = s != null && s == 1;
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
    int HIGH = 1, LOW = 0, state;
    if (initialState) {
      state = LOW;
    } else {
      state = HIGH;
    }

    if (mode == DISABLED) {
      xAxis[0] = 0;
      yAxis[0] = 0;
      plotLength = 1;
    } else if (mode == EVERY_EDGE) {
      xAxis[0] = 0;
      yAxis[0] = state as double;
      int length = 0;
      for (int i = 1, j = 1; i < dLength; i++, j++) {
        xAxis[j] = timestamps[i];
        yAxis[j] = state as double;
        if (state == HIGH) {
          state = LOW;
        } else {
          state = HIGH;
        }
        j++;
        xAxis[j] = timestamps[i];
        yAxis[j] = state as double;
        length = j;
      }
      plotLength = length;
    } else if (mode == EVERY_FALLING_EDGE) {
      xAxis[0] = 0;
      yAxis[0] = HIGH as double;
      int length = 0;
      for (int i = 1, j = 1; i < dLength; i++, j++) {
        xAxis[j] = timestamps[i];
        yAxis[j] = HIGH as double;
        j++;
        xAxis[j] = timestamps[i];
        yAxis[j] = LOW as double;
        j++;
        xAxis[j] = timestamps[i];
        yAxis[j] = HIGH as double;
        length = j;
      }
      state = HIGH;
      plotLength = length;
    } else if (mode == EVERY_RISING_EDGE ||
        mode == EVERY_FOURTH_RISING_EDGE ||
        mode == EVERY_SIXTEENTH_RISING_EDGE) {
      xAxis[0] = 0;
      yAxis[0] = LOW as double;
      int length = 0;
      for (int i = 1, j = 1; i < dLength; i++, j++) {
        xAxis[j] = timestamps[i];
        yAxis[j] = LOW as double;
        j++;
        xAxis[j] = timestamps[i];
        yAxis[j] = HIGH as double;
        j++;
        xAxis[j] = timestamps[i];
        yAxis[j] = LOW as double;
        length = j;
      }
      state = LOW;
      plotLength = length;
    }

    List<double> getXAxis() {
      return List.from(xAxis.getRange(0, plotLength));
    }

    List<double> getYAxis() {
      return List.from(yAxis.getRange(0, plotLength));
    }
  }
}
