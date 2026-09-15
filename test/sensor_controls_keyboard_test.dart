import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/widgets/sensor_controls.dart';

void main() {
  setUp(() async {
    registerAppLocalizations(
      await AppLocalizations.delegate.load(const Locale('en')),
    );
  });

  tearDown(() async => getIt.reset());

  testWidgets('sensor actions are reachable and activated by keyboard', (
    tester,
  ) async {
    var playCount = 0;
    var loopCount = 0;
    var clearCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SensorControlsWidget(
            isPlaying: false,
            isLooping: false,
            timegapMs: 200,
            numberOfReadings: 10,
            onPlayPause: () => playCount++,
            onLoop: () => loopCount++,
            onClearData: () => clearCount++,
            onTimegapChanged: (_) {},
            onNumberOfReadingsChanged: (_) {},
          ),
        ),
      ),
    );

    // Tab order: play, sample count field, loop, clear, time gap slider.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(playCount, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(loopCount, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(clearCount, 1);
    expect(playCount, 1);
    expect(loopCount, 1);
  });
}
