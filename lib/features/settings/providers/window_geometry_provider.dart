import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences keys for window geometry.
const _windowXKey = 'window_x';
const _windowYKey = 'window_y';
const _windowWidthKey = 'window_width';
const _windowHeightKey = 'window_height';

/// Default window dimensions.
const _defaultWidth = 1280.0;
const _defaultHeight = 720.0;

/// Window geometry state.
class WindowGeometry {
  const WindowGeometry({
    this.x,
    this.y,
    this.width = _defaultWidth,
    this.height = _defaultHeight,
  });

  /// X position of the window (null = center).
  final double? x;

  /// Y position of the window (null = center).
  final double? y;

  /// Width of the window.
  final double width;

  /// Height of the window.
  final double height;

  WindowGeometry copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return WindowGeometry(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

/// Provider for window geometry (only used on desktop platforms).
final windowGeometryProvider =
    NotifierProvider<WindowGeometryNotifier, WindowGeometry>(
  WindowGeometryNotifier.new,
);

/// Notifier for window geometry persistence.
class WindowGeometryNotifier extends Notifier<WindowGeometry> {
  @override
  WindowGeometry build() {
    // Only load on desktop platforms
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      _loadGeometry();
    }
    return const WindowGeometry();
  }

  Future<void> _loadGeometry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final x = prefs.getDouble(_windowXKey);
      final y = prefs.getDouble(_windowYKey);
      final width = prefs.getDouble(_windowWidthKey) ?? _defaultWidth;
      final height = prefs.getDouble(_windowHeightKey) ?? _defaultHeight;

      state = WindowGeometry(
        x: x,
        y: y,
        width: width,
        height: height,
      );
    } catch (_) {
      // Use defaults on error
    }
  }

  /// Save current geometry to SharedPreferences.
  Future<void> saveGeometry({
    required double x,
    required double y,
    required double width,
    required double height,
  }) async {
    state = WindowGeometry(x: x, y: y, width: width, height: height);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_windowXKey, x);
      await prefs.setDouble(_windowYKey, y);
      await prefs.setDouble(_windowWidthKey, width);
      await prefs.setDouble(_windowHeightKey, height);
    } catch (_) {
      // Ignore save errors
    }
  }

  /// Load geometry from SharedPreferences.
  /// Returns the loaded geometry or defaults if not found.
  static Future<WindowGeometry> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final x = prefs.getDouble(_windowXKey);
      final y = prefs.getDouble(_windowYKey);
      final width = prefs.getDouble(_windowWidthKey) ?? _defaultWidth;
      final height = prefs.getDouble(_windowHeightKey) ?? _defaultHeight;

      return WindowGeometry(
        x: x,
        y: y,
        width: width,
        height: height,
      );
    } catch (_) {
      return const WindowGeometry();
    }
  }
}
