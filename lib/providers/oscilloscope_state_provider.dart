import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:data/data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pslab/models/oscilloscope_measurements.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/others/oscilloscope_axes_scale.dart';
import 'package:pslab/providers/locator.dart';

import '../communication/analytics_class.dart';
import '../communication/science_lab.dart';
import '../others/audio_jack.dart';

enum MODE { rising, falling, dual }

enum ChannelMeasurements {
  frequency,
  period,
  amplitude,
  positivePeak,
  negativePeak
}

List<Color> colors = [
  Colors.cyan,
  Colors.green,
  Colors.white,
  Colors.purpleAccent
];

class OscilloscopeStateProvider extends ChangeNotifier {
  late AudioJack _audioJack;
  late int _selectedIndex;
  late String selectedChannelOffset;

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
  late double trigger;
  late ScienceLab _scienceLab;
  late AnalyticsClass _analyticsClass;
  late bool _monitor;
  late double _maxAmp;
  late double _maxFreq;
  late bool _isRecording;
  late bool isRunning;
  bool isMeasurementsChecked = false;
  late Map<String, int> _channelIndexMap;
  late String xyPlotAxis1;
  late String xyPlotAxis2;
  late List<List<FlSpot>> dataEntries;
  late List<List<FlSpot>> dataEntriesXYPlot;
  late List<List<FlSpot>> dataEntriesCurveFit;
  late List<String> dataParamsChannels;
  late int _timebaseDivisions;
  int get timebaseDivisions => _timebaseDivisions;

  late double timebaseSlider;

  late int oscillscopeRangeSelection;

  late bool _isProcessing;

  late Timer _timer;

  late OscilloscopeAxesScale oscilloscopeAxesScale;

