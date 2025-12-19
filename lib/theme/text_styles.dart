import 'package:flutter/material.dart';

import 'colors.dart';

/// Text style hierarchy for Conduit.
///
/// Uses system fonts with monospace for IRC content.
abstract final class AppTextStyles {
  // ==========================================================================
  // FONT FAMILIES
  // ==========================================================================

  /// System UI font family.
  static const String fontFamily = '.AppleSystemUIFont';

  /// Monospace font for IRC messages, code.
  static const String monoFamily = 'SF Mono';

  // ==========================================================================
  // DISPLAY STYLES (Large headers)
  // ==========================================================================

  /// Large display text - app title, splash.
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// Medium display text - screen titles.
  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  /// Small display text - section headers.
  static const TextStyle displaySmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ==========================================================================
  // HEADLINE STYLES (Section titles)
  // ==========================================================================

  /// Large headline - dialog titles.
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// Medium headline - card titles.
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// Small headline - list item titles.
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // ==========================================================================
  // BODY STYLES (Main content)
  // ==========================================================================

  /// Large body text - main content.
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Medium body text - standard content.
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Small body text - secondary content.
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // ==========================================================================
  // LABEL STYLES (UI elements)
  // ==========================================================================

  /// Large label - buttons, tabs.
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// Medium label - chips, badges.
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// Small label - captions, hints.
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.4,
    color: AppColors.textTertiary,
  );

  // ==========================================================================
  // IRC-SPECIFIC STYLES
  // ==========================================================================

  /// Nickname in message list.
  static const TextStyle nickname = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// IRC message content.
  static const TextStyle message = TextStyle(
    fontFamily: monoFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Timestamp in messages.
  static const TextStyle timestamp = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.textTertiary,
  );

  /// Channel name in list.
  static const TextStyle channelName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// Channel topic.
  static const TextStyle channelTopic = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// Server notice/status message.
  static const TextStyle serverMessage = TextStyle(
    fontFamily: monoFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// Input field text.
  static const TextStyle input = TextStyle(
    fontFamily: monoFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Input placeholder/hint.
  static const TextStyle inputHint = TextStyle(
    fontFamily: monoFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppColors.textTertiary,
  );

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  /// Create a nickname style with specific color.
  static TextStyle nicknameColored(Color color) {
    return nickname.copyWith(color: color);
  }

  /// Create message style with IRC formatting.
  static TextStyle messageFormatted({
    bool bold = false,
    bool italic = false,
    bool underline = false,
    bool strikethrough = false,
    Color? foreground,
    Color? background,
  }) {
    return message.copyWith(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      decoration: TextDecoration.combine([
        if (underline) TextDecoration.underline,
        if (strikethrough) TextDecoration.lineThrough,
      ]),
      color: foreground ?? AppColors.textPrimary,
      backgroundColor: background,
    );
  }
}
