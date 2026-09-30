import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/locator.dart';

abstract class DustSensorSource {
  bool get isConnected;

  Future<double> readVoltage();
}

enum DustSensorError { notConnected, readFailed }

class ScienceLabDustSensorSource implements DustSensorSource {
  final ScienceLab scienceLab;

  ScienceLabDustSensorSource(this.scienceLab);

  @override
  bool get isConnected => scienceLab.isConnected();

  @override
  Future<double> readVoltage() => scienceLab.getVoltage('CH1', 1);
}

class DustSensorReading {
  static const double referenceVoltage = 5.0;

  final double voltage;
  final double relativeLevel;

  const DustSensorReading({required this.voltage, required this.relativeLevel});

  factory DustSensorReading.fromVoltage(double voltage) {
    final safeVoltage =
        voltage.isFinite ? voltage.clamp(0.0, 16.0).toDouble() : 0.0;
    return DustSensorReading(
      voltage: safeVoltage,
      relativeLevel: (safeVoltage / referenceVoltage * 100).clamp(0.0, 100.0),
    );
  }
}

class DustSensorStateProvider extends ChangeNotifier {
  final DustSensorSource _source;
  final Duration updatePeriod;

  Timer? _readTimer;
  bool _isReading = false;
  bool _isBusy = false;
  DustSensorError? _error;
  DustSensorReading _currentReading = const DustSensorReading(
    voltage: 0,
    relativeLevel: 0,
  );

  final List<double> _voltages = [];
  final List<double> _times = [];
  final List<FlSpot> _chartData = [];
  final int _maxSamples;
  double _startedAt = 0;

  DustSensorStateProvider({
    DustSensorSource? source,
    this.updatePeriod = const Duration(seconds: 1),
    int maxSamples = 80,
  })  : _source = source ?? ScienceLabDustSensorSource(getIt.get<ScienceLab>()),
        _maxSamples = maxSamples;

  bool get isConnected => _source.isConnected;
  bool get isReading => _isReading;
  DustSensorError? get error => _error;
  DustSensorReading get currentReading => _currentReading;

  List<FlSpot> get chartData =>
      _chartData.isEmpty ? const [FlSpot(0, 0)] : List.unmodifiable(_chartData);

  double get minVoltage => _voltages.isEmpty ? 0 : _voltages.reduce(min);
  double get maxVoltage => _voltages.isEmpty ? 0 : _voltages.reduce(max);
  double get averageVoltage => _voltages.isEmpty
      ? 0
      : _voltages.reduce((value, element) => value + element) /
          _voltages.length;
  double get minTime => _times.isEmpty ? 0 : _times.first;
  double get maxTime => _times.isEmpty ? 0 : _times.last;

  double get timeInterval {
    if (maxTime <= 10) return 2;
    if (maxTime <= 30) return 5;
    if (maxTime <= 80) return 10;
    return 20;
  }

  Future<void> initialize() async {
    if (!isConnected) {
      _error = DustSensorError.notConnected;
      notifyListeners();
      return;
    }
    await start();
  }

  Future<void> start() async {
    if (_isReading) return;
    if (!isConnected) {
      _error = DustSensorError.notConnected;
      notifyListeners();
      return;
    }

    _error = null;
    _isReading = true;
    _startedAt = DateTime.now().millisecondsSinceEpoch / 1000;
    notifyListeners();
    await sampleOnce();
    _readTimer = Timer.periodic(updatePeriod, (_) => sampleOnce());
  }

  void stop() {
    _readTimer?.cancel();
    _readTimer = null;
    _isReading = false;
    notifyListeners();
  }

  void reset() {
    _voltages.clear();
    _times.clear();
    _chartData.clear();
    _currentReading = const DustSensorReading(voltage: 0, relativeLevel: 0);
    _startedAt = DateTime.now().millisecondsSinceEpoch / 1000;
    notifyListeners();
  }

  @visibleForTesting
  Future<void> sampleOnce() async {
    if (_isBusy || !isConnected) return;
    _isBusy = true;
    try {
      final voltage = await _source.readVoltage();
      final reading = DustSensorReading.fromVoltage(voltage);
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      final elapsed = max(0.0, now - _startedAt).toDouble();

      _currentReading = reading;
      _voltages.add(reading.voltage);
      _times.add(elapsed);
      if (_voltages.length > _maxSamples) {
        _voltages.removeAt(0);
        _times.removeAt(0);
      }
      _chartData
        ..clear()
        ..addAll(
          List.generate(
            _voltages.length,
            (index) => FlSpot(_times[index], _voltages[index]),
          ),
        );
      _error = null;
      notifyListeners();
    } catch (error) {
      logger.e('Dust sensor read error: $error');
      _error = DustSensorError.readFailed;
      stop();
    } finally {
      _isBusy = false;
    }
  }

  @override
  void dispose() {
    _readTimer?.cancel();
    super.dispose();
  }
}
