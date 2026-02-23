import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/main.dart' as app;
import 'utils.dart';

void main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    return Future(() async {
      WidgetsApp.debugAllowBannerOverride = false;
      if (Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
      }
    });
  });

  group('E2E Group', () {
    testWidgets('Take Screenshots', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final instrumentsScreenTitle = find.byKey(
        const ValueKey(instrumentsScreenTitleKey),
      );
      final powerSourceScreenTitle = find.byKey(
        const ValueKey(powerSourceScreenTitleKey),
      );
      final multimeterScreenTitle = find.byKey(
        const ValueKey(multimeterScreenTitleKey),
      );
      final waveGeneratorScreenTitle = find.byKey(
        const ValueKey(waveGeneratorScreenTitleKey),
      );
      final oscilloscopeScreenTitle = find.byKey(
        const ValueKey(oscilloscopeScreenTitleKey),
      );

      final notConnectedText = find.text('Not Connected');
      final backButton = find.byIcon(Icons.arrow_back);

      Future<void> scrollToTop() async {
        final topItem = find.text('OSCILLOSCOPE');
        await tester.scrollUntilVisible(
          topItem,
          -300.0,
          scrollable: find.byType(Scrollable),
          maxScrolls: 50,
        );
        await tester.pumpAndSettle();
      }

      await pumpUntilFound(tester, instrumentsScreenTitle);
      await tester.pump(const Duration(seconds: 2));
      await binding.takeScreenshot('1_instruments_screen');

      ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, notConnectedText);
      await tester.pump(const Duration(seconds: 1));
      await binding.takeScreenshot('2_nav_drawer');

      state.closeDrawer();
      await tester.pumpAndSettle();

      final accelerometerCard = find.text('ACCELEROMETER');
      await tester.scrollUntilVisible(
        accelerometerCard,
        200.0,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(accelerometerCard);
      await tester.pump(const Duration(seconds: 2));

      final infoIcon = find.byIcon(Icons.info);
      await tester.tap(infoIcon);
      await tester.pump(const Duration(seconds: 2));
      await binding.takeScreenshot('3_accelerometer');

      final hideGuideText = find.text('Hide Guide');
      if (tester.any(hideGuideText)) {
        await tester.tap(hideGuideText);
        await tester.pump(const Duration(seconds: 1));
      }

      await tester.tap(backButton);
      await tester.pump(const Duration(seconds: 2));
      await pumpUntilFound(tester, instrumentsScreenTitle);

      await scrollToTop();

      final powerSourceCard = find.text('POWER SOURCE');
      await tester.scrollUntilVisible(
        powerSourceCard,
        200.0,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(powerSourceCard);
      await pumpUntilFound(tester, powerSourceScreenTitle);
      await tester.pump(const Duration(seconds: 2));
      await binding.takeScreenshot('4_power_source');

      await tester.tap(backButton);
      await tester.pump(const Duration(seconds: 2));
      await pumpUntilFound(tester, instrumentsScreenTitle);

      await scrollToTop();

      final multimeterCard = find.text('MULTIMETER');
      await tester.scrollUntilVisible(
        multimeterCard,
        200.0,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(multimeterCard);
      await pumpUntilFound(tester, multimeterScreenTitle);
      await tester.pump(const Duration(seconds: 2));
      await binding.takeScreenshot('5_multimeter');

      await tester.tap(backButton);
      await tester.pump(const Duration(seconds: 2));
      await pumpUntilFound(tester, instrumentsScreenTitle);

      await scrollToTop();

      final waveGeneratorCard = find.text('WAVE GENERATOR');
      await tester.scrollUntilVisible(
        waveGeneratorCard,
        200.0,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(waveGeneratorCard);
      await pumpUntilFound(tester, waveGeneratorScreenTitle);

      final freqText = find.text('Freq');
      if (tester.any(freqText)) {
        await tester.tap(freqText);
        await tester.pump(const Duration(seconds: 2));
      }
      await binding.takeScreenshot('6_wave_generator');

      await tester.tap(backButton);
      await tester.pump(const Duration(seconds: 2));
      await pumpUntilFound(tester, instrumentsScreenTitle);

      await scrollToTop();

      final oscilloscopeCard = find.text('OSCILLOSCOPE');
      await tester.scrollUntilVisible(
        oscilloscopeCard,
        200.0,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(oscilloscopeCard);
      await pumpUntilFound(tester, oscilloscopeScreenTitle);
      await tester.pump(const Duration(seconds: 2));
      await binding.takeScreenshot('7_oscilloscope');
    });
  });
}
