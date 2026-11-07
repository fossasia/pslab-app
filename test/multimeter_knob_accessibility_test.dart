import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/multimeter_state_provider.dart';
import 'package:pslab/view/widgets/multimeter_knob.dart';

void main() {
  setUp(() {
    setupLocator();
  });

  tearDown(() async => getIt.reset());

  for (final language in ['en', 'hi']) {
    testWidgets('multimeter knob exposes semantics in $language', (
      tester,
    ) async {
      final localizations = await AppLocalizations.delegate.load(
        Locale(language),
      );
      registerAppLocalizations(localizations);
      final semantics = tester.ensureSemantics();
      try {
        final provider = MultimeterStateProvider();

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(360, 690),
            builder: (context, child) => MaterialApp(
              home: Scaffold(
                body: ChangeNotifierProvider<MultimeterStateProvider>.value(
                  value: provider,
                  child: const SizedBox(
                    width: 350,
                    height: 350,
                    child: MultimeterKnob(),
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
        expect(semanticsData.value, localizations.knobMarkerCh1);
        expect(semanticsData.label, localizations.multimeter);
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
        expect(updatedData.value, localizations.knobMarkerCap);

        // Perform decrease action
        semanticsNode.owner!.performAction(
          semanticsNode.id,
          SemanticsAction.decrease,
        );
        await tester.pumpAndSettle();

        final restoredData = tester.getSemantics(knobFinder).getSemanticsData();
        expect(restoredData.value, localizations.knobMarkerCh1);
      } finally {
        semantics.dispose();
      }
    });
  }
}
