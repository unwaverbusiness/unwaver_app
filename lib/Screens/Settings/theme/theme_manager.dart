import 'package:flutter/material.dart';

// --- STATE NOTIFIERS ---

// The active accent color.
final ValueNotifier<Color> appThemeColor = ValueNotifier<Color>(
  const Color(0xFFBB8E13), // Unwaver Gold
);

// The active theme mode (Light/Dark).
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier<ThemeMode>(
  ThemeMode.light,
);

// --- CORE LOGIC ---

void updateThemeColor(Color newColor) {
  appThemeColor.value = newColor;
}

void updateThemeMode(ThemeMode newMode) {
  appThemeMode.value = newMode;
}

/// Returns a readable foreground color for the provided background color.
Color getContrastingTextColor(Color backgroundColor) {
  return backgroundColor.computeLuminance() > 0.5
      ? Colors.black87
      : Colors.white;
}

// --- PRESETS ---

final List<Color> availableThemeColors = [
  const Color(0xFFBB8E13), // Original Gold
  const Color(0xFF1D8CA0), // Original Teal
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
  Colors.brown,
  Colors.blueGrey,
  const Color(0xFFE91E63), // Vibrant Pink
  const Color(0xFF00BCD4), // Vibrant Cyan
  const Color(0xFF4CAF50), // Vibrant Green
];
