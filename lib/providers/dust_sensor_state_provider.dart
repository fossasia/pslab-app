import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:pslab/communication/peripherals/uart.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/providers/locator.dart';

abstract class DustSensorSource {
  bool get isConnected;

  Future<void> initialize();

  Future<DustSensorReading> read();

  Future<void> close();
}

enum DustSensorError { notConnected, readFailed }

class DustSensorReading {
  final double pm25;
  final double pm10;

  const DustSensorReading({required this.pm25, required this.pm10});
}

class Sds011FrameParser {
  final List<int> _buffer = [];

  DustSensorReading? add(int byte) {
    _buffer.add(byte & 0xff);

    while (_buffer.isNotEmpty && _buffer.first != 0xaa) {
      _buffer.removeAt(0);
    }

    while (_buffer.length >= 10) {
      final frame = _buffer.sublist(0, 10);
      if (_isValid(frame)) {
        _buffer.removeRange(0, 10);
        return DustSensorReading(
          pm25: (frame[2] | frame[3] << 8) / 10,
          pm10: (frame[4] | frame[5] << 8) / 10,
        );
      }

      _buffer.removeAt(0);
      while (_buffer.isNotEmpty && _buffer.first != 0xaa) {
        _buffer.removeAt(0);
      }
    }
    return null;
  }

  bool _isValid(List<int> frame) {
    if (frame[0] != 0xaa || frame[1] != 0xc0 || frame[9] != 0xab) {
      return false;
    }
    final checksum =
        frame.sublist(2, 8).fold<int>(0, (sum, byte) => sum + byte);
    return checksum & 0xff == frame[8];
  }
}

class Sds011DustSensorSource implements DustSensorSource {
  static const int baudRate = 9600;
  static const Duration frameTimeout = Duration(milliseconds: 1500);
  static const List<int> _queryCommand = [
    0xaa,
    0xb4,
    0x04,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xff,
    0xff,
    0x02,
    0xab,
  ];

  final ScienceLab scienceLab;
  Uart2? _uart;
  int? _uartFirmwareMajor;
  final Sds011FrameParser _parser = Sds011FrameParser();

  Sds011DustSensorSource(this.scienceLab);

  @override
  bool get isConnected => scienceLab.isConnected();

  @override
  Future<void> initialize() async {
    final firmwareMajor = getIt.get<BoardStateProvider>().pslabFirmwareVersion;
    if (firmwareMajor == 0) {
      throw StateError('Unable to determine the PSLab firmware version');
    }
    if (_uart == null || _uartFirmwareMajor != firmwareMajor) {
      _uart = Uart2(
        scienceLab.mPacketHandler,
        requiresWriteAcknowledgement: firmwareMajor < 3,
      );
      _uartFirmwareMajor = firmwareMajor;
    }
    final uart = _uart!;
    await uart.configure(baudRate);
  }

  @override
  Future<DustSensorReading> read() async {
    final uart = _uart;
    if (uart == null) throw StateError('SDS011 source is not initialized');

    await uart.write(_queryCommand);
    final deadline = DateTime.now().add(frameTimeout);

    while (DateTime.now().isBefore(deadline)) {
      if (!isConnected) {
        throw StateError('PSLab disconnected while reading SDS011');
      }
      if (!await uart.hasData()) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        continue;
      }

      final reading = _parser.add(await uart.readByte());
      if (reading != null) return reading;
    }

    throw TimeoutException('No valid SDS011 data frame received', frameTimeout);
  }

  @override
  Future<void> close() async {}
}

class DustSensorStateProvider extends ChangeNotifier {
  final DustSensorSource _source;
  final Duration updatePeriod;

  Timer? _readTimer;
  bool _isReading = false;
  bool _isBusy = false;
  bool _disposed = false;
  int _session = 0;
  DustSensorError? _error;
  DustSensorReading _currentReading = const DustSensorReading(pm25: 0, pm10: 0);

  final List<double> _pm25Values = [];
  final List<double> _times = [];
  final List<FlSpot> _chartData = [];
  final int _maxSamples;
  double _startedAt = 0;

  DustSensorStateProvider({
    DustSensorSource? source,
    this.updatePeriod = const Duration(seconds: 1),
    int maxSamples = 80,
  })  : _source = source ?? Sds011DustSensorSource(getIt.get<ScienceLab>()),
        _maxSamples = maxSamples;

