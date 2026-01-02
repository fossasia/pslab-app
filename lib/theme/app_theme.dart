import 'package:flutter/material.dart';
import 'colors.dart';

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
          return radioButtonActiveColor;
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
    checkboxTheme: CheckboxThemeData(
      // Fix 1 & 3: Added space and handled disabled state for border
      side: WidgetStateBorderSide.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const BorderSide(color: Colors.grey, width: 2);
        }
        return const BorderSide(color: Colors.white, width: 2);
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        // Fix 2: Handle disabled state
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey;
        }
        if (states.contains(WidgetState.selected)) {
          return radioButtonActiveColor;
        }
        // Fix 1: Use White for unselected (Bot requested derived, but White is standard for Black theme)
        return Colors.white;
      }),
    ),
  );
}
