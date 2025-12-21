import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../theme/theme.dart';

/// Custom window title bar for desktop platforms.
/// Provides drag area and window controls (minimize, maximize, close).
class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({
    super.key,
    this.title,
    this.leading,
  });

  /// Optional title to display.
  final String? title;

  /// Optional leading widget (e.g., app icon).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    // macOS uses native title bar with hidden style, no custom bar needed
    if (Platform.isMacOS) {
      return const SizedBox.shrink();
    }

    // Only show on Windows/Linux
    if (!Platform.isWindows && !Platform.isLinux) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 32,
      color: AppColors.surface,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 8),
          ],
          // Draggable area with optional title
          Expanded(
            child: DragToMoveArea(
              child: title != null
                  ? Center(
                      child: Text(
                        title!,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // Windows/Linux buttons on the right
          const _WindowsWindowButtons(),
        ],
      ),
    );
  }
}

/// Windows-style window buttons.
class _WindowsWindowButtons extends StatelessWidget {
  const _WindowsWindowButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _WindowButton(
          icon: Icons.remove,
          onPressed: () => windowManager.minimize(),
          hoverColor: AppColors.surfaceElevated,
        ),
        _MaximizeButton(),
        _WindowButton(
          icon: Icons.close,
          onPressed: () => windowManager.close(),
          hoverColor: const Color(0xFFE81123),
          hoverIconColor: Colors.white,
        ),
      ],
    );
  }
}

/// Maximize/restore button that changes icon based on window state.
class _MaximizeButton extends StatefulWidget {
  @override
  State<_MaximizeButton> createState() => _MaximizeButtonState();
}

class _MaximizeButtonState extends State<_MaximizeButton> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _updateMaximizedState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _updateMaximizedState() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted && isMaximized != _isMaximized) {
      setState(() => _isMaximized = isMaximized);
    }
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    return _WindowButton(
      icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
      iconSize: _isMaximized ? 14 : 18,
      onPressed: () async {
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      hoverColor: AppColors.surfaceElevated,
    );
  }
}

/// A single window control button.
class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.onPressed,
    required this.hoverColor,
    this.hoverIconColor,
    this.iconSize = 18,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color hoverColor;
  final Color? hoverIconColor;
  final double iconSize;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 32,
          color: _isHovering ? widget.hoverColor : Colors.transparent,
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: _isHovering && widget.hoverIconColor != null
                ? widget.hoverIconColor
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
