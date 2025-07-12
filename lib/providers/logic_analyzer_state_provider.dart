import 'dart:collection';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pslab/communication/digitalChannel/digital_channel.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/theme/colors.dart';

class LogicAnalyzerStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  static const singleChannelAxisMin = -0.1;
  static const singleChannelAxisMax = 1.1;
  static const double twoChannelAxisMin = -0.3;
  static const double twoChannelAxisMax = 3.3;
  static const double threeChannelAxisMin = -0.5;
  static const double threeChannelAxisMax = 5.5;
  static const double fourChannelAxisMin = -0.7;
  static const double fourChannelAxisMax = 7.7;
  static const int everyEdge = 1;
  static const int disabled = 0;
  static const int everyFourthRisingEdge = 4;
  static const int everyRisingEdge = 3;
  static const int everyFallingEdge = 2;

  late int channelMode;
  late int currentChannel;
  late List<String> channels;
  late List<String> analysisChannelNames;
  late List<String> analysisEdgesNames;
  late Map<String, int> channelMap;
  late List<FlSpot> tempInput;
  late DigitalChannel digitalChannel;
  late List<DigitalChannel> digitalChannels;
  late List<List<FlSpot>> dataSets;

  late String channelSelectSpinner1;
  late String channelSelectSpinner2;
  late String channelSelectSpinner3;
  late String channelSelectSpinner4;
  late String edgeSelectSpinner1;
  late String edgeSelectSpinner2;
  late String edgeSelectSpinner3;
  late String edgeSelectSpinner4;

  late double maxY;
  late double minY;

  late ScienceLab _scienceLab;
  late bool isProcessing;
  late bool isData;

  late List<String> channelNames;
  LogicAnalyzerStateProvider() {
    channelNames = [
      appLocalizations.channelLA1,
      appLocalizations.channelLA2,
      appLocalizations.channelLA3,
      appLocalizations.channelLA4,
    ];
    channelMode = 1;
    channels = channelNames;
    channelMap = {};
    channelMap[channelNames[0]] = 0;
    channelMap[channelNames[1]] = 1;
    channelMap[channelNames[2]] = 2;
    channelMap[channelNames[3]] = 3;
    analysisChannelNames = [];
    analysisEdgesNames = [];
    tempInput = [];
    digitalChannels = [];
    dataSets = [];

    channelSelectSpinner1 = channelNames[0];
    channelSelectSpinner2 = channelNames[1];
    channelSelectSpinner3 = channelNames[2];
    channelSelectSpinner4 = channelNames[3];
    edgeSelectSpinner1 = appLocalizations.analysisOptionEveryEdge;
    edgeSelectSpinner2 = appLocalizations.analysisOptionEveryEdge;
    edgeSelectSpinner3 = appLocalizations.analysisOptionEveryEdge;
    edgeSelectSpinner4 = appLocalizations.analysisOptionEveryEdge;

    maxY = singleChannelAxisMax;
    minY = singleChannelAxisMin;

    _scienceLab = getIt<ScienceLab>();
    isProcessing = false;
    isData = false;
  }

  Future<void> analyze() async {
    isProcessing = true;
    notifyListeners();

    currentChannel = 0;
    dataSets.clear();
    analysisChannelNames.clear();
    analysisEdgesNames.clear();
    digitalChannels.clear();

    switch (channelMode) {
      case 1:
        analysisChannelNames.add(channelSelectSpinner1);
        analysisEdgesNames.add(edgeSelectSpinner1);
        break;
      case 2:
        analysisChannelNames
            .addAll([channelSelectSpinner1, channelSelectSpinner2]);
        analysisEdgesNames.addAll([edgeSelectSpinner1, edgeSelectSpinner2]);
        break;
      case 3:
        analysisChannelNames.addAll([
          channelSelectSpinner1,
          channelSelectSpinner2,
          channelSelectSpinner3
        ]);
        analysisEdgesNames.addAll(
            [edgeSelectSpinner1, edgeSelectSpinner2, edgeSelectSpinner3]);
        break;
      case 4:
        analysisChannelNames.addAll([
          channelSelectSpinner1,
          channelSelectSpinner2,
          channelSelectSpinner3,
          channelSelectSpinner4
        ]);
        analysisEdgesNames.addAll([
          edgeSelectSpinner1,
          edgeSelectSpinner2,
          edgeSelectSpinner3,
          edgeSelectSpinner4
        ]);
        break;
      default:
        analysisChannelNames.add(channelSelectSpinner1);
        analysisEdgesNames.add(edgeSelectSpinner1);
        break;
    }

    if (_scienceLab.isConnected()) {
      switch (channelMode) {
        case 1:
          await captureOne(analysisChannelNames[0], analysisEdgesNames[0]);
          maxY = singleChannelAxisMax;
          minY = singleChannelAxisMin;
          break;
        case 2:
          await captureTwo(analysisChannelNames, analysisEdgesNames);
          maxY = twoChannelAxisMax;
          minY = twoChannelAxisMin;
          break;
        case 3:
          await captureThree(analysisChannelNames, analysisEdgesNames);
          maxY = threeChannelAxisMax;
          minY = threeChannelAxisMin;
          break;
        case 4:
          await captureFour(analysisChannelNames, analysisEdgesNames);
          maxY = fourChannelAxisMax;
          minY = fourChannelAxisMin;
          break;
        default:
          break;
      }
      isData = true;
    }
    isProcessing = false;
    notifyListeners();
  }

  double getMaxY() {
    return maxY;
  }

  double getMinY() {
    return minY;
  }

  void setDataSet() {
    dataSets.add(tempInput);
  }

  void singleChannelEveryEdge(List<double> xData, List<double> yData) {
    tempInput = [];
    List<double> temp = List.filled(xData.length, 0);
    List<double> yAxis = List.filled(yData.length, 0);

    for (int i = 0; i < xData.length; i++) {
      temp[i] = xData[i];
      yAxis[i] = yData[i];
    }

    List<double> xaxis = [];
    List<double> yaxis = [];
    xaxis.add(temp[0]);
    yaxis.add(yAxis[0]);

    for (int i = 1; i < xData.length; i++) {
      if (temp[i] != temp[i - 1]) {
        xaxis.add(temp[i]);
        yaxis.add(yAxis[i]);
      }
    }

    if (yaxis.length > 1) {
      if (yaxis[1] == yaxis[0]) {
        tempInput.add(FlSpot(xaxis[0], (yaxis[0] + 2 * currentChannel)));
      } else {
        tempInput.add(FlSpot(xaxis[0], (yaxis[0] + 2 * currentChannel)));
        tempInput.add(FlSpot(xaxis[0], (yaxis[1] + 2 * currentChannel)));
      }
      for (int i = 1; i < xaxis.length - 1; i++) {
        if (yaxis[i] == yaxis[i + 1]) {
          tempInput.add(FlSpot(xaxis[i], (yaxis[i] + 2 * currentChannel)));
        } else {
          tempInput.add(FlSpot(xaxis[i], (yaxis[i] + 2 * currentChannel)));
          tempInput.add(FlSpot(xaxis[i], (yaxis[i + 1] + 2 * currentChannel)));
        }
      }
      tempInput.add(FlSpot(xaxis[xaxis.length - 1],
          (yaxis[xaxis.length - 1] + 2 * currentChannel)));
    } else {
      tempInput.add(FlSpot(xaxis[0], (yaxis[0] + 2 * currentChannel)));
    }

    setDataSet();
  }

  void singleChannelFourthRisingEdge(List<double> xData) {
    tempInput = [];
    double xaxis = xData[0];
    tempInput
        .add(FlSpot(xaxis.toDouble(), (0 + 2 * currentChannel).toDouble()));
    tempInput
        .add(FlSpot(xaxis.toDouble(), (1 + 2 * currentChannel).toDouble()));
    tempInput
        .add(FlSpot(xaxis.toDouble(), (0 + 2 * currentChannel).toDouble()));
    double check = xaxis;
    int count = 0;

    if (xData.length > 1) {
      for (int i = 1; i < xData.length; i++) {
        xaxis = xData[i];
        if (xaxis != check) {
          if (count == 3) {
            tempInput.add(
                FlSpot(xaxis.toDouble(), (0 + 2 * currentChannel).toDouble()));
            tempInput.add(
                FlSpot(xaxis.toDouble(), (1 + 2 * currentChannel).toDouble()));
            tempInput.add(
                FlSpot(xaxis.toDouble(), (0 + 2 * currentChannel).toDouble()));
            count = 0;
          } else {
            count++;
          }
          check = xaxis;
        }
      }
    }

    setDataSet();
  }

  void singleChannelRisingEdges(List<double> xData, List<double> yData) {
    tempInput = [];

    for (int i = 1; i < xData.length; i += 6) {
      tempInput.add(FlSpot(
          xData[i].toDouble(), (yData[i] + 2 * currentChannel).toDouble()));
      tempInput.add(FlSpot(xData[i + 1].toDouble(),
          (yData[i + 1] + 2 * currentChannel).toDouble()));
      tempInput.add(FlSpot(xData[i + 2].toDouble(),
          (yData[i + 2] + 2 * currentChannel).toDouble()));
    }

    setDataSet();
  }

  void singleChannelFallingEdges(List<double> xData, List<double> yData) {
    tempInput = [];

    for (int i = 4; i < xData.length; i += 6) {
      tempInput.add(FlSpot(
          xData[i].toDouble(), (yData[i] + 2 * currentChannel).toDouble()));
      tempInput.add(FlSpot(xData[i + 1].toDouble(),
          (yData[i + 1] + 2 * currentChannel).toDouble()));
      tempInput.add(FlSpot(xData[i + 2].toDouble(),
          (yData[i + 2] + 2 * currentChannel).toDouble()));
    }

    setDataSet();
  }

  void singleChannelOtherEdges(List<double> xData, List<double> yData) {
    tempInput = [];

    for (int i = 0; i < xData.length; i++) {
      double xaxis = xData[i];
      double yaxis = yData[i];
      tempInput.add(
          FlSpot(xaxis.toDouble(), (yaxis + 2 * currentChannel).toDouble()));
    }

    setDataSet();
  }

  Future<void> captureOne(String channelName, String edgeName) async {
    String edgeOption = "";
    bool holder;

    try {
      channels[0] = channelName;

      int? channelNumber = _scienceLab.calculateDigitalChannel(channelName);
      digitalChannel = _scienceLab.getDigitalChannel(channelNumber!);
      edgeOption = edgeName;

      switch (edgeOption) {
        case "EVERY EDGE":
          digitalChannel.mode = everyEdge;
          break;
        case "EVERY FALLING EDGE":
          digitalChannel.mode = everyFallingEdge;
          break;
        case "EVERY RISING EDGE":
          digitalChannel.mode = everyRisingEdge;
          break;
        case "EVERY FOURTH RISING EDGE":
          digitalChannel.mode = everyFourthRisingEdge;
          break;
        case "DISABLED":
          digitalChannel.mode = disabled;
          break;
        default:
          digitalChannel.mode = everyEdge;
          break;
      }

      await _scienceLab.startTwoChannelLA(null, null, 67, null, null, null);
      await Future.delayed(const Duration(seconds: 1));
      LinkedHashMap<String, int>? data = await _scienceLab.getLAInitialStates();
      await Future.delayed(const Duration(seconds: 1));
      holder = await _scienceLab.fetchLAChannel(channelNumber, data!, 1);
    } catch (e) {
      logger.e("Error in captureOne: $e");
      holder = false;
    }

    if (holder) {
      List<double> xAxis = digitalChannel.getXAxis();
      List<double> yAxis = digitalChannel.getYAxis();

      String string1 = "";
      String string2 = "";
      for (int i = 0; i < xAxis.length; i++) {
        string1 += "${xAxis[i].toStringAsFixed(2)},";
        string2 += "${yAxis[i].toStringAsFixed(2)},";
      }
      logger.t("X-Axis: $string1");
      logger.t("Y-Axis: $string2");

      switch (edgeOption) {
        case "EVERY EDGE":
          singleChannelEveryEdge(xAxis, yAxis);
          break;
        case "EVERY FALLING EDGE":
          singleChannelFourthRisingEdge(xAxis);
          break;
        case "EVERY RISING EDGE":
          singleChannelRisingEdges(xAxis, yAxis);
          break;
        case "EVERY FOURTH RISING EDGE":
          singleChannelFallingEdges(xAxis, yAxis);
          break;
        default:
          singleChannelOtherEdges(xAxis, yAxis);
          break;
      }
    }
  }

  Future<void> captureTwo(
      List<String> channelNames, List<String> edgeNames) async {
    List<String> edgeOption = List.filled(channelMode, "");
    bool holder1, holder2;

    try {
      channels[0] = channelNames[0];
      channels[1] = channelNames[1];

      int channelNumber1 =
          _scienceLab.calculateDigitalChannel(channelNames[0])!;
      int channelNumber2 =
          _scienceLab.calculateDigitalChannel(channelNames[1])!;

      digitalChannels.add(_scienceLab.getDigitalChannel(channelNumber1));
      digitalChannels.add(_scienceLab.getDigitalChannel(channelNumber2));
      edgeOption[0] = edgeNames[0];
      edgeOption[1] = edgeNames[1];

      List<int> modes = [];
      for (int i = 0; i < channelMode; i++) {
        switch (edgeOption[i]) {
          case "EVERY EDGE":
            digitalChannels[i].mode = everyEdge;
            modes.add(everyEdge);
            break;
          case "EVERY FALLING EDGE":
            digitalChannels[i].mode = everyFallingEdge;
            modes.add(everyFallingEdge);
            break;
          case "EVERY RISING EDGE":
            digitalChannels[i].mode = everyRisingEdge;
            modes.add(everyRisingEdge);
            break;
          case "EVERY FOURTH RISING EDGE":
            digitalChannels[i].mode = everyFourthRisingEdge;
            modes.add(everyFourthRisingEdge);
            break;
          case "DISABLED":
            digitalChannels[i].mode = disabled;
            modes.add(disabled);
            break;
          default:
            digitalChannels[i].mode = everyEdge;
            modes.add(everyEdge);
            break;
        }
      }

      await _scienceLab.startTwoChannelLA(
          channelNames, modes, 67, null, null, null);
      await Future.delayed(const Duration(seconds: 1));
      LinkedHashMap<String, int>? data = await _scienceLab.getLAInitialStates();
      await Future.delayed(const Duration(seconds: 1));
      holder1 = await _scienceLab.fetchLAChannel(channelNumber1, data!, 2);
      await Future.delayed(const Duration(seconds: 1));
      holder2 = await _scienceLab.fetchLAChannel(channelNumber2, data, 2);
    } catch (e) {
      logger.e("Error in captureTwo: $e");
      holder1 = false;
      holder2 = false;
    }

    if (holder1 && holder2) {
      List<List<double>> xaxis = [];
      xaxis.add(digitalChannels[0].getXAxis());
      xaxis.add(digitalChannels[1].getXAxis());

      List<List<double>> yaxis = [];
      yaxis.add(digitalChannels[0].getYAxis());
      yaxis.add(digitalChannels[1].getYAxis());

      for (int i = 0; i < channelMode; i++) {
        switch (edgeOption[i]) {
          case "EVERY EDGE":
            singleChannelEveryEdge(xaxis[i], yaxis[i]);
            break;
          case "EVERY FALLING EDGE":
            singleChannelFourthRisingEdge(xaxis[i]);
            break;
          case "EVERY RISING EDGE":
            singleChannelRisingEdges(xaxis[i], yaxis[i]);
            break;
          case "EVERY FOURTH RISING EDGE":
            singleChannelFallingEdges(xaxis[i], yaxis[i]);
            break;
          default:
            singleChannelOtherEdges(xaxis[i], yaxis[i]);
            break;
        }
        currentChannel++;
      }
    }
  }

  Future<void> captureThree(
      List<String> channelNames, List<String> edgeNames) async {
    List<String> edgeOption = List.filled(channelMode, "");
    bool holder1, holder2, holder3;

    try {
      channels[0] = channelNames[0];
      channels[1] = channelNames[1];
      channels[2] = channelNames[2];

      int channelNumber1 =
          _scienceLab.calculateDigitalChannel(channelNames[0])!;
      int channelNumber2 =
          _scienceLab.calculateDigitalChannel(channelNames[1])!;
      int channelNumber3 =
          _scienceLab.calculateDigitalChannel(channelNames[2])!;

      digitalChannels.add(_scienceLab.getDigitalChannel(channelNumber1));
      digitalChannels.add(_scienceLab.getDigitalChannel(channelNumber2));
      digitalChannels.add(_scienceLab.getDigitalChannel(channelNumber3));
      edgeOption[0] = edgeNames[0];
      edgeOption[1] = edgeNames[1];
      edgeOption[2] = edgeNames[2];

      List<int> modes = [];
      for (int i = 0; i < channelMode; i++) {
        switch (edgeOption[i]) {
          case "EVERY EDGE":
            digitalChannels[i].mode = everyEdge;
            modes.add(everyEdge);
            break;
          case "EVERY FALLING EDGE":
            digitalChannels[i].mode = everyFallingEdge;
            modes.add(everyFallingEdge);
            break;
          case "EVERY RISING EDGE":
            digitalChannels[i].mode = everyRisingEdge;
            modes.add(everyRisingEdge);
            break;
          case "EVERY FOURTH RISING EDGE":
            digitalChannels[i].mode = everyFourthRisingEdge;
            modes.add(everyFourthRisingEdge);
            break;
          case "DISABLED":
            digitalChannels[i].mode = disabled;
            modes.add(disabled);
            break;
          default:
            digitalChannels[i].mode = everyEdge;
            modes.add(everyEdge);
            break;
        }
      }
      modes.add(everyEdge);
      List<bool> triggerChannel = [];
      triggerChannel.add(true);
      triggerChannel.add(true);
      triggerChannel.add(true);
      await _scienceLab.startFourChannelLA(
          null, null, modes, null, triggerChannel);
      await Future.delayed(const Duration(seconds: 1));
      LinkedHashMap<String, int>? data = await _scienceLab.getLAInitialStates();
      await Future.delayed(const Duration(seconds: 1));
      holder1 = await _scienceLab.fetchLAChannel(channelNumber1, data!, 3);
      await Future.delayed(const Duration(seconds: 1));
      holder2 = await _scienceLab.fetchLAChannel(channelNumber2, data, 3);
      await Future.delayed(const Duration(seconds: 1));
      holder3 = await _scienceLab.fetchLAChannel(channelNumber3, data, 3);
    } catch (e) {
      holder1 = false;
      holder2 = false;
      holder3 = false;
      logger.e("Error in captureThree: $e");
    }

    if (holder1 && holder2 && holder3) {
      List<List<double>> xaxis = [];
      xaxis.add(digitalChannels[0].getXAxis());
      xaxis.add(digitalChannels[1].getXAxis());
      xaxis.add(digitalChannels[2].getXAxis());

      List<List<double>> yaxis = [];
      yaxis.add(digitalChannels[0].getYAxis());
      yaxis.add(digitalChannels[1].getYAxis());
      yaxis.add(digitalChannels[2].getYAxis());

      for (int i = 0; i < channelMode; i++) {
        switch (edgeOption[i]) {
          case "EVERY EDGE":
            singleChannelEveryEdge(xaxis[i], yaxis[i]);
            break;
          case "EVERY FALLING EDGE":
            singleChannelFourthRisingEdge(xaxis[i]);
            break;
          case "EVERY RISING EDGE":
            singleChannelRisingEdges(xaxis[i], yaxis[i]);
            break;
          case "EVERY FOURTH RISING EDGE":
            singleChannelFallingEdges(xaxis[i], yaxis[i]);
            break;
          default:
            singleChannelOtherEdges(xaxis[i], yaxis[i]);
            break;
        }
        currentChannel++;
      }
    }
  }

  Future<void> captureFour(
      List<String> channelNames, List<String> edgeNames) async {
    List<String> edgeOption = List.filled(channelMode, "");
    bool holder1, holder2, holder3, holder4;

    try {
      channels[0] = channelNames[0];
      channels[1] = channelNames[1];
      channels[2] = channelNames[2];
      channels[3] = channelNames[3];

      int channelNumber1 =
          _scienceLab.calculateDigitalChannel(channelNames[0])!;
      int channelNumber2 =
          _scienceLab.calculateDigitalChannel(channelNames[1])!;
      int channelNumber3 =
          _scienceLab.calculateDigitalChannel(channelNames[2])!;
      int channelNumber4 =
          _scienceLab.calculateDigitalChannel(channelNames[3])!;

      digitalChannels.add(_scienceLab.getDigitalChannel(channelNumber1));
      digitalChannels.add(_scienceLab.getDigitalChannel(channelNumber2));
      digitalChannels.add(_scienceLab.getDigitalChannel(channelNumber3));
      digitalChannels.add(_scienceLab.getDigitalChannel(channelNumber4));
      edgeOption[0] = edgeNames[0];
      edgeOption[1] = edgeNames[1];
      edgeOption[2] = edgeNames[2];
      edgeOption[3] = edgeNames[3];

      List<int> modes = [];
      for (int i = 0; i < channelMode; i++) {
        switch (edgeOption[i]) {
          case "EVERY EDGE":
            digitalChannels[i].mode = everyEdge;
            modes.add(everyEdge);
            break;
          case "EVERY FALLING EDGE":
            digitalChannels[i].mode = everyFallingEdge;
            modes.add(everyFallingEdge);
            break;
          case "EVERY RISING EDGE":
            digitalChannels[i].mode = everyRisingEdge;
            modes.add(everyRisingEdge);
            break;
          case "EVERY FOURTH RISING EDGE":
            digitalChannels[i].mode = everyFourthRisingEdge;
            modes.add(everyFourthRisingEdge);
            break;
          case "DISABLED":
            digitalChannels[i].mode = disabled;
            modes.add(disabled);
            break;
          default:
            digitalChannels[i].mode = everyEdge;
            modes.add(everyEdge);
            break;
        }
      }
      List<bool> triggerChannel = [];
      triggerChannel.add(true);
      triggerChannel.add(true);
      triggerChannel.add(true);

      await _scienceLab.startFourChannelLA(
          null, null, modes, null, triggerChannel);
      await Future.delayed(const Duration(seconds: 1));
      LinkedHashMap<String, int>? data = await _scienceLab.getLAInitialStates();
      await Future.delayed(const Duration(seconds: 1));
      holder1 = await _scienceLab.fetchLAChannel(channelNumber1, data!, 4);
      await Future.delayed(const Duration(seconds: 1));
      holder2 = await _scienceLab.fetchLAChannel(channelNumber2, data, 4);
      await Future.delayed(const Duration(seconds: 1));
      holder3 = await _scienceLab.fetchLAChannel(channelNumber3, data, 4);
      await Future.delayed(const Duration(seconds: 1));
      holder4 = await _scienceLab.fetchLAChannel(channelNumber4, data, 4);
    } catch (e) {
      holder1 = false;
      holder2 = false;
      holder3 = false;
      holder4 = false;
      logger.e("Error in captureFour: $e");
    }

    if (holder1 && holder2 && holder3 && holder4) {
      List<List<double>> xaxis = [];
      xaxis.add(digitalChannels[0].getXAxis());
      xaxis.add(digitalChannels[1].getXAxis());
      xaxis.add(digitalChannels[2].getXAxis());
      xaxis.add(digitalChannels[3].getXAxis());

      List<List<double>> yaxis = [];
      yaxis.add(digitalChannels[0].getYAxis());
      yaxis.add(digitalChannels[1].getYAxis());
      yaxis.add(digitalChannels[2].getYAxis());
      yaxis.add(digitalChannels[3].getYAxis());

      for (int i = 0; i < channelMode; i++) {
        switch (edgeOption[i]) {
          case "EVERY EDGE":
            singleChannelEveryEdge(xaxis[i], yaxis[i]);
            break;
          case "EVERY FALLING EDGE":
            singleChannelFourthRisingEdge(xaxis[i]);
            break;
          case "EVERY RISING EDGE":
            singleChannelRisingEdges(xaxis[i], yaxis[i]);
            break;
          case "EVERY FOURTH RISING EDGE":
            singleChannelFallingEdges(xaxis[i], yaxis[i]);
            break;
          default:
            singleChannelOtherEdges(xaxis[i], yaxis[i]);
            break;
        }
        currentChannel++;
      }
    }
  }

  List<LineChartBarData> createPlots() {
    List<LineChartBarData> plots = [];
    plots.addAll(
      List<LineChartBarData>.generate(
        dataSets.length,
        (index) {
          return LineChartBarData(
            spots: dataSets[index],
            color: logicAnalyzerChannelColors[
                index % logicAnalyzerChannelColors.length],
            barWidth: 2,
            dotData: const FlDotData(
              show: false,
            ),
          );
        },
      ),
    );
    return plots;
  }
}
