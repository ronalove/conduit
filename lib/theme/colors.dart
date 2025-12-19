import 'package:flutter/material.dart';

/// Conduit color palette for dark theme.
///
/// Color naming follows Material Design conventions with IRC-specific additions.
abstract final class AppColors {
  // ==========================================================================
  // BACKGROUND LEVELS
  // ==========================================================================

  /// Darkest background, used for the main scaffold.
  static const Color background = Color(0xFF0D0D0D);

  /// Surface color for cards and elevated containers.
  static const Color surface = Color(0xFF1A1A1A);

  /// Elevated surface for modals, dropdowns, tooltips.
  static const Color surfaceElevated = Color(0xFF242424);

  /// Container background for input fields, list items.
  static const Color surfaceContainer = Color(0xFF2A2A2A);

  /// Subtle divider/border color.
  static const Color divider = Color(0xFF3A3A3A);

  // ==========================================================================
  // TEXT COLORS
  // ==========================================================================

  /// Primary text color - high emphasis.
  static const Color textPrimary = Color(0xFFE8E8E8);

  /// Secondary text color - medium emphasis.
  static const Color textSecondary = Color(0xFFA0A0A0);

  /// Tertiary text color - low emphasis, hints.
  static const Color textTertiary = Color(0xFF707070);

  /// Disabled text color.
  static const Color textDisabled = Color(0xFF505050);

  /// Inverse text (for light backgrounds).
  static const Color textInverse = Color(0xFF0D0D0D);

  // ==========================================================================
  // ACCENT COLORS
  // ==========================================================================

  /// Primary accent color - teal/cyan for IRC feel.
  static const Color primary = Color(0xFF00BFA5);

  /// Primary variant for hover/pressed states.
  static const Color primaryVariant = Color(0xFF00897B);

  /// Secondary accent - purple for mentions, highlights.
  static const Color secondary = Color(0xFF7C4DFF);

  /// Secondary variant.
  static const Color secondaryVariant = Color(0xFF651FFF);

  // ==========================================================================
  // SEMANTIC COLORS
  // ==========================================================================

  /// Error color - for errors, kicks, bans.
  static const Color error = Color(0xFFEF5350);

  /// Error variant.
  static const Color errorVariant = Color(0xFFD32F2F);

  /// Success color - for joins, connections.
  static const Color success = Color(0xFF66BB6A);

  /// Success variant.
  static const Color successVariant = Color(0xFF43A047);

  /// Warning color - for warnings, away status.
  static const Color warning = Color(0xFFFFA726);

  /// Warning variant.
  static const Color warningVariant = Color(0xFFFB8C00);

  /// Info color - for notices, server messages.
  static const Color info = Color(0xFF42A5F5);

  /// Info variant.
  static const Color infoVariant = Color(0xFF1E88E5);

  // ==========================================================================
  // IRC-SPECIFIC COLORS
  // ==========================================================================

  /// Operator color (@ prefix).
  static const Color operator = Color(0xFFFFD54F);

  /// Voice color (+ prefix).
  static const Color voice = Color(0xFF81C784);

  /// Own nickname highlight.
  static const Color selfNick = Color(0xFF00BFA5);

  /// Mention highlight background.
  static const Color mentionBackground = Color(0x33651FFF);

  /// Unread indicator.
  static const Color unread = Color(0xFF00BFA5);

  /// Activity indicator (new messages).
  static const Color activity = Color(0xFFFFD54F);

  // ==========================================================================
  // IRC 16-COLOR PALETTE (mIRC compatible)
  // ==========================================================================

  /// Standard IRC colors for formatting (mIRC color codes 0-15).
  static const List<Color> ircColors = [
    Color(0xFFFFFFFF), // 0  - White
    Color(0xFF000000), // 1  - Black
    Color(0xFF00007F), // 2  - Navy Blue
    Color(0xFF009300), // 3  - Green
    Color(0xFFFF0000), // 4  - Red
    Color(0xFF7F0000), // 5  - Brown/Maroon
    Color(0xFF9C009C), // 6  - Purple
    Color(0xFFFC7F00), // 7  - Orange
    Color(0xFFFFFF00), // 8  - Yellow
    Color(0xFF00FC00), // 9  - Light Green
    Color(0xFF009393), // 10 - Cyan/Teal
    Color(0xFF00FFFF), // 11 - Light Cyan
    Color(0xFF0000FC), // 12 - Light Blue
    Color(0xFFFF00FF), // 13 - Pink/Magenta
    Color(0xFF7F7F7F), // 14 - Grey
    Color(0xFFD2D2D2), // 15 - Light Grey
  ];

  /// Get IRC color by code (0-15).
  static Color getIrcColor(int code) {
    if (code < 0 || code >= ircColors.length) {
      return textPrimary;
    }
    return ircColors[code];
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  /// Generate a consistent color for a nickname.
  static Color nickColor(String nickname) {
    if (nickname.isEmpty) return textPrimary;

    // Hash the nickname to get a consistent index
    var hash = 0;
    for (var i = 0; i < nickname.length; i++) {
      hash = nickname.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Use a curated palette of distinguishable colors
    const nickColors = [
      Color(0xFF00BFA5), // Teal
      Color(0xFF7C4DFF), // Purple
      Color(0xFFFF7043), // Deep Orange
      Color(0xFF42A5F5), // Blue
      Color(0xFFAB47BC), // Purple
      Color(0xFF26A69A), // Teal
      Color(0xFFEC407A), // Pink
      Color(0xFF66BB6A), // Green
      Color(0xFFFFA726), // Orange
      Color(0xFF5C6BC0), // Indigo
      Color(0xFFEF5350), // Red
      Color(0xFF29B6F6), // Light Blue
    ];

    return nickColors[hash.abs() % nickColors.length];
  }
}
