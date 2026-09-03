import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/others/permissions.dart';
import 'package:record/record.dart';

import 'package:pslab/src/rust/api/audio.dart' as rust_api;

class AudioJack {
  static const int maxBufferSize = 1024;
  static const int samplingRate = 44100;

  bool _isListening = false;

  StreamSubscription<List<double>>? _desktopAudioSubscription;
  AudioRecorder? _platformAudioRecorder;
  StreamSubscription<Uint8List>? _platformStreamSubscription;

  final List<double> _audioBuffer = [];

  AudioJack();

  Future<void> initialize() async {}

  bool get _isDesktopPlatform {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  Future<void> start() async {
    if (_isListening) return;

    try {
      if (_isDesktopPlatform) {
        await _startDesktopRustAudio();
      } else {
        await _startPlatformRecordAudio();
      }
    } catch (e) {
      logger.e("Error starting audio record stream: $e");
    }
  }

  Future<void> _startDesktopRustAudio() async {
    AppPermissionStatus status =
        await PSLabPermissions.checkStatus(AppPermission.microphone);

    if (status != AppPermissionStatus.granted) {
      status = await PSLabPermissions.request(AppPermission.microphone);
    }

    if (status == AppPermissionStatus.granted) {
      final stream = rust_api.startMicrophone();
      _desktopAudioSubscription =
          stream.listen(_onAudioDataReceived, onError: _onError);
      _isListening = true;
    } else {
      logger.e("Desktop Microphone permission denied.");
    }
  }

  Future<void> _startPlatformRecordAudio() async {
    _platformAudioRecorder = AudioRecorder();

    if (await _platformAudioRecorder!.hasPermission()) {
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: samplingRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      );

      final stream = await _platformAudioRecorder!.startStream(config);
      _platformStreamSubscription =
          stream.listen(_onPlatformByteDataReceived, onError: _onError);
      _isListening = true;
    } else {
      logger.e("Mobile/Web Microphone permission denied.");
    }
  }

  void _onAudioDataReceived(List<double> data) {
    _audioBuffer.addAll(data);
    _trimBuffer();
  }

  void _onPlatformByteDataReceived(Uint8List data) {
    final byteData = ByteData.sublistView(data);
    List<double> tempBuffer = [];

    for (int i = 0; i < byteData.lengthInBytes - 1; i += 2) {
      final sample = byteData.getInt16(i, Endian.little);
      tempBuffer.add(sample / 32768.0);
    }

    _audioBuffer.addAll(tempBuffer);
    _trimBuffer();
  }

  void _trimBuffer() {
    if (_audioBuffer.length > maxBufferSize) {
      _audioBuffer.removeRange(0, _audioBuffer.length - maxBufferSize);
    }
  }

  void _onError(Object e) {
    logger.e("Audio Stream Error: $e");
    _isListening = false;
  }

  List<double> read() {
    return List.from(_audioBuffer);
  }

  Future<void> close() async {
    _isListening = false;

    if (_isDesktopPlatform) {
      await _desktopAudioSubscription?.cancel();
      _desktopAudioSubscription = null;
      await rust_api.stopMicrophone();
    } else {
      await _platformStreamSubscription?.cancel();
      _platformStreamSubscription = null;

      if (_platformAudioRecorder != null) {
        await _platformAudioRecorder!.stop();
        await _platformAudioRecorder!.dispose();
        _platformAudioRecorder = null;
      }
    }

    _audioBuffer.clear();
  }

  Future<void> disposeHardware() async {
    await close();
  }

  bool isListening() {
    return _isListening;
  }
}
