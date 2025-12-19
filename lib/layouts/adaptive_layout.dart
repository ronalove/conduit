import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// A widget that builds different layouts based on screen size.
///
/// Provides three slots for mobile, tablet, and desktop layouts.
/// Falls back to smaller layouts if larger ones are not provided.
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Builder for mobile layout (< 600dp).
  /// Always required as the fallback.
  final Widget mobile;

  /// Builder for tablet layout (600-1024dp).
  /// Falls back to [mobile] if not provided.
  final Widget? tablet;

  /// Builder for desktop layout (> 1024dp).
  /// Falls back to [tablet] or [mobile] if not provided.
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = Breakpoints.getDeviceType(constraints.maxWidth);

        return switch (deviceType) {
          DeviceType.desktop => desktop ?? tablet ?? mobile,
          DeviceType.tablet => tablet ?? mobile,
          DeviceType.mobile => mobile,
        };
      },
    );
  }
}

/// A widget that builds different layouts using builder functions.
///
/// Similar to [AdaptiveLayout] but uses builder functions that receive
/// the [BuildContext] and [BoxConstraints].
class AdaptiveBuilder extends StatelessWidget {
  const AdaptiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Builder for mobile layout (< 600dp).
  final Widget Function(BuildContext context, BoxConstraints constraints)
      mobile;

  /// Builder for tablet layout (600-1024dp).
  final Widget Function(BuildContext context, BoxConstraints constraints)?
      tablet;

  /// Builder for desktop layout (> 1024dp).
  final Widget Function(BuildContext context, BoxConstraints constraints)?
      desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = Breakpoints.getDeviceType(constraints.maxWidth);

        final builder = switch (deviceType) {
          DeviceType.desktop => desktop ?? tablet ?? mobile,
          DeviceType.tablet => tablet ?? mobile,
          DeviceType.mobile => mobile,
        };

        return builder(context, constraints);
      },
    );
  }
}

/// A widget that shows/hides content based on device type.
class AdaptiveVisibility extends StatelessWidget {
  const AdaptiveVisibility({
    super.key,
    required this.child,
    this.visibleOnMobile = true,
    this.visibleOnTablet = true,
    this.visibleOnDesktop = true,
    this.replacement,
  });

  /// The widget to conditionally show.
  final Widget child;

  /// Whether to show on mobile devices.
  final bool visibleOnMobile;

  /// Whether to show on tablet devices.
  final bool visibleOnTablet;

  /// Whether to show on desktop devices.
  final bool visibleOnDesktop;

  /// Widget to show when [child] is hidden.
  /// Defaults to [SizedBox.shrink].
  final Widget? replacement;

  /// Show only on mobile.
  const AdaptiveVisibility.mobileOnly({
    super.key,
    required this.child,
    this.replacement,
  })  : visibleOnMobile = true,
        visibleOnTablet = false,
        visibleOnDesktop = false;

  /// Show only on tablet.
  const AdaptiveVisibility.tabletOnly({
    super.key,
    required this.child,
    this.replacement,
  })  : visibleOnMobile = false,
        visibleOnTablet = true,
        visibleOnDesktop = false;

  /// Show only on desktop.
  const AdaptiveVisibility.desktopOnly({
    super.key,
    required this.child,
    this.replacement,
  })  : visibleOnMobile = false,
        visibleOnTablet = false,
        visibleOnDesktop = true;

  /// Show on tablet and desktop (not mobile).
  const AdaptiveVisibility.tabletAndDesktop({
    super.key,
    required this.child,
    this.replacement,
  })  : visibleOnMobile = false,
        visibleOnTablet = true,
        visibleOnDesktop = true;

  /// Show on mobile and tablet (not desktop).
  const AdaptiveVisibility.mobileAndTablet({
    super.key,
    required this.child,
    this.replacement,
  })  : visibleOnMobile = true,
        visibleOnTablet = true,
        visibleOnDesktop = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = Breakpoints.getDeviceType(constraints.maxWidth);

        final isVisible = switch (deviceType) {
          DeviceType.mobile => visibleOnMobile,
          DeviceType.tablet => visibleOnTablet,
          DeviceType.desktop => visibleOnDesktop,
        };

        if (isVisible) {
          return child;
        }

        return replacement ?? const SizedBox.shrink();
      },
    );
  }
}

/// A widget that provides adaptive padding based on device type.
class AdaptivePadding extends StatelessWidget {
  const AdaptivePadding({
    super.key,
    required this.child,
    this.mobilePadding = EdgeInsets.zero,
    this.tabletPadding,
    this.desktopPadding,
  });

  /// The child widget.
  final Widget child;

  /// Padding for mobile devices.
  final EdgeInsetsGeometry mobilePadding;

  /// Padding for tablet devices. Falls back to [mobilePadding].
  final EdgeInsetsGeometry? tabletPadding;

  /// Padding for desktop devices. Falls back to [tabletPadding] or [mobilePadding].
  final EdgeInsetsGeometry? desktopPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = Breakpoints.getDeviceType(constraints.maxWidth);

        final padding = switch (deviceType) {
          DeviceType.desktop => desktopPadding ?? tabletPadding ?? mobilePadding,
          DeviceType.tablet => tabletPadding ?? mobilePadding,
          DeviceType.mobile => mobilePadding,
        };

        return Padding(
          padding: padding,
          child: child,
        );
      },
    );
  }
}

/// A widget that switches between Row and Column based on device type.
class AdaptiveDirection extends StatelessWidget {
  const AdaptiveDirection({
    super.key,
    required this.children,
    this.useRowOnMobile = false,
    this.useRowOnTablet = true,
    this.useRowOnDesktop = true,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing = 0,
  });

  /// The children widgets.
  final List<Widget> children;

  /// Use Row on mobile devices.
  final bool useRowOnMobile;

  /// Use Row on tablet devices.
  final bool useRowOnTablet;

  /// Use Row on desktop devices.
  final bool useRowOnDesktop;

  /// Main axis alignment for both Row and Column.
  final MainAxisAlignment mainAxisAlignment;

  /// Cross axis alignment for both Row and Column.
  final CrossAxisAlignment crossAxisAlignment;

  /// Main axis size for both Row and Column.
  final MainAxisSize mainAxisSize;

  /// Spacing between children (uses gap).
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = Breakpoints.getDeviceType(constraints.maxWidth);

        final useRow = switch (deviceType) {
          DeviceType.mobile => useRowOnMobile,
          DeviceType.tablet => useRowOnTablet,
          DeviceType.desktop => useRowOnDesktop,
        };

        final spacedChildren = _buildSpacedChildren(useRow);

        if (useRow) {
          return Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: spacedChildren,
          );
        }

        return Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: spacedChildren,
        );
      },
    );
  }

  List<Widget> _buildSpacedChildren(bool useRow) {
    if (spacing == 0 || children.isEmpty) {
      return children;
    }

    final spacer = useRow
        ? SizedBox(width: spacing)
        : SizedBox(height: spacing);

    return [
      for (int i = 0; i < children.length; i++) ...[
        children[i],
        if (i < children.length - 1) spacer,
      ],
    ];
  }
}
