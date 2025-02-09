import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:data/data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/others/science_lab_common.dart';

import '../communication/analytics_class.dart';
import '../communication/science_lab.dart';
import '../others/audio_jack.dart';

enum CHANNEL { ch1, ch2, ch3, mic }

enum MODE { rising, falling, dual }

enum ChannelMeasurements {
  frequency,
  period,
  amplitude,
  positivePeak,
  negativePeak
}

AudioJack? _audioJack;

class OscilloscopeStateProvider extends ChangeNotifier {
  late int _selectedIndex;

  int get selectedIndex => _selectedIndex;

  void updateSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  late int samples;
  late double timeGap;
  late double timebase;
  double maxTimebase = 102.4;
  late bool isCH1Selected;
  late bool isCH2Selected;
  late bool isCH3Selected;
  late bool isMICSelected;
  late bool isInBuiltMICSelected;
  late bool isAudioInputSelected;
  late bool isTriggerSelected;
  late bool isTriggered;
  late bool isFourierTransformSelected;
  late bool isXYPlotSelected;
  late bool sineFit;
  late bool squareFit;
  late String triggerChannel;
  late String triggerMode;
  late String curveFittingChannel1;
  late String curveFittingChannel2;
  late Map<String, double> xOffsets;
  late Map<String, double> yOffsets;
  late double _trigger;
  late ScienceLab _scienceLab;
  late AnalyticsClass _analyticsClass;
  late bool _monitor;
  late double _maxAmp;
  // late double _maxFreq;
  late bool _isRecording;
  late bool _isRunning;
  // bool _isMeasurementsChecked = false;
  late Map<String, int> _channelIndexMap;
  late String xyPlotAxis1;
  late String xyPlotAxis2;
  late List<List<FlSpot>> dataEntries;
  late List<String> dataParamsChannels;

  late double _yAxisScale;
  double get yAxisScale => _yAxisScale;

  late int _timebaseDivisions;
  int get timebaseDivisions => _timebaseDivisions;

  late double timebaseSlider;

  late int oscillscopeRangeSelection;

  late bool _isProcessing;

  late Timer _timer;

  OscilloscopeStateProvider() {
    _selectedIndex = 0;

    isCH1Selected = false;
    isCH2Selected = false;
    isCH3Selected = false;
    isMICSelected = false;
    isInBuiltMICSelected = false;
    isAudioInputSelected = false;
    isTriggerSelected = false;
    isTriggered = false;
    isFourierTransformSelected = false;
    isXYPlotSelected = false;
    _monitor = true;
    _isRecording = false;
    _isRunning = true;
    xyPlotAxis1 = 'CH1';
    xyPlotAxis2 = 'CH2';
    dataEntries = [];
    _yAxisScale = 16;
    _timebaseDivisions = 8;
    timebaseSlider = 0;
    oscillscopeRangeSelection = 0;
    _isProcessing = false;

    _channelIndexMap = <String, int>{};
    _channelIndexMap[CHANNEL.ch1.toString()] = 1;
    _channelIndexMap[CHANNEL.ch2.toString()] = 2;
    _channelIndexMap[CHANNEL.ch3.toString()] = 3;
    _channelIndexMap[CHANNEL.mic.toString()] = 4;

    _scienceLab = ScienceLabCommon.scienceLab;
    triggerChannel = CHANNEL.ch1.toString();
    _trigger = 0;
    timebase = 875;
    samples = 512;
    timeGap = 2;

    xOffsets = <String, double>{};
    xOffsets[CHANNEL.ch1.toString()] = 0.0;
    xOffsets[CHANNEL.ch2.toString()] = 0.0;
    xOffsets[CHANNEL.ch3.toString()] = 0.0;
    xOffsets[CHANNEL.mic.toString()] = 0.0;
    yOffsets = <String, double>{};
    yOffsets[CHANNEL.ch1.toString()] = 0.0;
    yOffsets[CHANNEL.ch2.toString()] = 0.0;
    yOffsets[CHANNEL.ch3.toString()] = 0.0;
    yOffsets[CHANNEL.mic.toString()] = 0.0;

    sineFit = true;
    squareFit = false;
    curveFittingChannel1 = '';
    curveFittingChannel2 = '';
    _analyticsClass = AnalyticsClass();

    monitor();
  }

