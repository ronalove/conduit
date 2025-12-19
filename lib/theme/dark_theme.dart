import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'spacing.dart';
import 'text_styles.dart';

/// Dark theme for Conduit IRC client.
///
/// This is the only theme - no light mode.
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  // ==========================================================================
  // COLOR SCHEME
  // ==========================================================================
  colorScheme: const ColorScheme.dark(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.textInverse,
    primaryContainer: AppColors.primaryVariant,
    onPrimaryContainer: AppColors.textPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.textInverse,
    secondaryContainer: AppColors.secondaryVariant,
    onSecondaryContainer: AppColors.textPrimary,
    error: AppColors.error,
    onError: AppColors.textInverse,
    errorContainer: AppColors.errorVariant,
    onErrorContainer: AppColors.textPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceContainer,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.divider,
    outlineVariant: AppColors.divider,
  ),

  // ==========================================================================
  // SCAFFOLD & BACKGROUNDS
  // ==========================================================================
  scaffoldBackgroundColor: AppColors.background,
  canvasColor: AppColors.surface,
  cardColor: AppColors.surface,
  // dialogBackgroundColor is now set via DialogThemeData
  dividerColor: AppColors.divider,

  // ==========================================================================
  // TEXT THEME
  // ==========================================================================
  textTheme: const TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    displayMedium: AppTextStyles.displayMedium,
    displaySmall: AppTextStyles.displaySmall,
    headlineLarge: AppTextStyles.headlineLarge,
    headlineMedium: AppTextStyles.headlineMedium,
    headlineSmall: AppTextStyles.headlineSmall,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.labelSmall,
  ),

  // ==========================================================================
  // APP BAR
  // ==========================================================================
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: false,
    titleTextStyle: AppTextStyles.headlineMedium,
    toolbarHeight: AppSpacing.appBarHeight,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  ),

  // ==========================================================================
  // BOTTOM NAVIGATION
  // ==========================================================================
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: AppTextStyles.labelSmall,
    unselectedLabelStyle: AppTextStyles.labelSmall,
  ),

  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    indicatorColor: AppColors.primary.withValues(alpha: 0.2),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppTextStyles.labelSmall.copyWith(color: AppColors.primary);
      }
      return AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary);
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.primary, size: 24);
      }
      return const IconThemeData(color: AppColors.textSecondary, size: 24);
    }),
    height: AppSpacing.bottomNavHeight,
  ),

  // ==========================================================================
  // NAVIGATION RAIL (Desktop)
  // ==========================================================================
  navigationRailTheme: NavigationRailThemeData(
    backgroundColor: AppColors.surface,
    selectedIconTheme: const IconThemeData(color: AppColors.primary),
    unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
    selectedLabelTextStyle:
        AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
    unselectedLabelTextStyle:
        AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
    indicatorColor: AppColors.primary.withValues(alpha: 0.2),
  ),

  // ==========================================================================
  // DRAWER
  // ==========================================================================
  drawerTheme: const DrawerThemeData(
    backgroundColor: AppColors.surface,
    scrimColor: Colors.black54,
    elevation: 0,
  ),

  // ==========================================================================
  // CARDS
  // ==========================================================================
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMd,
      side: const BorderSide(color: AppColors.divider, width: 1),
    ),
    margin: EdgeInsets.zero,
  ),

  // ==========================================================================
  // BUTTONS
  // ==========================================================================
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textInverse,
      disabledBackgroundColor: AppColors.surfaceContainer,
      disabledForegroundColor: AppColors.textDisabled,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      minimumSize: const Size(64, AppSpacing.buttonHeightMd),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      textStyle: AppTextStyles.labelLarge,
    ),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textInverse,
      disabledBackgroundColor: AppColors.surfaceContainer,
      disabledForegroundColor: AppColors.textDisabled,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      minimumSize: const Size(64, AppSpacing.buttonHeightMd),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      textStyle: AppTextStyles.labelLarge,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.textDisabled,
      side: const BorderSide(color: AppColors.primary),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      minimumSize: const Size(64, AppSpacing.buttonHeightMd),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      textStyle: AppTextStyles.labelLarge,
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.textDisabled,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      minimumSize: const Size(48, AppSpacing.buttonHeightSm),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      textStyle: AppTextStyles.labelLarge,
    ),
  ),

  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: AppColors.textSecondary,
      disabledForegroundColor: AppColors.textDisabled,
      minimumSize: const Size(40, 40),
      padding: const EdgeInsets.all(AppSpacing.sm),
    ),
  ),

  // ==========================================================================
  // INPUT FIELDS
  // ==========================================================================
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceContainer,
    contentPadding: AppSpacing.inputPadding,
    border: OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusMd,
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusMd,
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusMd,
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusMd,
      borderSide: const BorderSide(color: AppColors.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusMd,
      borderSide: const BorderSide(color: AppColors.error, width: 2),
    ),
    hintStyle: AppTextStyles.inputHint,
    labelStyle: AppTextStyles.bodyMedium,
    errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
    prefixIconColor: AppColors.textSecondary,
    suffixIconColor: AppColors.textSecondary,
  ),

  // ==========================================================================
  // DIALOGS
  // ==========================================================================
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surfaceElevated,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusLg,
    ),
    titleTextStyle: AppTextStyles.headlineMedium,
    contentTextStyle: AppTextStyles.bodyMedium,
  ),

  // ==========================================================================
  // BOTTOM SHEET
  // ==========================================================================
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.surfaceElevated,
    modalBackgroundColor: AppColors.surfaceElevated,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: AppSpacing.radiusXl,
      ),
    ),
    showDragHandle: true,
    dragHandleColor: AppColors.textTertiary,
  ),

  // ==========================================================================
  // SNACK BAR
  // ==========================================================================
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.surfaceElevated,
    contentTextStyle: AppTextStyles.bodyMedium,
    actionTextColor: AppColors.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMd,
    ),
  ),

  // ==========================================================================
  // LISTS
  // ==========================================================================
  listTileTheme: const ListTileThemeData(
    contentPadding: AppSpacing.listItemPadding,
    minVerticalPadding: AppSpacing.sm,
    horizontalTitleGap: AppSpacing.md,
    iconColor: AppColors.textSecondary,
    textColor: AppColors.textPrimary,
    titleTextStyle: AppTextStyles.bodyMedium,
    subtitleTextStyle: AppTextStyles.bodySmall,
    dense: false,
  ),

  // ==========================================================================
  // DIVIDER
  // ==========================================================================
  dividerTheme: const DividerThemeData(
    color: AppColors.divider,
    thickness: 1,
    space: 1,
  ),

  // ==========================================================================
  // CHIPS
  // ==========================================================================
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.surfaceContainer,
    selectedColor: AppColors.primary.withValues(alpha: 0.2),
    disabledColor: AppColors.surfaceContainer,
    labelStyle: AppTextStyles.labelMedium,
    secondaryLabelStyle: AppTextStyles.labelMedium,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusSm,
    ),
    side: BorderSide.none,
  ),

  // ==========================================================================
  // TOOLTIPS
  // ==========================================================================
  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: AppColors.surfaceElevated,
      borderRadius: AppSpacing.borderRadiusSm,
    ),
    textStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
  ),

  // ==========================================================================
  // PROGRESS INDICATORS
  // ==========================================================================
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary,
    linearTrackColor: AppColors.surfaceContainer,
    circularTrackColor: AppColors.surfaceContainer,
  ),

  // ==========================================================================
  // SWITCH
  // ==========================================================================
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return AppColors.textSecondary;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary.withValues(alpha: 0.3);
      }
      return AppColors.surfaceContainer;
    }),
    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
  ),

  // ==========================================================================
  // CHECKBOX
  // ==========================================================================
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(AppColors.textInverse),
    side: const BorderSide(color: AppColors.textSecondary, width: 2),
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusSm,
    ),
  ),

  // ==========================================================================
  // RADIO
  // ==========================================================================
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return AppColors.textSecondary;
    }),
  ),

  // ==========================================================================
  // SCROLLBAR
  // ==========================================================================
  scrollbarTheme: ScrollbarThemeData(
    thumbColor: WidgetStateProperty.all(
      AppColors.textTertiary.withValues(alpha: 0.5),
    ),
    trackColor: WidgetStateProperty.all(Colors.transparent),
    radius: const Radius.circular(4),
    thickness: WidgetStateProperty.all(6),
    thumbVisibility: WidgetStateProperty.all(false),
  ),

  // ==========================================================================
  // TAB BAR
  // ==========================================================================
  tabBarTheme: TabBarThemeData(
    labelColor: AppColors.primary,
    unselectedLabelColor: AppColors.textSecondary,
    labelStyle: AppTextStyles.labelLarge,
    unselectedLabelStyle: AppTextStyles.labelLarge,
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    indicatorSize: TabBarIndicatorSize.label,
    dividerColor: AppColors.divider,
  ),

  // ==========================================================================
  // POPUP MENU
  // ==========================================================================
  popupMenuTheme: PopupMenuThemeData(
    color: AppColors.surfaceElevated,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMd,
    ),
    textStyle: AppTextStyles.bodyMedium,
  ),

  // ==========================================================================
  // DROPDOWN
  // ==========================================================================
  dropdownMenuTheme: DropdownMenuThemeData(
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide.none,
      ),
    ),
    menuStyle: MenuStyle(
      backgroundColor: WidgetStateProperty.all(AppColors.surfaceElevated),
      elevation: WidgetStateProperty.all(4),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ),
    ),
  ),

  // ==========================================================================
  // ICON
  // ==========================================================================
  iconTheme: const IconThemeData(
    color: AppColors.textSecondary,
    size: AppSpacing.iconLg,
  ),

  primaryIconTheme: const IconThemeData(
    color: AppColors.primary,
    size: AppSpacing.iconLg,
  ),

  // ==========================================================================
  // MISC
  // ==========================================================================
  splashColor: AppColors.primary.withValues(alpha: 0.1),
  highlightColor: AppColors.primary.withValues(alpha: 0.05),
  hoverColor: AppColors.primary.withValues(alpha: 0.05),
  focusColor: AppColors.primary.withValues(alpha: 0.1),
);
