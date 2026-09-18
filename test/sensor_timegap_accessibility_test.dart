import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/widgets/sensor_controls.dart';

void main() {
  tearDown(() async => getIt.reset());

  for (final language in ['en', 'hi']) {
    testWidgets('time gap exposes its name and milliseconds in $language', (
      tester,
    ) async {
      final localizations = await AppLocalizations.delegate.load(
        Locale(language),
      );
      registerAppLocalizations(localizations);
      final semantics = tester.ensureSemantics();
      try {
        var timegap = 400;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => SensorControlsWidget(
                  isPlaying: false,
                  isLooping: false,
                  timegapMs: timegap,
                  numberOfReadings: 10,
                  onPlayPause: () {},
                  onLoop: () {},
                  onTimegapChanged: (value) => setState(() => timegap = value),
                  onNumberOfReadingsChanged: (_) {},
                ),
              ),
            ),
          ),
        );

        SemanticsNode sliderNode() => find.semantics
            .byPredicate(
              (node) =>
                  !node.isMergedIntoParent &&
                  node.getSemanticsData().flagsCollection.isSlider,
            )
            .evaluate()
            .single;

        final initial = sliderNode().getSemanticsData();
        expect(initial.value, '400 ${localizations.ms}');
        expect(initial.label, contains(localizations.timeGap));
        expect(initial.increasedValue, '500 ${localizations.ms}');
        expect(initial.decreasedValue, '300 ${localizations.ms}');
        expect(initial.hasAction(SemanticsAction.increase), isTrue);
        expect(initial.hasAction(SemanticsAction.decrease), isTrue);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        final nextValue = initial.increasedValue;
        sliderNode().owner!.performAction(
              sliderNode().id,
              SemanticsAction.increase,
            );
        await tester.pump();
        expect(timegap, greaterThan(400));
        expect(sliderNode().getSemanticsData().value, nextValue);
        expect(sliderNode().getSemanticsData().value,
            '$timegap ${localizations.ms}');

        sliderNode().owner!.performAction(
              sliderNode().id,
              SemanticsAction.decrease,
            );
        await tester.pump();
        expect(timegap, 400);
        expect(
            sliderNode().getSemanticsData().value, '400 ${localizations.ms}');
        for (final limit in [200, 1000]) {
          tester
              .widget<Slider>(find.byType(Slider))
              .onChanged!(limit.toDouble());
          await tester.pump();
          final node = sliderNode();
          final action = limit == 200
              ? SemanticsAction.decrease
              : SemanticsAction.increase;
          node.owner!.performAction(node.id, action);
          await tester.pump();
          expect(timegap, limit);
          expect(sliderNode().getSemanticsData().value,
              '$limit ${localizations.ms}');
        }
      } finally {
        semantics.dispose();
      }
    });
  }
}
