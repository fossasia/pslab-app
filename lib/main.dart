import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/providers/locator.dart';
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
import 'package:pslab/theme/app_theme.dart';
import 'package:pslab/view/soundmeter_screen.dart';
import 'package:pslab/view/thermometer_screen.dart';
import 'package:pslab/view/wave_generator_screen.dart';
import 'package:pslab/view/experiments_screen.dart';
import 'constants.dart';

void main() {
  setupLocator();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BoardStateProvider>(
          create: (context) => getIt<BoardStateProvider>(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations? appLocalizations;
    _preCacheImages(context);
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            registerAppLocalizations(AppLocalizations.of(context)!);
            getIt<BoardStateProvider>().initialize();
            appLocalizations = getIt.get<AppLocalizations>();
            return child!;
          },
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          initialRoute: '/',
          routes: {
            '/': (context) => const InstrumentsScreen(),
            '/oscilloscope': (context) => const OscilloscopeScreen(),
            '/multimeter': (context) => const MultimeterScreen(),
            '/waveGenerator': (context) => const WaveGeneratorScreen(),
            '/logicAnalyzer': (context) => const LogicAnalyzerScreen(),
            '/powerSource': (context) => const PowerSourceScreen(),
            '/compass': (context) => const CompassScreen(),
            '/connectDevice': (context) => const ConnectDeviceScreen(),
            '/faq': (context) => FAQScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/aboutUs': (context) => const AboutUsScreen(),
            '/softwareLicenses': (context) => SoftwareLicensesScreen(),
            '/accelerometer': (context) => const AccelerometerScreen(),
            '/gyroscope': (context) => const GyroscopeScreen(),
            '/roboticArm': (context) => const RoboticArmScreen(),
            '/luxmeter': (context) => const LuxMeterScreen(),
            '/barometer': (context) => const BarometerScreen(),
            '/soundmeter': (context) => const SoundMeterScreen(),
            '/thermometer': (context) => const ThermometerScreen(),
            '/sensors': (context) => const SensorsScreen(),
            '/experiments': (context) => const ExperimentsScreen(),
            '/loggedData': (context) => LoggedDataScreen(
                  instrumentNames: instrumentNames,
                  appBarName: appLocalizations!.loggedData,
                  instrumentIcons: instrumentIcons,
                ),
          },
        );
      },
    );
  }
}

void _preCacheImages(BuildContext context) {
  for (final path in instrumentIcons) {
    precacheImage(AssetImage(path), context);
  }
  precacheImage(
      const AssetImage('assets/icons/ic_nav_header_logo.png'), context);
}