  Future<void> monitor() async {
    _timer = Timer.periodic(
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
            await _audioJack?.configure();
          }

          List<String> channels = [];

          if (_scienceLab.isConnected() && isXYPlotSelected) {
            await xyPlotTask(xyPlotAxis1, xyPlotAxis2);
          } else {
            if (_scienceLab.isConnected()) {
              if (isCH1Selected) {
                channels.add(CHANNEL.ch1.toString());
              }
              if (isCH2Selected) {
                channels.add(CHANNEL.ch2.toString());
              }
              if (isCH3Selected) {
                channels.add(CHANNEL.ch3.toString());
              }
            }
            if (isAudioInputSelected && isInBuiltMICSelected ||
                (_scienceLab.isConnected() && isMICSelected)) {
              channels.add(CHANNEL.mic.toString());
            }
            if (channels.isNotEmpty) {
              await captureTask(channels);
            } else {
              dataEntries = [];
            }
          }
        }
        _isProcessing = false;
      },
    );
  }

  Future<void> xyPlotTask(String xyPlotAxis1, String xyPlotAxis2) async {}

  Future<void> captureTask(List<String> channels) async {
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
      if (noOfChannels > 0) {
        await _scienceLab.captureTraces(
            4, samples, timeGap, channel, false, null);
      }
      await Future.delayed(
          Duration(milliseconds: (samples * timeGap * 1e-3).toInt()));
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
        double factor = samples * timeGap * 1e-3;
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
                xValue += timeGap;
              }
              if (triggerMode == MODE.rising.toString() &&
                  prevY < _trigger &&
                  currY >= _trigger &&
                  increasing) {
                isTriggered = true;
              } else if (triggerMode == MODE.falling.toString() &&
                  prevY > _trigger &&
                  currY <= _trigger &&
                  !increasing) {
                isTriggered = true;
              } else if (triggerMode == MODE.dual.toString() &&
                      (prevY < _trigger && currY >= _trigger && increasing) ||
                  (prevY > _trigger && currY <= _trigger && !increasing)) {
                isTriggered = true;
              }
              prevY = currY;
            } else {
              entries[i].add(FlSpot(xData[j], yData[j]));
            }
          } else {
            if (j < n / 2) {
              double y = fftOut[j].abs() / samples;
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
          List<double> sinFit = _analyticsClass.sineFit(xData, yData);
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
          List<double> sqFit = _analyticsClass.squareFit(xData, yData);
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
        if (mA > _maxAmp) {
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
        double factor = buffer.length * timeGap * 1e-3;
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
            if (isTriggerSelected && triggerChannel == CHANNEL.mic.toString()) {
              if (currY > prevY) {
                increasing = true;
              } else if (currY < prevY && increasing) {
                increasing = false;
              }
              if (triggerMode == MODE.rising.toString() &&
                  prevY < _trigger &&
                  currY >= _trigger &&
                  increasing) {
                isTriggered = true;
              } else if (triggerMode == MODE.falling.toString() &&
                  prevY > _trigger &&
                  currY <= _trigger &&
                  !increasing) {
                isTriggered = true;
              } else if (triggerMode == MODE.dual.toString() &&
                      (prevY < _trigger && currY >= _trigger && increasing) ||
                  (prevY > _trigger && currY <= _trigger && !increasing)) {
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
              double y = fftOut[i].abs() / samples;
              if (y > mA) {
                mA = y;
              }
              entries[entries.length - 1].add(FlSpot((i / factor), y));
            }
          }
          yDataString[yDataString.length - 1][i] = audioValue.toString();
        }
        if (mA > _maxAmp) {
          _maxAmp = mA;
        }
      }

      if (_isRecording) {}

      dataEntries = List.from(entries);
      dataParamsChannels = List.from(paramsChannels);
      notifyListeners();
    } catch (e) {
      logger.e(e);
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
        timebase = 1000.00;
        break;
      case 2:
        timebase = 2000.00;
        break;
      case 3:
        timebase = 4000.00;
        break;
      case 4:
        timebase = 8000.00;
        break;
      case 5:
        timebase = 25600.00;
        break;
      case 6:
        timebase = 38400.00;
        break;
      case 7:
        timebase = 51200.00;
        break;
      case 8:
        timebase = 102400.00;
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
      case 1000.00:
        return 0.2;
      case 2000.00:
        return 0.3;
      case 4000.00:
        return 0.7;
      case 8000.00:
        return 1;
      case 25600.00:
        return 4;
      case 38400.00:
        return 10;
      case 51200.00:
        return 10;
      case 102400.00:
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

  @override
  void dispose() {
    _monitor = false;
    if (_timer.isActive) {
      _timer.cancel();
    }
    super.dispose();
  }
}
