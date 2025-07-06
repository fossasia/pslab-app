import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LogicAnalyzerStateProvider extends ChangeNotifier {
  late List<List<FlSpot>> dataSets;
  LogicAnalyzerStateProvider() {
    dataSets = [];
  }
}
