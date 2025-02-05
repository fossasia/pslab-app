import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:data/data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pslab/others/science_lab_common.dart';

import '../communication/analytics_class.dart';
import '../communication/science_lab.dart';
import '../others/audio_jack.dart';

enum CHANNEL { CH1, CH2, CH3, MIC }

enum MODE { RISING, FALLING, DUAL }

enum ChannelMeasurements {
  FREQUENCY,
  PERIOD,
  AMPLITUDE,
  POSITIVE_PEAK,
  NEGATIVE_PEAK
}

class OscilloscopeStateProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void updateSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  int? samples;
  double? timeGap;
  double? timebase;
  double maxTimebase = 102.4;
  bool isCH1Selected = false;
  bool isCH2Selected = false;
  bool isCH3Selected = false;
  bool isMICSelected = false;
  bool isInBuiltMICSelected = false;
  bool isAudioInputSelected = false;
  bool isTriggerSelected = false;
  bool isTriggered = false;
  bool isFourierTransformSelected = false;
  bool isXYPlotSelected = false;
  late bool sineFit;
  late bool squareFit;
  late String triggerChannel;
  late String triggerMode;
  late String curveFittingChannel1;
  late String curveFittingChannel2;
  late Map<String, double> xOffsets;
  late Map<String, double> yOffsets;
  double? _trigger;
  late ScienceLab _scienceLab;
  AudioJack? _audioJack;
  AnalyticsClass? _analyticsClass;
  bool _monitor = true;
  double? _maxAmp;
  // double? _maxFreq;
  bool _isRecording = false;
  bool _isRunning = true;
  // bool _isMeasurementsChecked = false;
  late Map<String, int> _channelIndexMap;
  String xyPlotAxis1 = 'CH1';
  String xyPlotAxis2 = 'CH2';
  List<List<FlSpot>> dataEntries = [];
  late List<String> dataParamsChannels;

  double _yAxisScale = 16;
  double get yAxisScale => _yAxisScale;

  int _timebaseDivisions = 8;
  int get timebaseDivisions => _timebaseDivisions;

  double timebaseSlider = 0;

  bool _isProcessing = false;

  Future<void> initialize() async {
    _channelIndexMap = <String, int>{};
    _channelIndexMap[CHANNEL.CH1.toString()] = 1;
    _channelIndexMap[CHANNEL.CH2.toString()] = 2;
    _channelIndexMap[CHANNEL.CH3.toString()] = 3;
    _channelIndexMap[CHANNEL.MIC.toString()] = 4;

    _scienceLab = ScienceLabCommon.scienceLab!;
    triggerChannel = CHANNEL.CH1.toString();
    _trigger = 0;
    timebase = 875;
    samples = 512;
    timeGap = 2;

    xOffsets = <String, double>{};
    xOffsets[CHANNEL.CH1.toString()] = 0.0;
    xOffsets[CHANNEL.CH2.toString()] = 0.0;
    xOffsets[CHANNEL.CH3.toString()] = 0.0;
    xOffsets[CHANNEL.MIC.toString()] = 0.0;
    yOffsets = <String, double>{};
    yOffsets[CHANNEL.CH1.toString()] = 0.0;
    yOffsets[CHANNEL.CH2.toString()] = 0.0;
    yOffsets[CHANNEL.CH3.toString()] = 0.0;
    yOffsets[CHANNEL.MIC.toString()] = 0.0;

    sineFit = true;
    squareFit = false;
    curveFittingChannel1 = '';
    curveFittingChannel2 = '';
    _analyticsClass = AnalyticsClass();

    monitor();
  }

  Future<void> monitor() async {
    Timer.periodic(
      Duration.zero,
      (timer) async {
        if (!_monitor) {
          timer.cancel();
          return;
        }

        if (_isProcessing) {
          return;
        }
        _isProcessing = true;

        if (_isRunning) {
          if (isInBuiltMICSelected && _audioJack == null) {
            _audioJack = AudioJack();
            await _audioJack!.configure();
          }

          List<String> channels = [];

          if (_scienceLab.isConnected() && isXYPlotSelected) {
            await XYPlotTask(xyPlotAxis1, xyPlotAxis2);
          } else {
            if (_scienceLab.isConnected()) {
              if (isCH1Selected) {
                channels.add(CHANNEL.CH1.toString());
              }
              if (isCH2Selected) {
                channels.add(CHANNEL.CH2.toString());
              }
              if (isCH3Selected) {
                channels.add(CHANNEL.CH3.toString());
              }
            }
            if (isAudioInputSelected && isInBuiltMICSelected ||
                (_scienceLab.isConnected() && isMICSelected)) {
              channels.add(CHANNEL.MIC.toString());
            }
            if (channels.isNotEmpty) {
              await CaptureTask(channels);
            }
          }
          if (!isInBuiltMICSelected && _audioJack != null) {
            await _audioJack?.close();
            _audioJack = null;
          }
        }
        _isProcessing = false;
      },
    );
  }

  Future<void> XYPlotTask(String xyPlotAxis1, String xyPlotAxis2) async {}

  Future<void> CaptureTask(List<String> channels) async {
    List<List<FlSpot>> entries = [];
    List<List<FlSpot>> curveFitEntries = [];
    int noOfChannels = channels.length;
    List<String> paramsChannels = channels;
    String? channel;

    if (isInBuiltMICSelected) {
      noOfChannels--;
    }
    try {
      List<double>? xData;
      List<double>? yData;
      double? xValue;
      List<List<String>> yDataString = [];
      List<String> xDataString = [];
      _maxAmp = 0;
      await _scienceLab.captureTraces(
          4, samples!, timeGap!, channel, false, null);
      await Future.delayed(
          Duration(milliseconds: (samples! * timeGap! * 1e-3).toInt()));
      for (int i = 0; i < noOfChannels; i++) {
        entries.add([]);
        channel = channels[i];
        isTriggered = false;
        Map<String, List<double>> data;
        data = await _scienceLab.fetchTrace(_channelIndexMap[channel]!);
        xData = data['x'];
        yData = data['y'];
        xValue = xData?[0];
        int n = min(xData!.length, yData!.length);
        xDataString = List.filled(n, '');
        yDataString.add(List.filled(n, ''));
        List<Complex> fftOut = [];
        if (isFourierTransformSelected) {
          List<Complex> yComplex = List.filled(yData.length, const Complex(0));
          for (int j = 0; j < yData.length; j++) {
            yComplex[j] = Complex(yData[j]);
          }
          fftOut = fft(yComplex);
        }
        double factor = samples! * timeGap! * 1e-3;
        // _maxFreq = (n / 2 - 1) / factor;
        double mA = 0;
        double prevY = yData[0];
        bool increasing = false;
        for (int j = 0; j < n; j++) {
          double currY = yData[j];
          xData[j] = xData[j] / ((timebase == 875) ? 1 : 1000);
          if (!isFourierTransformSelected) {
            if (isTriggerSelected && triggerChannel == channel) {
              if (currY > prevY) {
                increasing = true;
              } else if (currY < prevY && increasing) {
                increasing = false;
              }
              if (isTriggered) {
                double k = xValue! / ((timebase == 875) ? 1 : 1000);
                entries[i].add(FlSpot(k, yData[j]));
                xValue += timeGap!;
              }
              if (triggerMode == MODE.RISING.toString() &&
                  prevY < _trigger! &&
                  currY >= _trigger! &&
                  increasing) {
                isTriggered = true;
              } else if (triggerMode == MODE.FALLING.toString() &&
                  prevY > _trigger! &&
                  currY <= _trigger! &&
                  !increasing) {
                isTriggered = true;
              } else if (triggerMode == MODE.DUAL.toString() &&
                      (prevY < _trigger! && currY >= _trigger! && increasing) ||
                  (prevY > _trigger! && currY <= _trigger! && !increasing)) {
                isTriggered = true;
              }
              prevY = currY;
            } else {
              entries[i].add(FlSpot(xData[j], yData[j]));
            }
          } else {
            if (j < n / 2) {
              double y = fftOut[j].abs() / samples!;
              if (y > mA) {
                mA = y;
              }
              entries[i].add(FlSpot(j / factor, y));
            }
            xDataString[j] = xData[j].toString();
            yDataString[i][j] = yData[j].toString();
          }
        }
        if (sineFit && channel == curveFittingChannel1) {
          if (curveFitEntries.isEmpty) {
            curveFitEntries.add([]);
          }
          List<double> sinFit = _analyticsClass!.sineFit(xData, yData);
          double amp = sinFit[0];
          double freq = sinFit[1];
          double offset = sinFit[2];
          double phase = sinFit[3];

          freq = freq / 1e6;
          double max = xData[xData.length - 1];
          for (int j = 0; j < 500; j++) {
            double x = j * max / 500;
            double y = offset +
                amp * sin((freq * (2 * pi)).abs()) * x +
                phase * pi / 180;
            curveFitEntries[curveFitEntries.length - 1].add(FlSpot(x, y));
          }
        }

        if (squareFit && channel == curveFittingChannel2) {
          if (curveFitEntries.isEmpty) {
            curveFitEntries.add([]);
          }
          List<double> sqFit = _analyticsClass!.squareFit(xData, yData);
          double amp = sqFit[0];
          double freq = sqFit[1];
          double phase = sqFit[2];
          double dc = sqFit[3];
          double offset = sqFit[4];

          freq = freq / 1e6;
          double max = xData[xData.length - 1];
          for (int j = 0; j < 500; j++) {
            double x = j * max / 500;
            double t = 2 * pi * freq * (x - phase);
            double y;
            if (t % (2 * pi) < 2 * pi * dc) {
              y = offset + amp;
            } else {
              y = offset - 2 * amp;
            }
            curveFitEntries[curveFitEntries.length - 1].add(FlSpot(x, y));
          }
        }
        if (mA > _maxAmp!) {
          _maxAmp = mA;
        }
      }

      if (isInBuiltMICSelected) {
        noOfChannels++;
        isTriggered = false;
        entries.add([]);
        _audioJack ??= AudioJack();
        List<double> buffer = _audioJack!.read();
        xDataString = List.filled(buffer.length, '');
        yDataString.add(List.filled(buffer.length, ''));

        int n = buffer.length;
        List<Complex> fftOut = [];
        if (isFourierTransformSelected) {
          List<Complex> yComplex = List.filled(buffer.length, const Complex(0));
          for (int j = 0; j < buffer.length; j++) {
            double audioValue = buffer[j] * 3;
            yComplex[j] = Complex(audioValue);
          }
          fftOut = fft(yComplex);
        }
        double factor = buffer.length * timeGap! * 1e-3;
        // _maxFreq = (n / 2 - 1) / factor;
        double mA = 0;
        double prevY = buffer[0] * 3;
        bool increasing = false;
        double xDataPoint = 0;
        for (int i = 0; i < n; i++) {
          double j = ((i / AudioJack.samplingRate) * 1000000.0);
          j = j / ((timebase == 875) ? 1 : 1000);
          double audioValue = buffer[i] * 3;
          double currY = audioValue;
          if (!isFourierTransformSelected) {
            if (noOfChannels == 1) {
              xDataString[i] = j.toString();
            }
            if (isTriggerSelected && triggerChannel == CHANNEL.MIC.toString()) {
              if (currY > prevY) {
                increasing = true;
              } else if (currY < prevY && increasing) {
                increasing = false;
              }
              if (triggerMode == MODE.RISING.toString() &&
                  prevY < _trigger! &&
                  currY >= _trigger! &&
                  increasing) {
                isTriggered = true;
              } else if (triggerMode == MODE.FALLING.toString() &&
                  prevY > _trigger! &&
                  currY <= _trigger! &&
                  !increasing) {
                isTriggered = true;
              } else if (triggerMode == MODE.DUAL.toString() &&
                      (prevY < _trigger! && currY >= _trigger! && increasing) ||
                  (prevY > _trigger! && currY <= _trigger! && !increasing)) {
                isTriggered = true;
              }
              if (isTriggered) {
                double k = ((xDataPoint / AudioJack.samplingRate) * 1000000.0);
                k = k / ((timebase == 875) ? 1 : 1000);
                entries[entries.length - 1].add(FlSpot(k, audioValue));
                xDataPoint++;
              }
              prevY = currY;
            } else {
              entries[entries.length - 1].add(FlSpot(j, audioValue));
            }
          } else {
            if (i < n / 2) {
              double y = fftOut[i].abs() / samples!;
              if (y > mA) {
                mA = y;
              }
              entries[entries.length - 1].add(FlSpot((i / factor), y));
            }
          }
          yDataString[yDataString.length - 1][i] = audioValue.toString();
        }
        if (mA > _maxAmp!) {
          _maxAmp = mA;
        }
      }

      if (_isRecording) {}

      dataEntries = List.from(entries);
      dataParamsChannels = List.from(paramsChannels);
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  void setYAxisScale(double range) {
    _yAxisScale = range;
    notifyListeners();
  }

  void setTimebaseDivisions(int divisions) {
    _timebaseDivisions = divisions;
    notifyListeners();
  }

  void setTimebase(double value) {
    switch (value) {
      case 0:
        timebase = 875.00;
        break;
      case 1:
        timebase = 1.00;
        break;
      case 2:
        timebase = 2.00;
        break;
      case 3:
        timebase = 4.00;
        break;
      case 4:
        timebase = 8.00;
        break;
      case 5:
        timebase = 25.60;
        break;
      case 6:
        timebase = 38.40;
        break;
      case 7:
        timebase = 51.20;
        break;
      case 8:
        timebase = 102.40;
        break;
      default:
        timebase = 875.00;
        break;
    }
    notifyListeners();
  }

  double getTimebaseInterval() {
    switch (timebase) {
      case 875.00:
        return 100;
      case 1.00:
        return 0.2;
      case 2.00:
        return 0.3;
      case 4.00:
        return 0.7;
      case 8.00:
        return 1;
      case 25.60:
        return 4;
      case 38.40:
        return 10;
      case 51.20:
        return 10;
      case 102.40:
        return 20;
      default:
        return 100;
    }
  }

  List<LineChartBarData> createLineBarsData() {
    List<Color> colors = [
      Colors.cyan,
      Colors.green,
      Colors.white,
      Colors.deepPurple
    ];
    return List<LineChartBarData>.generate(dataEntries.length, (index) {
      return LineChartBarData(
        spots: dataEntries[index],
        isCurved: true,
        color: colors[index % colors.length],
        barWidth: 1,
        dotData: const FlDotData(
          show: false,
        ),
      );
    });
  }
}