  OscilloscopeStateProvider() {
    _audioJack = AudioJack();
    _selectedIndex = 0;
    selectedChannelOffset = 'CH1';

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
    isRunning = true;
    xyPlotAxis1 = 'CH1';
    xyPlotAxis2 = 'CH2';
    dataEntries = [];
    dataEntriesXYPlot = [];
    dataEntriesCurveFit = [];
    _timebaseDivisions = 8;
    timebaseSlider = 0;
    oscillscopeRangeSelection = 0;
    _isProcessing = false;

    dataEntries = <List<FlSpot>>[];
    dataEntriesXYPlot = <List<FlSpot>>[];
    dataEntriesCurveFit = <List<FlSpot>>[];
    dataParamsChannels = <String>[];

    _channelIndexMap = <String, int>{};
    _channelIndexMap['CH1'] = 1;
    _channelIndexMap['CH2'] = 2;
    _channelIndexMap['CH3'] = 3;
    _channelIndexMap['MIC'] = 4;

    _scienceLab = getIt.get<ScienceLab>();
    triggerChannel = 'CH1';
    triggerMode = MODE.rising.toString();
    trigger = 0;
    timebase = 875;
    samples = 512;
    timeGap = 2;

    xOffsets = <String, double>{};
    xOffsets['CH1'] = 0.0;
    xOffsets['CH2'] = 0.0;
    xOffsets['CH3'] = 0.0;
    xOffsets['MIC'] = 0.0;
    yOffsets = <String, double>{};
    yOffsets['CH1'] = 0.0;
    yOffsets['CH2'] = 0.0;
    yOffsets['CH3'] = 0.0;
    yOffsets['MIC'] = 0.0;

    sineFit = true;
    squareFit = false;
    curveFittingChannel1 = '';
    curveFittingChannel2 = '';
    _analyticsClass = AnalyticsClass();
    oscilloscopeAxesScale = OscilloscopeAxesScale();

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

        if (isRunning) {
          if (isInBuiltMICSelected && !_audioJack.isListening()) {
            await _audioJack.initialize();
            await _audioJack.start();
          }

          List<String> channels = [];

          if (_scienceLab.isConnected() && isXYPlotSelected) {
            await xyPlotTask(xyPlotAxis1, xyPlotAxis2);
          } else {
            if (_scienceLab.isConnected()) {
              if (isCH1Selected) {
                channels.add('CH1');
              }
              if (isCH2Selected) {
                channels.add('CH2');
              }
              if (isCH3Selected) {
                channels.add('CH3');
              }
            }
            if (isAudioInputSelected && isInBuiltMICSelected ||
                (_scienceLab.isConnected() && isMICSelected)) {
              channels.add('MIC');
            }
            if (channels.isNotEmpty) {
              await captureTask(channels);
            } else {
              resetGraph();
              dataEntries = [];
            }
          }
          if (!isInBuiltMICSelected && _audioJack.isListening()) {
            await _audioJack.close();
          }
        }
        _isProcessing = false;
      },
    );
  }

  Future<void> xyPlotTask(String xyPlotAxis1, String xyPlotAxis2) async {
    String analogInput1 = xyPlotAxis1;
    String analogInput2 = xyPlotAxis2;
    List<List<FlSpot>> entries = [];

    Map<String, List<double>> data;
    entries.add([]);
    if (analogInput1 == analogInput2) {
      await _scienceLab.captureTraces(
          1, samples, timeGap, analogInput1, isTriggerSelected, null);
      data = await _scienceLab.fetchTrace(1);
      List<double>? yData = data['y'];
      int n = yData!.length;
      for (int i = 0; i < n; i++) {
        entries[0].add(FlSpot(yData[i], yData[i]));
      }
    } else {
      int noOfChannels = 1;
      if ((analogInput1 == 'CH1' && analogInput2 == 'CH2') ||
          (analogInput1 == 'CH2' && analogInput2 == 'CH1')) {
        noOfChannels = 2;
        await _scienceLab.captureTraces(
            noOfChannels, 175, timeGap, 'CH1', isTriggerSelected, null);
        data = await _scienceLab.fetchTrace(1);
        List<double>? yData1 = data['y'];
        data = await _scienceLab.fetchTrace(2);
        List<double>? yData2 = data['y'];
        int n = min(yData1!.length, yData2!.length);
        for (int i = 0; i < n; i++) {
          entries[0].add(FlSpot(yData1[i], yData2[i]));
        }
      } else {
        noOfChannels = 4;
        await _scienceLab.captureTraces(
            noOfChannels, 175, timeGap, 'CH1', isTriggerSelected, null);
        data = await _scienceLab.fetchTrace(_channelIndexMap[analogInput1]!);
        List<double>? yData1 = data['y'];
        data = await _scienceLab.fetchTrace(_channelIndexMap[analogInput2]!);
        List<double>? yData2 = data['y'];
        int n = min(yData1!.length, yData2!.length);
        for (int i = 0; i < n; i++) {
          entries[0].add(FlSpot(yData1[i], yData2[i]));
        }
      }
    }
    dataEntriesXYPlot = List.from(entries);
    notifyListeners();
  }

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
        _maxFreq = (n / 2 - 1) / factor;
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
              } else if ((currY < prevY) && increasing) {
                increasing = false;
              }
              if (isTriggered) {
                double k = xValue! / ((timebase == 875) ? 1 : 1000);
                entries[i].add(FlSpot(k + xOffsets[channels[i]]!,
                    yData[j] + yOffsets[channels[i]]!));
                xValue += timeGap;
              }
              if (triggerMode == MODE.rising.toString() &&
                  prevY < trigger &&
                  currY >= trigger &&
                  increasing) {
                isTriggered = true;
              } else if (triggerMode == MODE.falling.toString() &&
                  prevY > trigger &&
                  currY <= trigger &&
                  !increasing) {
                isTriggered = true;
              } else if (triggerMode == MODE.dual.toString() &&
                  ((prevY < trigger && currY >= trigger && increasing) ||
                      (prevY > trigger && currY <= trigger && !increasing))) {
                isTriggered = true;
              }
              prevY = currY;
            } else {
              entries[i].add(FlSpot(xData[j] - xOffsets[channels[i]]!,
                  yData[j] + yOffsets[channels[i]]!));
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
                amp * sin(((freq * (2 * pi)).abs()) * x + phase * pi / 180);
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
        List<double> buffer = _audioJack.read();
        xDataString = List.filled(buffer.length, '');
        yDataString.add(List.filled(buffer.length, ''));

        int n = buffer.length;
        List<Complex> fftOut = [];
        if (isFourierTransformSelected) {
          List<Complex> yComplex =
              List.filled(buffer.length, const Complex(0), growable: true);
          for (int j = 0; j < buffer.length; j++) {
            double audioValue = buffer[j] * 3;
            yComplex[j] = Complex(audioValue);
          }
          fftOut = fft(yComplex);
        }
        double factor = buffer.length * timeGap * 1e-3;
        _maxFreq = (n / 2 - 1) / factor;
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
            if (isTriggerSelected && triggerChannel == 'MIC') {
              if (currY > prevY) {
                increasing = true;
              } else if (currY < prevY && increasing) {
                increasing = false;
              }
              if (triggerMode == MODE.rising.toString() &&
                  prevY < trigger &&
                  currY >= trigger &&
                  increasing) {
                isTriggered = true;
              } else if (triggerMode == MODE.falling.toString() &&
                  prevY > trigger &&
                  currY <= trigger &&
                  !increasing) {
                isTriggered = true;
              } else if (triggerMode == MODE.dual.toString() &&
                  ((prevY < trigger && currY >= trigger && increasing) ||
                      (prevY > trigger && currY <= trigger && !increasing))) {
                isTriggered = true;
              }
              if (isTriggered) {
                double k = ((xDataPoint / AudioJack.samplingRate) * 1000000.0);
                k = k / ((timebase == 875) ? 1 : 1000);
                entries[entries.length - 1].add(FlSpot(
                    k - xOffsets['MIC']!, audioValue + yOffsets['MIC']!));
                xDataPoint++;
              }
              prevY = currY;
            } else {
              entries[entries.length - 1].add(
                  FlSpot(j - xOffsets['MIC']!, audioValue + yOffsets['MIC']!));
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

      if (!isFourierTransformSelected) {
        for (int i = 0; i < min(entries.length, paramsChannels.length); i++) {
          String channel = paramsChannels[i];
          double minY;
          double maxY;
          double yRange;
          List<double> voltage = List.filled(512, 0.0);
          List<FlSpot> entriesList = entries[i];

          if (entriesList.isEmpty) {
            minY = 0;
            maxY = 0;
          } else {
            minY = double.maxFinite;
            maxY = -1 * double.maxFinite;

            for (int j = 0; j < entriesList.length; j++) {
              FlSpot entry = entriesList[j];
              if (j < voltage.length - 1) {
                voltage[j] = entry.y;
              }
              if (entry.y > maxY) {
                maxY = entry.y;
              }
              if (entry.y < minY) {
                minY = entry.y;
              }
            }
          }
          final double frequency;
          if (paramsChannels[i] == 'MIC') {
            frequency = _analyticsClass.findFrequency(
                voltage, (1 / AudioJack.samplingRate).toDouble());
          } else {
            frequency =
                _analyticsClass.findFrequency(voltage, timeGap / 1000000.0);
          }
          double period = (1 / frequency) * 1000.0;
          yRange = maxY - minY;
          OscilloscopeMeasurements
              .channel[channel]![ChannelMeasurements.frequency] = frequency;
          OscilloscopeMeasurements
              .channel[channel]![ChannelMeasurements.period] = period;
          OscilloscopeMeasurements
              .channel[channel]![ChannelMeasurements.amplitude] = yRange;
          OscilloscopeMeasurements
              .channel[channel]![ChannelMeasurements.positivePeak] = maxY;
          OscilloscopeMeasurements
              .channel[channel]![ChannelMeasurements.negativePeak] = minY;
        }
      }

      dataEntries = List.from(entries);
      dataEntriesCurveFit = List.from(curveFitEntries);
      dataParamsChannels = List.from(paramsChannels);
      if (isFourierTransformSelected) {
        oscilloscopeAxesScale.setYAxisScaleMax(_maxAmp);
        oscilloscopeAxesScale.setYAxisScaleMin(0);
        oscilloscopeAxesScale.setXAxisScale(_maxFreq * 1000);
      }
      notifyListeners();
    } catch (e) {
      logger.e(e);
    }
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
    oscilloscopeAxesScale.setXAxisScale(timebase);
    notifyListeners();
  }

  void setYAxisScale(double value) {
    oscilloscopeAxesScale.setYAxisScale(value);
    notifyListeners();
  }

  bool autoScale() {
    double minY = double.maxFinite;
    double maxY = double.minPositive;
    double maxPeriod = -1 * double.minPositive;
    double yRange;
    double yPadding;
    List<double> voltage = List.filled(512, 0.0);
    for (int i = 0; i < dataParamsChannels.length; i++) {
      if (dataEntries.length > i) {
        List<FlSpot> entryList = dataEntries[i];
        for (int j = 0; j < entryList.length; j++) {
          FlSpot entry = entryList[j];
          if (j < voltage.length - 1) {
            voltage[j] = entry.y;
          }
          if (entry.y > maxY) {
            maxY = entry.y;
          }
          if (entry.y < minY) {
            minY = entry.y;
          }
        }
        final double frequency;
        if (dataParamsChannels[i] == 'MIC') {
          frequency = _analyticsClass.findSignalFrequency(
              voltage, (1 / AudioJack.samplingRate).toDouble());
        } else {
          frequency =
              _analyticsClass.findSignalFrequency(voltage, timeGap / 1000000.0);
        }
        double period = (1 / frequency) * 1000.0;
        if (period > maxPeriod) {
          maxPeriod = period;
        }
      }
    }
    yRange = maxY - minY;
    yPadding = yRange * 0.1;
    if (maxPeriod > 0) {
      double xAxisScale = min((maxPeriod * 5), maxTimebase);
      double yAxisScale;
      if (maxY.abs() > minY.abs()) {
        yAxisScale = maxY + yPadding;
      } else {
        yAxisScale = -1 * (minY - yPadding);
      }
      samples = 512;
      timeGap = (2 * xAxisScale * 1000.0) / samples;
      timebase = xAxisScale * 1000.0;
      oscilloscopeAxesScale.setXAxisScale(timebase);
      oscilloscopeAxesScale.setYAxisScale(yAxisScale);
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  List<LineChartBarData> createPlots() {
    List<Color> curveFitColors = [Colors.yellow];
    List<LineChartBarData> plots = [];
    plots.addAll(
      List<LineChartBarData>.generate(
        dataEntries.length,
        (index) {
          return LineChartBarData(
            spots: dataEntries[index],
            isCurved: true,
            color: colors[index % colors.length],
            barWidth: 1,
            dotData: const FlDotData(
              show: false,
            ),
          );
        },
      ),
    );
    plots.addAll(
      List<LineChartBarData>.generate(
        dataEntriesCurveFit.length,
        (index) {
          return LineChartBarData(
            spots: dataEntriesCurveFit[index],
            isCurved: true,
            color: curveFitColors[index % colors.length],
            barWidth: 1,
            dotData: const FlDotData(
              show: false,
            ),
          );
        },
      ),
    );
    return plots;
  }

  List<LineChartBarData> createXYPlot() {
    List<Color> colors = [Colors.red];
    return List<LineChartBarData>.generate(
      dataEntriesXYPlot.length,
      (index) {
        return LineChartBarData(
          spots: dataEntriesXYPlot[index],
          isCurved: true,
          color: colors[index % colors.length],
          barWidth: 1,
          dotData: const FlDotData(
            show: false,
          ),
        );
      },
    );
  }

  void resetGraph() {
    oscilloscopeAxesScale.setYAxisScaleMax(oscilloscopeAxesScale.yAxisScale);
    oscilloscopeAxesScale.setYAxisScaleMin(-oscilloscopeAxesScale.yAxisScale);
    oscilloscopeAxesScale.setXAxisScale(timebase);
    dataEntries = [];
    dataEntriesXYPlot = [];
    dataEntriesCurveFit = [];
  }

  @override
  void dispose() {
    _monitor = false;
    if (_timer.isActive) {
      _timer.cancel();
    }
    _audioJack.close();
    super.dispose();
  }
}
