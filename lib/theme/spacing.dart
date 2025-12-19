import 'package:flutter/material.dart';

/// Consistent spacing scale for Conduit.
///
/// Based on 4dp base unit for visual rhythm.
abstract final class AppSpacing {
  // ==========================================================================
  // BASE SPACING SCALE (4dp increments)
  // ==========================================================================

  /// 2dp - Micro spacing, icon padding.
  static const double xxs = 2;

  /// 4dp - Tight spacing, inline elements.
  static const double xs = 4;

  /// 8dp - Small spacing, related elements.
  static const double sm = 8;

  /// 12dp - Medium-small spacing.
  static const double md = 12;

  /// 16dp - Standard spacing, sections.
  static const double lg = 16;

  /// 20dp - Medium-large spacing.
  static const double xl = 20;

  /// 24dp - Large spacing, major sections.
  static const double xxl = 24;

  /// 32dp - Extra large spacing.
  static const double xxxl = 32;

  /// 48dp - Huge spacing, page margins.
  static const double huge = 48;

  // ==========================================================================
  // COMMON PADDING PRESETS
  // ==========================================================================

  /// No padding.
  static const EdgeInsets none = EdgeInsets.zero;

  /// Tight padding all around (4dp).
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);

  /// Small padding all around (8dp).
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);

  /// Medium padding all around (12dp).
  static const EdgeInsets paddingMd = EdgeInsets.all(md);

  /// Standard padding all around (16dp).
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);

  /// Large padding all around (24dp).
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  // ==========================================================================
  // HORIZONTAL PADDING PRESETS
  // ==========================================================================

  /// Horizontal padding (8dp).
  static const EdgeInsets paddingHorizontalSm =
      EdgeInsets.symmetric(horizontal: sm);

  /// Horizontal padding (16dp).
  static const EdgeInsets paddingHorizontalLg =
      EdgeInsets.symmetric(horizontal: lg);

  /// Horizontal padding (24dp).
  static const EdgeInsets paddingHorizontalXxl =
      EdgeInsets.symmetric(horizontal: xxl);

  // ==========================================================================
  // VERTICAL PADDING PRESETS
  // ==========================================================================

  /// Vertical padding (8dp).
  static const EdgeInsets paddingVerticalSm =
      EdgeInsets.symmetric(vertical: sm);

  /// Vertical padding (16dp).
  static const EdgeInsets paddingVerticalLg =
      EdgeInsets.symmetric(vertical: lg);

  // ==========================================================================
  // COMPONENT-SPECIFIC SPACING
  // ==========================================================================

  /// Message bubble padding.
  static const EdgeInsets messagePadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  /// List item padding.
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Card content padding.
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  /// Input field content padding.
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  /// Dialog content padding.
  static const EdgeInsets dialogPadding = EdgeInsets.all(xxl);

  /// Screen edge padding.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );

  // ==========================================================================
  // GAP WIDGETS (for Row/Column spacing)
  // ==========================================================================

  /// Horizontal gap 4dp.
  static const SizedBox gapXs = SizedBox(width: xs);

  /// Horizontal gap 8dp.
  static const SizedBox gapSm = SizedBox(width: sm);

  /// Horizontal gap 12dp.
  static const SizedBox gapMd = SizedBox(width: md);

  /// Horizontal gap 16dp.
  static const SizedBox gapLg = SizedBox(width: lg);

  /// Vertical gap 4dp.
  static const SizedBox gapVerticalXs = SizedBox(height: xs);

  /// Vertical gap 8dp.
  static const SizedBox gapVerticalSm = SizedBox(height: sm);

  /// Vertical gap 12dp.
  static const SizedBox gapVerticalMd = SizedBox(height: md);

  /// Vertical gap 16dp.
  static const SizedBox gapVerticalLg = SizedBox(height: lg);

  /// Vertical gap 24dp.
  static const SizedBox gapVerticalXxl = SizedBox(height: xxl);

  // ==========================================================================
  // BORDER RADIUS
  // ==========================================================================

  /// Small radius (4dp) - chips, badges.
  static const Radius radiusSm = Radius.circular(xs);

  /// Medium radius (8dp) - cards, buttons.
  static const Radius radiusMd = Radius.circular(sm);

  /// Large radius (12dp) - dialogs, modals.
  static const Radius radiusLg = Radius.circular(md);

  /// Extra large radius (16dp) - bottom sheets.
  static const Radius radiusXl = Radius.circular(lg);

  /// Full round (circular).
  static const Radius radiusFull = Radius.circular(999);

  /// Small border radius.
  static const BorderRadius borderRadiusSm = BorderRadius.all(radiusSm);

  /// Medium border radius.
  static const BorderRadius borderRadiusMd = BorderRadius.all(radiusMd);

  /// Large border radius.
  static const BorderRadius borderRadiusLg = BorderRadius.all(radiusLg);

  /// Extra large border radius.
  static const BorderRadius borderRadiusXl = BorderRadius.all(radiusXl);

  /// Full circular border radius.
  static const BorderRadius borderRadiusFull = BorderRadius.all(radiusFull);

  // ==========================================================================
  // COMPONENT SIZES
  // ==========================================================================

  /// Avatar size - small (24dp).
  static const double avatarSm = 24;

  /// Avatar size - medium (32dp).
  static const double avatarMd = 32;

  /// Avatar size - large (40dp).
  static const double avatarLg = 40;

  /// Icon size - small (16dp).
  static const double iconSm = 16;

  /// Icon size - medium (20dp).
  static const double iconMd = 20;

  /// Icon size - large (24dp).
  static const double iconLg = 24;

  /// Button height - small (32dp).
  static const double buttonHeightSm = 32;

  /// Button height - medium (40dp).
  static const double buttonHeightMd = 40;

  /// Button height - large (48dp).
  static const double buttonHeightLg = 48;

  /// Input height (48dp).
  static const double inputHeight = 48;

  /// App bar height (56dp).
  static const double appBarHeight = 56;

  /// Bottom nav height (64dp).
  static const double bottomNavHeight = 64;

  /// Channel list width - desktop (240dp).
  static const double channelListWidth = 240;

  /// User list width - desktop (200dp).
  static const double userListWidth = 200;
}
