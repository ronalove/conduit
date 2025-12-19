import 'package:flutter/material.dart';

/// Available theme color options (shadcn-inspired).
enum ThemeColor {
  blue,
  green,
  orange,
  red,
  rose,
  violet,
  yellow,
  zinc,
}

/// Extension for theme color display names.
extension ThemeColorName on ThemeColor {
  String get displayName => switch (this) {
        ThemeColor.blue => 'Blue',
        ThemeColor.green => 'Green',
        ThemeColor.orange => 'Orange',
        ThemeColor.red => 'Red',
        ThemeColor.rose => 'Rose',
        ThemeColor.violet => 'Violet',
        ThemeColor.yellow => 'Yellow',
        ThemeColor.zinc => 'Zinc',
      };
}

/// Color palettes inspired by shadcn/ui for dark theme.
abstract final class ColorPalettes {
  // ==========================================================================
  // BLUE (Default)
  // ==========================================================================
  static const bluePrimary = Color(0xFF3B82F6);
  static const blueSecondary = Color(0xFF1D4ED8);

  // ==========================================================================
  // GREEN
  // ==========================================================================
  static const greenPrimary = Color(0xFF22C55E);
  static const greenSecondary = Color(0xFF16A34A);

  // ==========================================================================
  // ORANGE
  // ==========================================================================
  static const orangePrimary = Color(0xFFF97316);
  static const orangeSecondary = Color(0xFFEA580C);

  // ==========================================================================
  // RED
  // ==========================================================================
  static const redPrimary = Color(0xFFEF4444);
  static const redSecondary = Color(0xFFDC2626);

  // ==========================================================================
  // ROSE
  // ==========================================================================
  static const rosePrimary = Color(0xFFF43F5E);
  static const roseSecondary = Color(0xFFE11D48);

  // ==========================================================================
  // VIOLET
  // ==========================================================================
  static const violetPrimary = Color(0xFF8B5CF6);
  static const violetSecondary = Color(0xFF7C3AED);

  // ==========================================================================
  // YELLOW
  // ==========================================================================
  static const yellowPrimary = Color(0xFFEAB308);
  static const yellowSecondary = Color(0xFFCA8A04);

  // ==========================================================================
  // ZINC (Neutral)
  // ==========================================================================
  static const zincPrimary = Color(0xFF71717A);
  static const zincSecondary = Color(0xFF52525B);

  /// Get primary color for a theme.
  static Color getPrimary(ThemeColor theme) => switch (theme) {
        ThemeColor.blue => bluePrimary,
        ThemeColor.green => greenPrimary,
        ThemeColor.orange => orangePrimary,
        ThemeColor.red => redPrimary,
        ThemeColor.rose => rosePrimary,
        ThemeColor.violet => violetPrimary,
        ThemeColor.yellow => yellowPrimary,
        ThemeColor.zinc => zincPrimary,
      };

  /// Get secondary color for a theme.
  static Color getSecondary(ThemeColor theme) => switch (theme) {
        ThemeColor.blue => blueSecondary,
        ThemeColor.green => greenSecondary,
        ThemeColor.orange => orangeSecondary,
        ThemeColor.red => redSecondary,
        ThemeColor.rose => roseSecondary,
        ThemeColor.violet => violetSecondary,
        ThemeColor.yellow => yellowSecondary,
        ThemeColor.zinc => zincSecondary,
      };

  /// Get all theme colors as a list for UI display.
  static List<ThemeColorOption> get allOptions => ThemeColor.values
      .map((theme) => ThemeColorOption(
            theme: theme,
            primary: getPrimary(theme),
            secondary: getSecondary(theme),
          ))
      .toList();
}

/// A theme color option for display.
class ThemeColorOption {
  const ThemeColorOption({
    required this.theme,
    required this.primary,
    required this.secondary,
  });

  final ThemeColor theme;
  final Color primary;
  final Color secondary;

  String get name => theme.displayName;
}
