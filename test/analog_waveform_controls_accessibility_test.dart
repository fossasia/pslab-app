import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/wave_generator_state_provider.dart';
import 'package:pslab/view/widgets/analog_waveform_controls.dart';

class _DisconnectedScienceLab implements ScienceLab {
  @override
  bool isConnected() => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() async => getIt.reset());

  testWidgets('wave type buttons expose which wave is selected', (
    tester,
  ) async {
    final localizations = await AppLocalizations.delegate.load(
      const Locale('en'),
    );
    registerAppLocalizations(localizations);
    getIt.registerLazySingleton<ScienceLab>(() => _DisconnectedScienceLab());
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider(
              create: (_) => WaveGeneratorStateProvider(),
              child: const AnalogWaveformControls(),
            ),
          ),
        ),
      );

      Tristate selectedState(String label) => tester
          .getSemantics(find.byTooltip(label))
          .getSemanticsData()
          .flagsCollection
          .isSelected;

      expect(selectedState(localizations.sine), Tristate.isTrue);
      expect(selectedState(localizations.triangular), Tristate.isFalse);
      expect(selectedState(localizations.sawtooth), Tristate.isFalse);

      await tester.tap(find.byTooltip(localizations.sawtooth));
      await tester.pump();

      expect(selectedState(localizations.sine), Tristate.isFalse);
      expect(selectedState(localizations.sawtooth), Tristate.isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('wave and property buttons expose which one is selected', (
    tester,
  ) async {
    final localizations = await AppLocalizations.delegate.load(
      const Locale('en'),
    );
    registerAppLocalizations(localizations);
    getIt.registerLazySingleton<ScienceLab>(() => _DisconnectedScienceLab());
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider(
              create: (_) => WaveGeneratorStateProvider(),
              child: const AnalogWaveformControls(),
            ),
          ),
        ),
      );

      Tristate selectedState(String text) => tester
          .getSemantics(find.text(text))
          .getSemanticsData()
          .flagsCollection
          .isSelected;

      expect(selectedState(localizations.wave1), Tristate.isTrue);
      expect(selectedState(localizations.wave2), Tristate.isFalse);
      expect(selectedState(localizations.freq), Tristate.isFalse);

      await tester.tap(find.text(localizations.freq));
      await tester.pump();
      expect(selectedState(localizations.freq), Tristate.isTrue);

      await tester.tap(find.text(localizations.wave2));
      await tester.pump();
      await tester.tap(find.text(localizations.phase));
      await tester.pump();

      expect(selectedState(localizations.wave1), Tristate.isFalse);
      expect(selectedState(localizations.wave2), Tristate.isTrue);
      expect(selectedState(localizations.freq), Tristate.isFalse);
      expect(selectedState(localizations.phase), Tristate.isTrue);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });
}
