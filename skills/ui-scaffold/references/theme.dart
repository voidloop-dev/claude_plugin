// lib/theme/theme.dart — Flutter Material 3 theming from a seed + semantic tokens.
import 'package:flutter/material.dart';

class AppSpacing {
  static const x1 = 4.0, x2 = 8.0, x3 = 12.0, x4 = 16.0, x6 = 24.0, x8 = 32.0;
}

class AppRadius {
  static const sm = 4.0, md = 8.0, lg = 12.0;
}

ThemeData _build(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4F46E5),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: Typography.material2021().black.apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        ),
    focusColor: scheme.primary.withOpacity(0.4),
  );
}

final lightTheme = _build(Brightness.light);
final darkTheme = _build(Brightness.dark);

// MaterialApp(theme: lightTheme, darkTheme: darkTheme, themeMode: ThemeMode.system)
