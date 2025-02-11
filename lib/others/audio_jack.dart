import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:pslab/others/logger_service.dart';

class AudioJack {
  static const int samplingRate = 44100;
  bool _isListening = false;
  final FlutterAudioCapture flutterAudioCapture = FlutterAudioCapture();

  List<double> _audioBuffer = [];

  AudioJack();

  Future<void> initialize() async {
    await flutterAudioCapture.init();
  }

  Future<void> start() async {
    await flutterAudioCapture.start(_listener, _onError,
        sampleRate: samplingRate);
    _isListening = true;
  }

  List<double> read() {
    return _audioBuffer;
  }

  void _listener(dynamic obj) {
    _audioBuffer = obj.cast<double>();
  }

  void _onError(Object e) {
    logger.e(e);
  }

  Future<void> close() async {
    await flutterAudioCapture.stop();
    _isListening = false;
  }

  bool isListening() {
    return _isListening;
  }
}
