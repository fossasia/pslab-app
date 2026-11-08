import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/power_source_state_provider.dart';
import 'package:pslab/view/widgets/power_source_knob.dart';

void main() {
  setUp(() {
    setupLocator();
  });

  tearDown(() async => getIt.reset());

  for (final language in ['en', 'hi']) {
    testWidgets('power source knob exposes semantics in $language for PV1', (
      tester,
    ) async {
      final localizations = await AppLocalizations.delegate.load(
        Locale(language),
      );
      registerAppLocalizations(localizations);
      final semantics = tester.ensureSemantics();
      try {
        final provider = PowerSourceStateProvider();

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(360, 690),
            builder: (context, child) => MaterialApp(
              home: Scaffold(
                body: ChangeNotifierProvider<PowerSourceStateProvider>.value(
                  value: provider,
                  child: const SizedBox(
                    width: 350,
                    height: 350,
                    child: PowerSourceKnob(
                      maxValue: 1000,
                      pin: Pin.pv1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final knobFinder = find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.value != null,
        );
        expect(knobFinder, findsOneWidget);

        final semanticsData =
            tester.getSemantics(knobFinder).getSemanticsData();
        expect(semanticsData.label, localizations.pinPV1);
        expect(semanticsData.value, '-5.00 V');
        expect(semanticsData.hasAction(SemanticsAction.increase), isTrue);
        expect(semanticsData.hasAction(SemanticsAction.decrease), isTrue);

        // Perform increase action
        final semanticsNode = tester.getSemantics(knobFinder);
        semanticsNode.owner!.performAction(
          semanticsNode.id,
          SemanticsAction.increase,
        );
        await tester.pumpAndSettle();

        final updatedData = tester.getSemantics(knobFinder).getSemanticsData();
        expect(updatedData.value, '-4.99 V');

        // Perform decrease action
        semanticsNode.owner!.performAction(
          semanticsNode.id,
          SemanticsAction.decrease,
        );
        await tester.pumpAndSettle();

        final restoredData = tester.getSemantics(knobFinder).getSemanticsData();
        expect(restoredData.value, '-5.00 V');
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('power source knob exposes mA semantics in $language for PCS', (
      tester,
    ) async {
      final localizations = await AppLocalizations.delegate.load(
        Locale(language),
      );
      registerAppLocalizations(localizations);
      final semantics = tester.ensureSemantics();
      try {
        final provider = PowerSourceStateProvider();

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(360, 690),
            builder: (context, child) => MaterialApp(
              home: Scaffold(
                body: ChangeNotifierProvider<PowerSourceStateProvider>.value(
                  value: provider,
                  child: const SizedBox(
                    width: 350,
                    height: 350,
                    child: PowerSourceKnob(
                      maxValue: 330,
                      pin: Pin.pcs,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final knobFinder = find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.value != null,
        );
        expect(knobFinder, findsOneWidget);

        final semanticsData =
            tester.getSemantics(knobFinder).getSemanticsData();
        expect(semanticsData.label, localizations.pinPCS);
        expect(semanticsData.value, '0.00 mA');
        expect(semanticsData.hasAction(SemanticsAction.increase), isTrue);
        expect(semanticsData.hasAction(SemanticsAction.decrease), isTrue);

        // Perform increase action
        final semanticsNode = tester.getSemantics(knobFinder);
        semanticsNode.owner!.performAction(
          semanticsNode.id,
          SemanticsAction.increase,
        );
        await tester.pumpAndSettle();

        final updatedData = tester.getSemantics(knobFinder).getSemanticsData();
        expect(updatedData.value, '0.01 mA');
      } finally {
        semantics.dispose();
      }
    });
  }
}
