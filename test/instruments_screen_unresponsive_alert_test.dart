import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pslab/communication/handler/wifi_comms_handler.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/science_lab_common.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/providers/instrument_filter_provider.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/settings_config_provider.dart';
import 'package:pslab/view/instruments_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SilentScienceLab extends ScienceLab {
  _SilentScienceLab() : super(WifiCommsHandler());

  @override
  Future<String> getVersion() async => '';

  @override
  bool isConnected() => false;
}

class _FakeScienceLabCommon extends ScienceLabCommon {
  _FakeScienceLabCommon(this.scienceLab) : super(WifiCommsHandler());

  final ScienceLab scienceLab;

  @override
  ScienceLab getScienceLab() => scienceLab;

  @override
  Future<bool> openWiFiDevice() async => true;
}

Widget _app(BoardStateProvider board) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsConfigProvider>(
          create: (_) => SettingsConfigProvider()),
      ChangeNotifierProvider<BoardStateProvider>.value(value: board),
      ChangeNotifierProvider(create: (_) => HardwareFilterProvider()),
    ],
    child: ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          registerAppLocalizations(AppLocalizations.of(context)!);
          return child!;
        },
        home: const InstrumentsScreen(),
      ),
    ),
  );
}

void main() {
  late BoardStateProvider board;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    final scienceLab = _SilentScienceLab();
    getIt.registerSingleton<ScienceLab>(scienceLab);
    getIt
        .registerSingleton<ScienceLabCommon>(_FakeScienceLabCommon(scienceLab));
    board = BoardStateProvider();
    getIt.registerSingleton<BoardStateProvider>(board);
  });

  testWidgets('shows a failure reported before the screen opened once',
      (tester) async {
    await tester.runAsync(board.initializeWiFi);

    await tester.pumpWidget(_app(board));
    await tester.pumpAndSettle();

    expect(find.text('PSLab Not Responding'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(board));
    await tester.pumpAndSettle();

    expect(find.text('PSLab Not Responding'), findsNothing);
  });
}
