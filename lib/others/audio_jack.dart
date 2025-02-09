import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:pslab/others/logger_service.dart';

class AudioJack {
  static const int samplingRate = 44100;
  final FlutterAudioCapture flutterAudioCapture = FlutterAudioCapture();

  List<double> _audioBuffer = [];

  AudioJack();

  Future<bool> configure() async {
    await flutterAudioCapture.init();
    await flutterAudioCapture.start(_listener, _onError,
        sampleRate: samplingRate);
    return true;
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

  void close() async {
    await flutterAudioCapture.stop();
  }
}
