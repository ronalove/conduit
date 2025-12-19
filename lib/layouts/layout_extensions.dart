import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Extensions on [BuildContext] for responsive layout helpers.
extension LayoutContextExtensions on BuildContext {
  /// Get the current [DeviceType] based on screen width.
  DeviceType get deviceType => Breakpoints.of(this);

  /// Check if current device is mobile (< 600dp).
  bool get isMobile => Breakpoints.isMobile(this);

  /// Check if current device is tablet (600-1024dp).
  bool get isTablet => Breakpoints.isTablet(this);

  /// Check if current device is desktop (> 1024dp).
  bool get isDesktop => Breakpoints.isDesktop(this);

  /// Check if current device is mobile or tablet.
  bool get isMobileOrTablet => Breakpoints.isMobileOrTablet(this);

  /// Check if current device is tablet or desktop.
  bool get isTabletOrDesktop => Breakpoints.isTabletOrDesktop(this);

  /// Get screen width.
  double get screenWidth => Breakpoints.screenWidth(this);

  /// Get screen height.
  double get screenHeight => Breakpoints.screenHeight(this);

  /// Check if device is in landscape orientation.
  bool get isLandscape => Breakpoints.isLandscape(this);

  /// Check if device is in portrait orientation.
  bool get isPortrait => Breakpoints.isPortrait(this);

  /// Select a value based on device type.
  ///
  /// ```dart
  /// final padding = context.adaptive(
  ///   mobile: 16.0,
  ///   tablet: 24.0,
  ///   desktop: 32.0,
  /// );
  /// ```
  T adaptive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    return switch (deviceType) {
      DeviceType.desktop => desktop ?? tablet ?? mobile,
      DeviceType.tablet => tablet ?? mobile,
      DeviceType.mobile => mobile,
    };
  }

  /// Execute a callback based on device type.
  ///
  /// ```dart
  /// context.onDevice(
  ///   mobile: () => showBottomSheet(),
  ///   desktop: () => showDialog(),
  /// );
  /// ```
  void onDevice({
    VoidCallback? mobile,
    VoidCallback? tablet,
    VoidCallback? desktop,
  }) {
    switch (deviceType) {
      case DeviceType.mobile:
        mobile?.call();
      case DeviceType.tablet:
        (tablet ?? mobile)?.call();
      case DeviceType.desktop:
        (desktop ?? tablet ?? mobile)?.call();
    }
  }
}

/// Extensions on [num] for responsive sizing.
extension ResponsiveSizeExtensions on num {
  /// Scale value based on device type.
  ///
  /// ```dart
  /// final fontSize = 14.scaled(context); // 14 on mobile, 15.4 on tablet, 16.8 on desktop
  /// ```
  double scaled(BuildContext context, {double tabletScale = 1.1, double desktopScale = 1.2}) {
    return switch (context.deviceType) {
      DeviceType.mobile => toDouble(),
      DeviceType.tablet => toDouble() * tabletScale,
      DeviceType.desktop => toDouble() * desktopScale,
    };
  }
}
