import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'color_palettes.dart';
import 'colors.dart';
import 'dark_theme.dart';

/// Key for storing theme color preference.
const _themeColorKey = 'theme_color';

/// Theme state.
class ThemeState {
  const ThemeState({
    this.themeColor = ThemeColor.blue,
  });

  /// Selected theme color.
  final ThemeColor themeColor;

  /// Get the primary color.
  Color get primaryColor => ColorPalettes.getPrimary(themeColor);

  /// Get the secondary color.
  Color get secondaryColor => ColorPalettes.getSecondary(themeColor);

  /// Get the complete ThemeData.
  ThemeData get themeData => createThemeData(themeColor);

  ThemeState copyWith({ThemeColor? themeColor}) {
    return ThemeState(
      themeColor: themeColor ?? this.themeColor,
    );
  }
}

/// Creates a ThemeData with the specified color palette.
ThemeData createThemeData(ThemeColor themeColor) {
  final primary = ColorPalettes.getPrimary(themeColor);
  final secondary = ColorPalettes.getSecondary(themeColor);

  // Start with the base dark theme and override colors
  return darkTheme.copyWith(
    primaryColor: primary,
    colorScheme: darkTheme.colorScheme.copyWith(
      primary: primary,
      secondary: secondary,
      primaryContainer: primary.withValues(alpha: 0.2),
      secondaryContainer: secondary.withValues(alpha: 0.2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: AppColors.textInverse,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: AppColors.textInverse,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: AppColors.textInverse,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return AppColors.textTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary.withValues(alpha: 0.5);
        }
        return AppColors.surfaceContainer;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.textInverse),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return AppColors.textSecondary;
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primary,
      thumbColor: primary,
      inactiveTrackColor: AppColors.surfaceContainer,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
    ),
  );
}

/// Theme provider.
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);

/// Theme notifier.
class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    _loadSavedTheme();
    return const ThemeState();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_themeColorKey);
      if (savedIndex != null && savedIndex < ThemeColor.values.length) {
        state = state.copyWith(themeColor: ThemeColor.values[savedIndex]);
      }
    } catch (_) {
      // Ignore errors, use default theme
    }
  }

  /// Set the theme color.
  Future<void> setThemeColor(ThemeColor color) async {
    state = state.copyWith(themeColor: color);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeColorKey, color.index);
    } catch (_) {
      // Ignore save errors
    }
  }
}
