import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:pslab/others/logger_service.dart';

class AudioJack {
  static const int samplingRate = 44100;

  static const int _maxBufferSamples = 44100;

  bool _isListening = false;

  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _streamSubscription;

  final ListQueue<double> _ringBuffer = ListQueue<double>(_maxBufferSamples);

  AudioJack();

  Future<void> initialize() async {}

  Future<void> start() async {
    if (_isListening) return;

    try {
      _recorder = AudioRecorder();

      final hasPerm = await _recorder!.hasPermission();
      if (!hasPerm) {
        logger.e("Microphone permission denied.");
        return;
      }

      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: samplingRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      );

      final stream = await _recorder!.startStream(config);

      _streamSubscription = stream.listen(_listener, onError: _onError);
      _isListening = true;
    } catch (e) {
      logger.e("Error starting audio record stream: $e");
      _isListening = false;
    }
  }

  void _listener(Uint8List data) {
    final byteData = ByteData.sublistView(data);

    for (int i = 0; i < byteData.lengthInBytes - 1; i += 2) {
      final sample = byteData.getInt16(i, Endian.little);
      final value = sample / 32768.0;

      if (_ringBuffer.length >= _maxBufferSamples) {
        _ringBuffer.removeFirst();
      }
      _ringBuffer.addLast(value);
    }
  }

  void _onError(Object e) {
    logger.e("Audio Stream Error: $e");
    _isListening = false;
  }

  List<double> read() {
    return readSamples(512);
  }

  List<double> readSamples(int count) {
    if (count <= 0) return <double>[];

    final int available = _ringBuffer.length;

    if (available == 0) {
      return List<double>.filled(count, 0.0);
    }

    final List<double> out = List<double>.filled(count, 0.0);

    final int take = available >= count ? count : available;
    final int startIndexInOut = count - take;

    final List<double> snapshot = _ringBuffer.toList();
    final List<double> tail = snapshot.sublist(snapshot.length - take);

    for (int i = 0; i < take; i++) {
      out[startIndexInOut + i] = tail[i];
    }

    return out;
  }

  Future<void> close() async {
    _isListening = false;
    await _streamSubscription?.cancel();
    _streamSubscription = null;

    if (_recorder != null) {
      await _recorder!.stop();
      await _recorder!.dispose();
      _recorder = null;
    }

    _ringBuffer.clear();
  }

  Future<void> disposeHardware() async {
    await close();
  }

  bool isListening() => _isListening;
}
