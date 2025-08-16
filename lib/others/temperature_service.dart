import 'dart:async';
import 'package:flutter/services.dart';
import 'package:pslab/others/logger_service.dart';

class TemperatureService {
  static const MethodChannel _methodChannel =
      MethodChannel('io.pslab/temperature');
  static const EventChannel _eventChannel =
      EventChannel('io.pslab/temperature_stream');

  static StreamSubscription<dynamic>? _temperatureSubscription;
  static final StreamController<double> _temperatureController =
      StreamController<double>.broadcast();

  static Stream<double> get temperatureStream => _temperatureController.stream;

  static Future<bool> isTemperatureSensorAvailable() async {
    try {
      final bool isAvailable =
          await _methodChannel.invokeMethod('isTemperatureSensorAvailable');
      logger.d('Temperature sensor available: $isAvailable');
      return isAvailable;
    } on PlatformException catch (e) {
      logger.e('Error checking temperature sensor availability: ${e.message}');
      return false;
    }
  }

  static Future<double> getCurrentTemperature() async {
    try {
      final double temperature =
          await _methodChannel.invokeMethod('getCurrentTemperature');
      logger.d('Current temperature: $temperature°C');
      return temperature;
    } on PlatformException catch (e) {
      logger.e('Error getting current temperature: ${e.message}');
      return 0.0;
    }
  }

  static Future<bool> startTemperatureUpdates() async {
    try {
      final bool success =
          await _methodChannel.invokeMethod('startTemperatureUpdates');
      if (success) {
        _startListening();
        logger.d('Temperature updates started');
      }
      return success;
    } on PlatformException catch (e) {
      logger.e('Error starting temperature updates: ${e.message}');
      return false;
    }
  }

  static Future<void> stopTemperatureUpdates() async {
    try {
      await _methodChannel.invokeMethod('stopTemperatureUpdates');
      _stopListening();
      logger.d('Temperature updates stopped');
    } on PlatformException catch (e) {
      logger.e('Error stopping temperature updates: ${e.message}');
    }
  }

  static void _startListening() {
    _temperatureSubscription?.cancel();
    _temperatureSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic temperature) {
        logger.d('Received temperature from stream: $temperature');
        if (temperature is double) {
          _temperatureController.add(temperature);
        } else if (temperature is num) {
          _temperatureController.add(temperature.toDouble());
        }
      },
      onError: (error) {
        logger.e('Temperature stream error: $error');
      },
    );
  }

  static void _stopListening() {
    _temperatureSubscription?.cancel();
    _temperatureSubscription = null;
  }

  static void dispose() {
    _stopListening();
    _temperatureController.close();
  }
}
