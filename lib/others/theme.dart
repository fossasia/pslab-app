import 'package:flutter/material.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    colorSchemeSeed: Colors.white,
    checkboxTheme: const CheckboxThemeData(
      side: BorderSide(color: Colors.black, width: 2),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFCE525F);
        }
        return Colors.black;
      }),
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.black,
    colorSchemeSeed: Colors.black,
    checkboxTheme: const CheckboxThemeData(
      side: BorderSide(color: Colors.black, width: 2),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFCE525F);
        }
        return Colors.black;
      }),
    ),
  );
}
