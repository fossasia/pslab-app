import 'package:flutter_audio_capture/flutter_audio_capture.dart';

class AudioJack {
  static const int samplingRate = 44100;
  final FlutterAudioCapture flutterAudioCapture = FlutterAudioCapture();

  late List<double> _audioBuffer;

  AudioJack();

  Future<bool> _configure() async {
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
    print(e);
  }

  Future<void> close() async {
    await flutterAudioCapture.stop();
  }
}
