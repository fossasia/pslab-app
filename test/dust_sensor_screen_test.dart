import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/dust_sensor_state_provider.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/dust_sensor_screen.dart';

class _ScreenTestSource implements DustSensorSource {
  @override
  bool get isConnected => true;

  @override
  Future<double> readVoltage() async => 2.5;
}

void main() {
  setUp(() async {
    registerAppLocalizations(
      await AppLocalizations.delegate.load(const Locale('en')),
    );
  });

  tearDown(() async => getIt.reset());

  testWidgets('dust sensor screen exposes readings and measurement controls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = DustSensorStateProvider(
      source: _ScreenTestSource(),
      updatePeriod: const Duration(days: 1),
    );

    await tester.pumpWidget(
      MaterialApp(home: DustSensorScreen(provider: provider)),
    );
    await tester.pump();

    expect(find.text('Dust Sensor'), findsOneWidget);
    expect(find.text('Relative signal: 50%'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('RESET'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
