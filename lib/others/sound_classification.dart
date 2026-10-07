import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:flutter_litert/flutter_litert.dart';

class ActiveSoundEvent {
  final String label;
  final double confidence;
  final int hexColor;

  ActiveSoundEvent(this.label, this.confidence, this.hexColor);
}

class SoundClassificationService {
  static const String modelUrl =
      'https://huggingface.co/thelou1s/yamnet/resolve/main/lite-model_yamnet_classification_tflite_1.tflite';
  static const String modelFileName = 'yamnet_final.tflite';

  bool isModelLoaded = false;
  Interpreter? _interpreter;
  List<String> _labels = [];
  List<double> _smoothedScores = List.filled(521, 0.0);
  bool _isFirstFrame = true;

  Future<void> initializeEngine() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$modelFileName');

      if (!await file.exists() || await file.length() < 1000000) {
        if (await file.exists()) await file.delete();
        logger.i("Downloading YAMNet model...");
        final response = await http.get(Uri.parse(modelUrl));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception(
              "Download failed with status: ${response.statusCode}");
        }
      }

      final options = InterpreterOptions()..threads = 2;
      _interpreter = Interpreter.fromFile(file, options: options);

      final csvData =
          await rootBundle.loadString('assets/yamnet_class_map.csv');
      _labels = csvData
          .split('\n')
          .skip(1)
          .where((line) => line.isNotEmpty)
          .map((line) {
        final parts = line.split(',');
        return parts.length >= 3
            ? parts[2].replaceAll('"', '').trim()
            : "Unknown";
      }).toList();

      isModelLoaded = true;
      logger.i(
          "LiteRT AI initialized successfully with ${_labels.length} classes.");
    } catch (e) {
      logger.e("AI initialization failed: $e");
      isModelLoaded = false;
    }
  }

  void _cleanAudioBuffer(List<double> audio) {
    if (audio.isEmpty) return;
    double sum = 0.0;
    for (int i = 0; i < audio.length; i++) {
      sum += audio[i];
    }
    double mean = sum / audio.length;

    const double alpha = 0.97;
    double prevX = audio[0] - mean;
    double prevY = prevX;
    audio[0] = prevX;

    for (int i = 1; i < audio.length; i++) {
      double currentX = audio[i] - mean;
      audio[i] = alpha * (prevY + currentX - prevX);
      prevX = currentX;
      prevY = audio[i];
    }
  }

  double _calculateWindowDb(List<double> audioWindow) {
    if (audioWindow.isEmpty) return 0.0;
    double sum = 0.0;
    for (final sample in audioWindow) {
      sum += sample * sample;
    }
    double rms = sqrt(sum / audioWindow.length);
    if (rms <= 0.0) return 0.0;
    double dbFS = 20 * (log(rms) / ln10);

    return (dbFS + 64).clamp(20.0, 120.0);
  }

  List<ActiveSoundEvent> classifyAudioWindow(
      List<double> audioWindow, double currentDb) {
    if (_interpreter == null ||
        _labels.isEmpty ||
        audioWindow.length != 15600) {
      return [ActiveSoundEvent("Silence", 1.0, 0xFFB0BEC5)];
    }

    double windowDb = _calculateWindowDb(audioWindow);

    if (currentDb < 10.0) {
      _isFirstFrame = true;
      _smoothedScores = List.filled(521, 0.0);
      return [ActiveSoundEvent("Silence", 1.0, 0xFFB0BEC5)];
    }

    _cleanAudioBuffer(audioWindow);

    var input = [audioWindow];
    var output = List.filled(521, 0.0).reshape([1, 521]);
    _interpreter!.run(input, output);

    List<double> rawScores = (output[0] as List).cast<double>();
    if (_isFirstFrame) {
      _smoothedScores = List.from(rawScores);
      _isFirstFrame = false;
    } else {
      for (int i = 0; i < 521; i++) {
        _smoothedScores[i] =
            (rawScores[i] * 0.75) + (_smoothedScores[i] * 0.25);
      }
    }

    const blockedKeywords = [
      'stomach',
      'digest',
      'rumble',
      'burp',
      'eructation',
      'hiccup',
      'flatulence',
      'gargling',
      'animal',
      'bird',
      'pigeon',
      'dove',
      'wild',
      'chirp',
      'squawk',
      'roaring',
      'fowl',
      'livestock',
      'duck'
    ];

    List<MapEntry<int, double>> validEvents = [];

    for (int i = 0; i < _smoothedScores.length; i++) {
      if (i >= _labels.length) continue;

      String labelLower = _labels[i].toLowerCase();
      bool isBlocked = blockedKeywords.any((k) => labelLower.contains(k));
      if (isBlocked) continue;

      if (_smoothedScores[i] >= 0.14) {
        validEvents.add(MapEntry(i, _smoothedScores[i]));
      }
    }

    validEvents.sort((a, b) => b.value.compareTo(a.value));

    if (validEvents.isEmpty) {
      double highestScore = -1.0;
      int highestIdx = -1;
      for (int i = 0; i < _smoothedScores.length; i++) {
        if (i >= _labels.length) continue;

        String labelLower = _labels[i].toLowerCase();
        if (blockedKeywords.any((k) => labelLower.contains(k))) continue;

        if (_smoothedScores[i] > highestScore) {
          highestScore = _smoothedScores[i];
          highestIdx = i;
        }
      }
      if (highestIdx != -1) {
        validEvents.add(MapEntry(highestIdx, highestScore));
      }
    }

    if (validEvents.isNotEmpty) {
      final top = validEvents.first;
      logger.i(
          "OUTPUT -> Instant Smoothed: ${_labels[top.key]} (${(top.value * 100).toStringAsFixed(1)}%) | dB: ${windowDb.toStringAsFixed(1)}");
    }

    return validEvents.take(4).map((entry) {
      return ActiveSoundEvent(
        _labels[entry.key],
        entry.value,
        _getMacroColorForIndex(entry.key),
      );
    }).toList();
  }

  int _getMacroColorForIndex(int index) {
    if (index >= 0 && index <= 69) return 0xFFFF7043;
    if (index >= 300 && index <= 382) return 0xFF29B6F6;
    if (index >= 70 && index <= 299) return 0xFF66BB6A;
    if (index >= 383 && index <= 450) return 0xFFEF5350;
    return 0xFFB0BEC5;
  }
}
