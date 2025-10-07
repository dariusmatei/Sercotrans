import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Breakpoints inspirate din tool-urile enterprise (mobile/tablet/desktop)
class AppBreakpoints {
  static const double tablet = 768;
  static const double desktop = 1024;
}

class AppTheme {
  static const _seed = Color(0xFF2563EB); // albastru „productivity”
  static final _text = GoogleFonts.interTextTheme();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _text,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
      cardTheme: const CardTheme(
        elevation: 1,
        margin: EdgeInsets.all(12),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        selectedLabelTextStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _text,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
