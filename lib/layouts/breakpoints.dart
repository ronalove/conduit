import 'package:flutter/widgets.dart';

/// Device type based on screen width.
enum DeviceType {
  /// Mobile devices (phones) - width < 600dp
  mobile,

  /// Tablet devices - width 600-1024dp
  tablet,

  /// Desktop devices - width > 1024dp
  desktop,
}

/// Breakpoint definitions for responsive layouts.
///
/// Based on Material Design responsive layout grid.
abstract final class Breakpoints {
  /// Mobile breakpoint threshold (< 600dp).
  static const double mobile = 600;

  /// Tablet breakpoint threshold (600-1024dp).
  static const double tablet = 1024;

  /// Compact width for single-column layouts.
  static const double compact = 600;

  /// Medium width for two-column layouts.
  static const double medium = 840;

  /// Expanded width for three-column layouts.
  static const double expanded = 1200;

  /// Returns the [DeviceType] based on screen width.
  static DeviceType getDeviceType(double width) {
    if (width < mobile) {
      return DeviceType.mobile;
    } else if (width < tablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Returns the [DeviceType] from [BuildContext].
  static DeviceType of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return getDeviceType(width);
  }

  /// Check if current device is mobile.
  static bool isMobile(BuildContext context) {
    return of(context) == DeviceType.mobile;
  }

  /// Check if current device is tablet.
  static bool isTablet(BuildContext context) {
    return of(context) == DeviceType.tablet;
  }

  /// Check if current device is desktop.
  static bool isDesktop(BuildContext context) {
    return of(context) == DeviceType.desktop;
  }

  /// Check if current device is mobile or tablet.
  static bool isMobileOrTablet(BuildContext context) {
    final type = of(context);
    return type == DeviceType.mobile || type == DeviceType.tablet;
  }

  /// Check if current device is tablet or desktop.
  static bool isTabletOrDesktop(BuildContext context) {
    final type = of(context);
    return type == DeviceType.tablet || type == DeviceType.desktop;
  }

  /// Get screen width from context.
  static double screenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  /// Get screen height from context.
  static double screenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  /// Check if device is in landscape orientation.
  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  /// Check if device is in portrait orientation.
  static bool isPortrait(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.portrait;
  }
}
