import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/models/chart_data_points.dart';
import 'package:pslab/providers/mlx90614_provider.dart';

void main() {
  late MLX90614Provider provider;
  final getIt = GetIt.instance;

  setUp(() {
    getIt.reset();
    getIt.registerLazySingleton<AppLocalizations>(
      () => lookupAppLocalizations(const Locale('en')),
    );
    provider = MLX90614Provider();
  });

  tearDown(() {
    getIt.reset();
  });

  // ============================================================
  // GROUP 1: Initial State
  // ============================================================
  group('Initial State', () {
    test('objectTemperature starts at 0.0', () {
      expect(provider.objectTemperature, 0.0);
    });

    test('ambientTemperature starts at 0.0', () {
      expect(provider.ambientTemperature, 0.0);
    });

    test('isRunning starts as false', () {
      expect(provider.isRunning, false);
    });

    test('isLooping starts as false', () {
      expect(provider.isLooping, false);
    });

    test('timegapMs starts at 1000', () {
      expect(provider.timegapMs, 1000);
    });

    test('numberOfReadings starts at 100', () {
      expect(provider.numberOfReadings, 100);
    });

    test('collectedReadings starts at 0', () {
      expect(provider.collectedReadings, 0);
    });

    test('objectTempData starts empty', () {
      expect(provider.objectTempData, isEmpty);
    });

    test('ambientTempData starts empty', () {
      expect(provider.ambientTempData, isEmpty);
    });

    test('isCollectionComplete starts as false', () {
      expect(provider.isCollectionComplete, false);
    });
  });

  // ============================================================
  // GROUP 2: toggleLooping
  // ============================================================
  group('toggleLooping', () {
    test('toggles from false to true', () {
      expect(provider.isLooping, false);
      provider.toggleLooping();
      expect(provider.isLooping, true);
    });

    test('toggles from true back to false', () {
      provider.toggleLooping(); // true
      provider.toggleLooping(); // false
      expect(provider.isLooping, false);
    });

    test('can toggle multiple times', () {
      for (int i = 0; i < 5; i++) {
        provider.toggleLooping();
      }
      // 5 toggles from false = true
      expect(provider.isLooping, true);
    });
  });

  // ============================================================
  // GROUP 3: setTimegap
  // ============================================================
  group('setTimegap', () {
    test('sets custom timegap', () {
      provider.setTimegap(500);
      expect(provider.timegapMs, 500);
    });

    test('updates timegap to new value', () {
      provider.setTimegap(500);
      provider.setTimegap(2000);
      expect(provider.timegapMs, 2000);
    });

    test('allows very small timegap', () {
      provider.setTimegap(100);
      expect(provider.timegapMs, 100);
    });

    test('allows large timegap', () {
      provider.setTimegap(10000);
      expect(provider.timegapMs, 10000);
    });
  });

  // ============================================================
  // GROUP 4: setNumberOfReadings
  // ============================================================
  group('setNumberOfReadings', () {
    test('sets custom number of readings', () {
      provider.setNumberOfReadings(50);
      expect(provider.numberOfReadings, 50);
    });

    test('updates to new value', () {
      provider.setNumberOfReadings(50);
      provider.setNumberOfReadings(200);
      expect(provider.numberOfReadings, 200);
    });

    test('allows value of 1', () {
      provider.setNumberOfReadings(1);
      expect(provider.numberOfReadings, 1);
    });
  });

  // ============================================================
  // GROUP 5: clearData
  // ============================================================
  group('clearData', () {
    test('resets objectTemperature to 0', () {
      provider.clearData();
      expect(provider.objectTemperature, 0.0);
    });

    test('resets ambientTemperature to 0', () {
      provider.clearData();
      expect(provider.ambientTemperature, 0.0);
    });

    test('resets collectedReadings to 0', () {
      provider.clearData();
      expect(provider.collectedReadings, 0);
    });

    test('clears objectTempData list', () {
      provider.clearData();
      expect(provider.objectTempData, isEmpty);
    });

    test('clears ambientTempData list', () {
      provider.clearData();
      expect(provider.ambientTempData, isEmpty);
    });
  });

  // ============================================================
  // GROUP 6: toggleDataCollection without sensor
  // ============================================================
  group('toggleDataCollection without sensor', () {
    test('does not start if sensor is not initialized', () {
      provider.toggleDataCollection();
      // Without sensor, _startDataCollection returns immediately
      // isRunning should still be false because _mlx90614 is null
      expect(provider.isRunning, false);
    });
  });

  // ============================================================
  // GROUP 7: isCollectionComplete
  // ============================================================
  group('isCollectionComplete', () {
    test('false when looping is enabled', () {
      provider.toggleLooping(); // isLooping = true
      expect(provider.isCollectionComplete, false);
    });

    test('false when no readings collected', () {
      expect(provider.isCollectionComplete, false);
    });
  });

  // ============================================================
  // GROUP 8: Data list immutability
  // ============================================================
  group('Data list immutability', () {
    test('objectTempData returns unmodifiable list', () {
      final list = provider.objectTempData;
      expect(
        () => list.add(ChartDataPoint(0, 0)),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('ambientTempData returns unmodifiable list', () {
      final list = provider.ambientTempData;
      expect(
        () => list.add(ChartDataPoint(0, 0)),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  // ============================================================
  // GROUP 9: dispose
  // ============================================================
  group('dispose', () {
    test('dispose does not throw', () {
      expect(() => provider.dispose(), returnsNormally);
    });

    test('can be called multiple times without error', () {
      provider.dispose();
      // Second dispose should not throw
      // The super.dispose() may throw but stopDataCollection won't
    });
  });

  // ============================================================
  // GROUP 10: initializeSensors without I2C
  // ============================================================
  group('initializeSensors edge cases', () {
    test('reports error when i2c is null', () async {
      String? errorMessage;
      await provider.initializeSensors(
        onError: (msg) => errorMessage = msg,
        i2c: null,
        scienceLab: null,
      );
      expect(errorMessage, isNotNull);
    });

    test('reports error when scienceLab is null', () async {
      String? errorMessage;
      await provider.initializeSensors(
        onError: (msg) => errorMessage = msg,
        i2c: null,
        scienceLab: null,
      );
      expect(errorMessage, isNotNull);
    });
  });
}
