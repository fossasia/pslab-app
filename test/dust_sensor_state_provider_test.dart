import 'package:flutter_test/flutter_test.dart';
import 'package:pslab/providers/dust_sensor_state_provider.dart';

class _FakeDustSensorSource implements DustSensorSource {
  _FakeDustSensorSource(this.values, {this.connected = true});

  final List<double> values;
  final bool connected;
  int _index = 0;

  @override
  bool get isConnected => connected;

  @override
  Future<double> readVoltage() async => values[_index++];
}

void main() {
  group('DustSensorReading', () {
    test(
      'reports voltage as a relative signal without claiming concentration',
      () {
        final reading = DustSensorReading.fromVoltage(2.5);

        expect(reading.voltage, 2.5);
        expect(reading.relativeLevel, 50);
      },
    );

    test('clamps invalid and out-of-range values safely', () {
      expect(DustSensorReading.fromVoltage(double.nan).voltage, 0);
      expect(DustSensorReading.fromVoltage(-2).voltage, 0);
      expect(DustSensorReading.fromVoltage(20).voltage, 16);
      expect(DustSensorReading.fromVoltage(20).relativeLevel, 100);
    });
  });

  test('provider samples CH1 data and calculates summary values', () async {
    final provider = DustSensorStateProvider(
      source: _FakeDustSensorSource([1, 2, 3]),
      maxSamples: 2,
    );

    await provider.sampleOnce();
    await provider.sampleOnce();
    await provider.sampleOnce();

    expect(provider.currentReading.voltage, 3);
    expect(provider.chartData.map((spot) => spot.y), [2, 3]);
    expect(provider.minVoltage, 2);
    expect(provider.maxVoltage, 3);
    expect(provider.averageVoltage, 2.5);
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
}
