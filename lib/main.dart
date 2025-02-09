import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/connect_device_screen.dart';
import 'package:pslab/view/faq_screen.dart';
import 'package:pslab/view/instruments_screen.dart';
import 'package:pslab/view/oscilloscope_screen.dart';

import 'constants.dart';

void main() {
  setupLocator();
  WidgetsFlutterBinding.ensureInitialized();
  getIt<BoardStateProvider>().initialize();
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
    _preCacheImages(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.white,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const InstrumentsScreen(),
        '/oscilloscope': (context) => const OscilloscopeScreen(),
        '/connectDevice': (context) => const ConnectDeviceScreen(),
        '/faq': (context) => const FAQScreen(),
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
