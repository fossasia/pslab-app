import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:pslab/providers/sht21_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/settings_config_provider.dart';
import 'package:pslab/view/accelerometer_screen.dart';
import 'package:pslab/view/barometer_screen.dart';
import 'package:pslab/view/connect_device_screen.dart';
import 'package:pslab/view/faq_screen.dart';
import 'package:pslab/view/gyroscope_screen.dart';
import 'package:pslab/view/instruments_screen.dart';
import 'package:pslab/view/logged_data_screen.dart';
import 'package:pslab/view/logic_analyzer_screen.dart';
import 'package:pslab/view/luxmeter_screen.dart';
import 'package:pslab/view/multimeter_screen.dart';
import 'package:pslab/view/oscilloscope_screen.dart';
import 'package:pslab/view/power_source_screen.dart';
import 'package:pslab/view/robotic_arm_screen.dart';
import 'package:pslab/view/sensors_screen.dart';
import 'package:pslab/view/settings_screen.dart';
import 'package:pslab/view/about_us_screen.dart';
import 'package:pslab/view/software_licenses_screen.dart';
import 'package:pslab/view/compass_screen.dart';
import 'package:pslab/view/soundmeter_screen.dart';
import 'package:pslab/view/thermometer_screen.dart';
import 'package:pslab/view/wave_generator_screen.dart';
import 'package:pslab/view/experiments_screen.dart';
import 'constants.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS) &&
      args.any((a) => a == '-v' || a == '--version')) {
    if (Platform.isWindows) {
      _attachParentConsole();
    }
    final info = await PackageInfo.fromPlatform();
    stdout.writeln('${info.appName} ${info.version}+${info.buildNumber}');
    await stdout.flush();
    exit(0);
  }

  setupLocator();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsConfigProvider>(
          create: (context) => SettingsConfigProvider(),
        ),
        ChangeNotifierProvider<BoardStateProvider>(
          create: (context) => getIt<BoardStateProvider>(),
        ),
        ChangeNotifierProvider<SHT21Provider>(
          create: (context) => getIt<SHT21Provider>(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

bool _boardInitialized = false;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations? appLocalizations;
    _preCacheImages(context);
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) {
        return Consumer<SettingsConfigProvider>(
          builder: (context, provider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: Locale(provider.config.languageCode),
              builder: (context, child) {
                registerAppLocalizations(AppLocalizations.of(context)!);
                if (!_boardInitialized) {
                  _boardInitialized = true;
                  getIt<BoardStateProvider>().initialize();
                }
                appLocalizations = getIt.get<AppLocalizations>();
                return child!;
              },
              theme: ThemeData(
                colorSchemeSeed: Colors.white,
                useMaterial3: true,
              ),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              initialRoute: '/',
              routes: {
                '/': (context) =>
                    const _LocaleAware(child: InstrumentsScreen()),
                '/oscilloscope': (context) =>
                    const _LocaleAware(child: OscilloscopeScreen()),
                '/multimeter': (context) =>
                    const _LocaleAware(child: MultimeterScreen()),
                '/waveGenerator': (context) =>
                    const _LocaleAware(child: WaveGeneratorScreen()),
                '/logicAnalyzer': (context) =>
                    const _LocaleAware(child: LogicAnalyzerScreen()),
                '/powerSource': (context) =>
                    const _LocaleAware(child: PowerSourceScreen()),
                '/compass': (context) =>
                    const _LocaleAware(child: CompassScreen()),
                '/connectDevice': (context) =>
                    const _LocaleAware(child: ConnectDeviceScreen()),
                '/faq': (context) => _LocaleAware(child: FAQScreen()),
                '/settings': (context) =>
                    const _LocaleAware(child: SettingsScreen()),
                '/aboutUs': (context) =>
                    const _LocaleAware(child: AboutUsScreen()),
                '/softwareLicenses': (context) =>
                    _LocaleAware(child: SoftwareLicensesScreen()),
                '/accelerometer': (context) =>
                    const _LocaleAware(child: AccelerometerScreen()),
                '/gyroscope': (context) =>
                    const _LocaleAware(child: GyroscopeScreen()),
                '/roboticArm': (context) =>
                    const _LocaleAware(child: RoboticArmScreen()),
                '/luxmeter': (context) =>
                    const _LocaleAware(child: LuxMeterScreen()),
                '/barometer': (context) =>
                    const _LocaleAware(child: BarometerScreen()),
                '/soundmeter': (context) =>
                    const _LocaleAware(child: SoundMeterScreen()),
                '/thermometer': (context) =>
                    const _LocaleAware(child: ThermometerScreen()),
                '/sensors': (context) =>
                    const _LocaleAware(child: SensorsScreen()),
                '/experiments': (context) =>
                    const _LocaleAware(child: ExperimentsScreen()),
                '/loggedData': (context) => _LocaleAware(
                      child: LoggedDataScreen(
                        instrumentNames: instrumentNames,
                        appBarName: appLocalizations!.loggedData,
                        instrumentIcons: instrumentIcons,
                      ),
                    ),
              },
            );
          },
        );
      },
    );
  }
}

class _LocaleAware extends StatelessWidget {
  final Widget child;
  const _LocaleAware({required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsConfigProvider>(
      builder: (_, provider, __) => KeyedSubtree(
        key: ValueKey(provider.config.languageCode),
        child: child,
      ),
    );
  }
}

void _attachParentConsole() {
  const attachParentProcess = 0xFFFFFFFF;
  final kernel32 = ffi.DynamicLibrary.open('kernel32.dll');
  final attachConsole = kernel32.lookupFunction<ffi.Int32 Function(ffi.Uint32),
      int Function(int)>('AttachConsole');
  attachConsole(attachParentProcess);
}

void _preCacheImages(BuildContext context) {
  for (final path in instrumentIcons) {
    precacheImage(AssetImage(path), context);
  }
  precacheImage(
      const AssetImage('assets/icons/ic_nav_header_logo.png'), context);
}
