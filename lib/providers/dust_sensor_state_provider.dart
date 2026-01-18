import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DustSensorStateProvider extends ChangeNotifier {
  /// Current dust value in PPM.
  /// null means "not available" (device not connected / not started).
  double? _ppm;
  double? get ppm => _ppm;

  final List<FlSpot> _spots = [];
  List<FlSpot> get spots => List.unmodifiable(_spots);

  Timer? _timer;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Call this from UI (or from a connection listener later).
  void setConnectionStatus(bool connected) {
    _isConnected = connected;

    if (!connected) {
      stop();
      _ppm = null;
      _spots.clear();
    }

    notifyListeners();
  }

  /// Starts polling/streaming dust values.
  /// In this PR we only enable the UI + route; hardware streaming will be added later.
  void start() {
    if (_isStreaming || !_isConnected) return;
    _isStreaming = true;

    // TODO: Replace timer body with real sensor reading.
    // Example future flow:
    // 1) Read dust sensor value from PSLab
    // 2) _ppm = newValue
    // 3) _spots.add(FlSpot(_time, _ppm!))
    // 4) _time += 1
    // 5) notifyListeners()

    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      // No mock values in perfect PR.
      // Keep running idle until real data integration is added.
      notifyListeners();
    });

    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isStreaming = false;
    notifyListeners();
  }

  void clearGraph() {
    _spots.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
