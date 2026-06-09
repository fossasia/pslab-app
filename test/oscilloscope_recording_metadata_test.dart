import 'package:flutter_test/flutter_test.dart';
import 'package:pslab/models/oscilloscope_recording_metadata.dart';

void main() {
  group('OscilloscopeRecordingMetadata', () {
    test('round-trips through toJson/fromJson', () {
      final original = OscilloscopeRecordingMetadata(
        recordedAt: DateTime.parse('2026-06-01T12:30:00.000'),
        enabledChannels: const ['CH1', 'CH2', 'CH3'],
        range: '±16V',
        timebase: 875.0,
        triggerEnabled: true,
        triggerChannel: 'CH1',
        triggerMode: 'MODE.rising',
        triggerLevel: 0.5,
        samplingRate: 500000.0,
        samplesPerFrame: 512,
        sampleCount: 42,
      );

      final restored =
          OscilloscopeRecordingMetadata.fromJson(original.toJson());

      expect(restored.recordedAt, original.recordedAt);
      expect(restored.enabledChannels, ['CH1', 'CH2', 'CH3']);
      expect(restored.range, '±16V');
      expect(restored.timebase, 875.0);
      expect(restored.triggerEnabled, isTrue);
      expect(restored.triggerChannel, 'CH1');
      expect(restored.triggerMode, 'MODE.rising');
      expect(restored.triggerLevel, 0.5);
      expect(restored.samplingRate, 500000.0);
      expect(restored.samplesPerFrame, 512);
      expect(restored.sampleCount, 42);
    });

    test('encode/tryDecode round-trips through a single CSV cell', () {
      const original = OscilloscopeRecordingMetadata(
        enabledChannels: ['CH1'],
        range: '±8V',
        timebase: 1000.0,
        triggerEnabled: false,
        samplingRate: 500000.0,
        samplesPerFrame: 512,
        sampleCount: 10,
      );

      final cell = original.encode();
      // base64 produces a single token with no commas/quotes/newlines.
      expect(cell.contains(','), isFalse);
      expect(cell.contains('"'), isFalse);
      expect(cell.contains('\n'), isFalse);

      final decoded = OscilloscopeRecordingMetadata.tryDecode(cell);
      expect(decoded, isNotNull);
      expect(decoded!.range, '±8V');
      expect(decoded.timebase, 1000.0);
      expect(decoded.enabledChannels, ['CH1']);
      expect(decoded.sampleCount, 10);
    });

    test('tryDecode returns null for legacy / non-metadata cells', () {
      // Legacy metadata rows only have [instrument, date, time] (no 4th cell).
      expect(OscilloscopeRecordingMetadata.tryDecode(null), isNull);
      expect(OscilloscopeRecordingMetadata.tryDecode(''), isNull);
      expect(OscilloscopeRecordingMetadata.tryDecode('not-base64-@@'), isNull);
      // Valid base64 but not JSON.
      expect(OscilloscopeRecordingMetadata.tryDecode('aGVsbG8='), isNull);
    });

    test('fromJson tolerates missing/null fields', () {
      final meta = OscilloscopeRecordingMetadata.fromJson({});

      expect(meta.recordedAt, isNull);
      expect(meta.enabledChannels, isEmpty);
      expect(meta.range, isNull);
      expect(meta.timebase, isNull);
      expect(meta.triggerEnabled, isFalse);
      expect(meta.sampleCount, isNull);
      expect(meta.isEmpty, isTrue);
    });
  });
}