  bool get isConnected => _source.isConnected;
  bool get isReading => _isReading;
  DustSensorError? get error => _error;
  DustSensorReading get currentReading => _currentReading;

  List<FlSpot> get chartData =>
      _chartData.isEmpty ? const [FlSpot(0, 0)] : List.unmodifiable(_chartData);

  double get minPm25 => _pm25Values.isEmpty ? 0 : _pm25Values.reduce(min);
  double get maxPm25 => _pm25Values.isEmpty ? 0 : _pm25Values.reduce(max);
  double get averagePm25 => _pm25Values.isEmpty
      ? 0
      : _pm25Values.reduce((value, element) => value + element) /
          _pm25Values.length;
  double get minTime => _times.isEmpty ? 0 : _times.first;
  double get maxTime => _times.isEmpty ? 0 : _times.last;
  double get chartMaximum {
    final peak = max(50.0, maxPm25);
    return (peak / 50).ceil() * 50;
  }

  double get timeInterval {
    if (maxTime <= 10) return 2;
    if (maxTime <= 30) return 5;
    if (maxTime <= 80) return 10;
    return 20;
  }

  Future<void> initialize() async {
    if (_disposed) return;
    if (!isConnected) {
      _setError(DustSensorError.notConnected);
      return;
    }
    await start();
  }

  Future<void> start() async {
    if (_disposed || _isReading) return;
    if (!isConnected) {
      _setError(DustSensorError.notConnected);
      return;
    }

    final session = ++_session;
    _error = null;
    _isReading = true;
    final previousTime = _times.isEmpty ? 0.0 : _times.last;
    _startedAt = DateTime.now().millisecondsSinceEpoch / 1000 - previousTime;
    notifyListeners();

    try {
      await _source.initialize();
      if (!_isCurrentSession(session)) return;
      await sampleOnce(session: session);
      if (_isCurrentSession(session)) {
        _readTimer = Timer.periodic(
          updatePeriod,
          (_) => sampleOnce(session: session),
        );
      }
    } catch (error) {
      _handleReadError(error, session);
    }
  }

  void stop() {
    if (_disposed) return;
    _session++;
    _readTimer?.cancel();
    _readTimer = null;
    _isReading = false;
    notifyListeners();
  }

  void reset() {
    if (_disposed) return;
    _pm25Values.clear();
    _times.clear();
    _chartData.clear();
    _currentReading = const DustSensorReading(pm25: 0, pm10: 0);
    _startedAt = DateTime.now().millisecondsSinceEpoch / 1000;
    notifyListeners();
  }

  @visibleForTesting
  Future<void> sampleOnce({int? session}) async {
    if (_disposed ||
        _isBusy ||
        (session != null && !_isCurrentSession(session))) {
      return;
    }
    if (!isConnected) {
      _setError(DustSensorError.notConnected);
      _stopAfterError();
      return;
    }

    _isBusy = true;
    try {
      final reading = await _source.read();
      if (_disposed || (session != null && !_isCurrentSession(session))) return;

      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      final elapsed = max(0.0, now - _startedAt).toDouble();
      _currentReading = reading;
      _pm25Values.add(reading.pm25);
      _times.add(elapsed);
      if (_pm25Values.length > _maxSamples) {
        _pm25Values.removeAt(0);
        _times.removeAt(0);
      }
      _chartData
        ..clear()
        ..addAll(List.generate(
          _pm25Values.length,
          (index) => FlSpot(_times[index], _pm25Values[index]),
        ));
      _error = null;
      notifyListeners();
    } catch (error) {
      _handleReadError(error, session);
    } finally {
      _isBusy = false;
    }
  }

  bool _isCurrentSession(int session) =>
      !_disposed && _isReading && session == _session;

  void _handleReadError(Object error, int? session) {
    if (_disposed || (session != null && session != _session)) return;
    logger.e('SDS011 read error: $error');
    _setError(
      isConnected ? DustSensorError.readFailed : DustSensorError.notConnected,
    );
    _stopAfterError();
  }

  void _setError(DustSensorError error) {
    if (_disposed) return;
    _error = error;
    notifyListeners();
  }

  void _stopAfterError() {
    if (_disposed) return;
    _session++;
    _readTimer?.cancel();
    _readTimer = null;
    _isReading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _session++;
    _isReading = false;
    _readTimer?.cancel();
    unawaited(_source.close());
    super.dispose();
  }
}
