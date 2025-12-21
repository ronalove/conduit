import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

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
    // macOS uses native title bar, no custom bar needed
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
            child: MoveWindow(
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

/// macOS-style window buttons (close, minimize, maximize).
class _MacOSWindowButtons extends StatelessWidget {
  const _MacOSWindowButtons();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          _MacButton(
            color: const Color(0xFFFF5F57),
            onPressed: () => appWindow.close(),
          ),
          const SizedBox(width: 8),
          _MacButton(
            color: const Color(0xFFFEBC2E),
            onPressed: () => appWindow.minimize(),
          ),
          const SizedBox(width: 8),
          _MacButton(
            color: const Color(0xFF28C840),
            onPressed: () => appWindow.maximizeOrRestore(),
          ),
        ],
      ),
    );
  }
}

/// A single macOS-style button.
class _MacButton extends StatefulWidget {
  const _MacButton({
    required this.color,
    required this.onPressed,
  });

  final Color color;
  final VoidCallback onPressed;

  @override
  State<_MacButton> createState() => _MacButtonState();
}

class _MacButtonState extends State<_MacButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: _isHovering
              ? Icon(
                  widget.color == const Color(0xFFFF5F57)
                      ? Icons.close
                      : widget.color == const Color(0xFFFEBC2E)
                          ? Icons.remove
                          : Icons.crop_square,
                  size: 8,
                  color: Colors.black.withValues(alpha: 0.6),
                )
              : null,
        ),
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
        MinimizeWindowButton(colors: _windowButtonColors),
        MaximizeWindowButton(colors: _windowButtonColors),
        CloseWindowButton(colors: _closeButtonColors),
      ],
    );
  }
}

final _windowButtonColors = WindowButtonColors(
  iconNormal: AppColors.textSecondary,
  mouseOver: AppColors.surface.withValues(alpha: 0.1),
  mouseDown: AppColors.surface.withValues(alpha: 0.2),
  iconMouseOver: AppColors.textPrimary,
  iconMouseDown: AppColors.textPrimary,
);

final _closeButtonColors = WindowButtonColors(
  iconNormal: AppColors.textSecondary,
  mouseOver: const Color(0xFFE81123),
  mouseDown: const Color(0xFFB71C1C),
  iconMouseOver: Colors.white,
  iconMouseDown: Colors.white,
);
