import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:pslab/others/logger_service.dart';

class AudioJack {
  static const int samplingRate = 44100;
  bool _isListening = false;

  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _streamSubscription;
  List<double> _audioBuffer = [];

  AudioJack();

  Future<void> initialize() async {
    /*The record package handles initialization internally during start() or permission checks.*/
  }

  Future<void> start() async {
    if (_isListening) return;

    try {
      _recorder = AudioRecorder();

      if (await _recorder!.hasPermission()) {
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
      } else {
        logger.e("Microphone permission denied.");
      }
    } catch (e) {
      logger.e("Error starting audio record stream: $e");
    }
  }

  void _listener(Uint8List data) {
    final byteData = ByteData.sublistView(data);
    List<double> tempBuffer = [];
    for (int i = 0; i < byteData.lengthInBytes - 1; i += 2) {
      final sample = byteData.getInt16(i, Endian.little);
      tempBuffer.add(sample / 32768.0);
    }
    _audioBuffer = tempBuffer;
  }

  void _onError(Object e) {
    logger.e("Audio Stream Error: $e");
    _isListening = false;
  }

  List<double> read() {
    return _audioBuffer;
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
  }

  Future<void> disposeHardware() async {
    await close();
  }

  bool isListening() {
    return _isListening;
  }
}
