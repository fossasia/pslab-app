import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pslab/view/connect_device_screen.dart';
import 'package:pslab/view/faq_screen.dart';
import 'package:pslab/view/instruments_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.white,
            useMaterial3: true,
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const InstrumentsScreen(),
            '/connectDevice': (context) => const ConnectDeviceScreen(),
            '/faq': (context) => const FAQScreen(),
          },
        );
      },
    );
  }
}
