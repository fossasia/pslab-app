import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/communication/packet_handler.dart';
import 'package:pslab/communication/peripherals/uart.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/providers/dust_sensor_state_provider.dart';

class _ConnectedCommunicationHandler implements CommunicationHandler {
  @override
  bool connected = true;

  @override
  bool deviceFound = true;

  @override
  void close() => connected = false;

  @override
  Future<void> initialize() async {}

  @override
  bool isConnected() => connected;

  @override
  bool isDeviceFound() => deviceFound;

  @override
  Future<void> open({int overrideBaud = 1000000}) async => connected = true;

  @override
  Future<int> read(
    Uint8List dest,
    int bytesToRead,
    int timeoutMillis,
  ) async =>
      0;

  @override
  void write(Uint8List src, int timeoutMillis) {}
}

class _BlockingReadUart extends Uart2 {
  _BlockingReadUart(super.packetHandler);

  final Completer<void> readGate = Completer<void>();
  final List<int> _frame = [
    0xaa,
    0xc0,
    0x7b,
    0x00,
    0xc8,
    0x01,
    0x12,
    0x34,
    0x8a,
    0xab,
  ];
  final List<List<int>> writes = [];
  int configureCount = 0;

  @override
  Future<void> configure(int baudRate) async => configureCount++;

  @override
  Future<bool> hasData() async => _frame.isNotEmpty;

  @override
  Future<int> readByte() async => _frame.removeAt(0);

  @override
  Future<void> write(List<int> values) {
    writes.add(List<int>.of(values));
    return values[2] == 0x04 ? readGate.future : Future<void>.value();
  }
}

class _FakeDustSensorSource implements DustSensorSource {
  _FakeDustSensorSource(this.values, {this.connected = true});

  final List<DustSensorReading> values;
  bool connected;
  int _index = 0;
  int initializeCount = 0;

  @override
  bool get isConnected => connected;

  @override
  Future<void> initialize() async => initializeCount++;

  @override
  Future<DustSensorReading> read() async => values[_index++];

  @override
  Future<void> close() async {}
}

class _FailingDustSensorSource implements DustSensorSource {
  @override
  bool get isConnected => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<DustSensorReading> read() => Future.error('read failed');

  @override
  Future<void> close() async {}
}

class _DelayedDustSensorSource implements DustSensorSource {
  final Completer<DustSensorReading> completer = Completer();

  @override
  bool get isConnected => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<DustSensorReading> read() => completer.future;

  @override
  Future<void> close() async {}
}

void main() {
  group('Sds011FrameParser', () {
    test('parses a valid SDS011 PM2.5 and PM10 frame', () {
      final parser = Sds011FrameParser();
      const frame = [
        0xaa,
        0xc0,
        0x7b,
        0x00,
        0xc8,
        0x01,
        0x12,
        0x34,
        0x8a,
        0xab
      ];

      DustSensorReading? reading;
      for (final byte in frame) {
        reading = parser.add(byte) ?? reading;
      }

      expect(reading?.pm25, 12.3);
      expect(reading?.pm10, 45.6);
    });

    test('ignores noise and corrupt frames before a valid frame', () {
      final parser = Sds011FrameParser();
      const corrupt = [0x01, 0xaa, 0xc0, 0x7b, 0, 0xc8, 1, 0x12, 0x34, 0, 0xab];
      const valid = [
        0xaa,
        0xc0,
        0x7b,
        0x00,
        0xc8,
        0x01,
        0x12,
        0x34,
        0x8a,
        0xab
      ];

      DustSensorReading? reading;
      for (final byte in [...corrupt, ...valid]) {
        reading = parser.add(byte) ?? reading;
      }

      expect(reading?.pm25, 12.3);
      expect(reading?.pm10, 45.6);
    });
  });

  test('SDS011 initialization waits for an in-flight UART read', () async {
    final handler = _ConnectedCommunicationHandler();
    final uart = _BlockingReadUart(PacketHandler(500, handler));
    final source = Sds011DustSensorSource(
      ScienceLab(handler),
      uart: uart,
      firmwareMajorOverride: 3,
    );
    await source.initialize();
    expect(uart.writes.single.sublist(0, 5), [0xaa, 0xb4, 0x02, 0x01, 0x01]);

    final read = source.read();
    await Future<void>.delayed(Duration.zero);
    final reinitialize = source.initialize();
    await Future<void>.delayed(Duration.zero);

    expect(uart.configureCount, 1);
    uart.readGate.complete();
    expect((await read).pm25, 12.3);
    await reinitialize;
    expect(uart.configureCount, 2);
  });

  test('provider samples PM2.5 data and calculates summary values', () async {
    final provider = DustSensorStateProvider(
      source: _FakeDustSensorSource(const [
        DustSensorReading(pm25: 10, pm10: 20),
        DustSensorReading(pm25: 20, pm10: 30),
        DustSensorReading(pm25: 30, pm10: 40),
      ]),
      maxSamples: 2,
    );

    await provider.sampleOnce();
    await provider.sampleOnce();
    await provider.sampleOnce();

    expect(provider.currentReading.pm25, 30);
    expect(provider.currentReading.pm10, 40);
    expect(provider.chartData.map((spot) => spot.y), [20, 30]);
    expect(provider.minPm25, 20);
    expect(provider.maxPm25, 30);
    expect(provider.averagePm25, 25);
    provider.dispose();
  });

  test('provider explains when PSLab is not connected', () async {
    final provider = DustSensorStateProvider(
      source: _FakeDustSensorSource(const [], connected: false),
    );

    await provider.initialize();

    expect(provider.isReading, isFalse);
    expect(provider.error, DustSensorError.notConnected);
    provider.dispose();
  });

  test('provider stays stopped when the initial read fails', () async {
    final provider = DustSensorStateProvider(
      source: _FailingDustSensorSource(),
      updatePeriod: const Duration(milliseconds: 1),
    );

    await provider.start();

    expect(provider.isReading, isFalse);
    expect(provider.error, DustSensorError.readFailed);
    provider.dispose();
  });

  test('provider stops and reports a connection lost during sampling',
      () async {
    final source = _FakeDustSensorSource(
      const [DustSensorReading(pm25: 10, pm10: 20)],
    );
    final provider = DustSensorStateProvider(
      source: source,
      updatePeriod: const Duration(days: 1),
    );
    await provider.start();
    source.connected = false;

    await provider.sampleOnce();

    expect(provider.isReading, isFalse);
    expect(provider.error, DustSensorError.notConnected);
    provider.dispose();
  });

  test('a stopped in-flight sample cannot restart or publish data', () async {
    final source = _DelayedDustSensorSource();
    final provider = DustSensorStateProvider(
      source: source,
      updatePeriod: const Duration(milliseconds: 1),
    );

    final start = provider.start();
    await Future<void>.delayed(Duration.zero);
    provider.stop();
    source.completer.complete(const DustSensorReading(pm25: 10, pm10: 20));
    await start;
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(provider.isReading, isFalse);
    expect(provider.currentReading.pm25, 0);
    provider.dispose();
  });
}
