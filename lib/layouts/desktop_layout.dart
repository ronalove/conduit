import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

/// Desktop layout with 3 columns: channels, chat, users.
///
/// ```
/// ┌─────────────────────────────────────────────────────┐
/// │ [Channels]  │        Chat Area         │  [Users]  │
/// │  Sidebar    │  ┌─────────────────────┐ │  Sidebar  │
/// │             │  │     Messages        │ │           │
/// │  #general   │  │                     │ │  @user1   │
/// │  #random    │  │                     │ │  @user2   │
/// │             │  ├─────────────────────┤ │           │
/// │             │  │   Input + Actions   │ │           │
/// └─────────────┴──┴─────────────────────┴─┴───────────┘
/// ```
class DesktopLayout extends StatefulWidget {
  const DesktopLayout({
    super.key,
    required this.channelsSidebar,
    required this.chatArea,
    required this.usersSidebar,
    this.initialChannelsWidth = AppSpacing.channelListWidth,
    this.initialUsersWidth = AppSpacing.userListWidth,
    this.minSidebarWidth = 180,
    this.maxSidebarWidth = 400,
    this.showChannels = true,
    this.showUsers = true,
    this.onChannelsToggle,
    this.onUsersToggle,
  });

  /// Widget for the channels sidebar (left).
  final Widget channelsSidebar;

  /// Widget for the main chat area (center).
  final Widget chatArea;

  /// Widget for the users sidebar (right).
  final Widget usersSidebar;

  /// Initial width of channels sidebar.
  final double initialChannelsWidth;

  /// Initial width of users sidebar.
  final double initialUsersWidth;

  /// Minimum sidebar width.
  final double minSidebarWidth;

  /// Maximum sidebar width.
  final double maxSidebarWidth;

  /// Whether to show channels sidebar.
  final bool showChannels;

  /// Whether to show users sidebar.
  final bool showUsers;

  /// Callback when channels visibility toggles.
  final ValueChanged<bool>? onChannelsToggle;

  /// Callback when users visibility toggles.
  final ValueChanged<bool>? onUsersToggle;

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  late double _channelsWidth;
  late double _usersWidth;
  late bool _showChannels;
  late bool _showUsers;

  @override
  void initState() {
    super.initState();
    _channelsWidth = widget.initialChannelsWidth;
    _usersWidth = widget.initialUsersWidth;
    _showChannels = widget.showChannels;
    _showUsers = widget.showUsers;
  }

  @override
  void didUpdateWidget(DesktopLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showChannels != oldWidget.showChannels) {
      _showChannels = widget.showChannels;
    }
    if (widget.showUsers != oldWidget.showUsers) {
      _showUsers = widget.showUsers;
    }
  }

  void _toggleChannels() {
    setState(() {
      _showChannels = !_showChannels;
    });
    widget.onChannelsToggle?.call(_showChannels);
  }

  void _toggleUsers() {
    setState(() {
      _showUsers = !_showUsers;
    });
    widget.onUsersToggle?.call(_showUsers);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        // Cmd/Ctrl + B to toggle channels sidebar
        SingleActivator(
          LogicalKeyboardKey.keyB,
          meta: Theme.of(context).platform == TargetPlatform.macOS,
          control: Theme.of(context).platform != TargetPlatform.macOS,
        ): _toggleChannels,
        // Cmd/Ctrl + U to toggle users sidebar
        SingleActivator(
          LogicalKeyboardKey.keyU,
          meta: Theme.of(context).platform == TargetPlatform.macOS,
          control: Theme.of(context).platform != TargetPlatform.macOS,
        ): _toggleUsers,
      },
      child: Focus(
        autofocus: true,
        child: Row(
          children: [
            // Channels sidebar (left)
            if (_showChannels) ...[
              _ResizableSidebar(
                width: _channelsWidth,
                minWidth: widget.minSidebarWidth,
                maxWidth: widget.maxSidebarWidth,
                onWidthChanged: (width) {
                  setState(() => _channelsWidth = width);
                },
                resizeHandlePosition: _ResizeHandlePosition.right,
                child: widget.channelsSidebar,
              ),
            ],

            // Chat area (center)
            Expanded(
              child: widget.chatArea,
            ),

            // Users sidebar (right)
            if (_showUsers) ...[
              _ResizableSidebar(
                width: _usersWidth,
                minWidth: widget.minSidebarWidth,
                maxWidth: widget.maxSidebarWidth,
                onWidthChanged: (width) {
                  setState(() => _usersWidth = width);
                },
                resizeHandlePosition: _ResizeHandlePosition.left,
                child: widget.usersSidebar,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Position of the resize handle.
enum _ResizeHandlePosition { left, right }

/// A sidebar that can be resized by dragging.
class _ResizableSidebar extends StatefulWidget {
  const _ResizableSidebar({
    required this.width,
    required this.minWidth,
    required this.maxWidth,
    required this.onWidthChanged,
    required this.resizeHandlePosition,
    required this.child,
  });

  final double width;
  final double minWidth;
  final double maxWidth;
  final ValueChanged<double> onWidthChanged;
  final _ResizeHandlePosition resizeHandlePosition;
  final Widget child;

  @override
  State<_ResizableSidebar> createState() => _ResizableSidebarState();
}

class _ResizableSidebarState extends State<_ResizableSidebar> {
  bool _isHovering = false;
  bool _isDragging = false;

  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = widget.resizeHandlePosition == _ResizeHandlePosition.right
        ? details.delta.dx
        : -details.delta.dx;

    final newWidth = (widget.width + delta).clamp(
      widget.minWidth,
      widget.maxWidth,
    );

    widget.onWidthChanged(newWidth);
  }

  @override
  Widget build(BuildContext context) {
    final handle = MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragStart: (_) => setState(() => _isDragging = true),
        onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
        onHorizontalDragUpdate: _handleDragUpdate,
        child: Container(
          width: 4,
          color: _isHovering || _isDragging
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.divider,
        ),
      ),
    );

    return SizedBox(
      width: widget.width,
      child: Row(
        children: [
          if (widget.resizeHandlePosition == _ResizeHandlePosition.left) handle,
          Expanded(
            child: Container(
              color: AppColors.surface,
              child: widget.child,
            ),
          ),
          if (widget.resizeHandlePosition == _ResizeHandlePosition.right) handle,
        ],
      ),
    );
  }
}

/// A simple sidebar container with header and content.
class SidebarContainer extends StatelessWidget {
  const SidebarContainer({
    super.key,
    this.header,
    required this.child,
    this.showDivider = true,
  });

  /// Optional header widget (e.g., title, search).
  final Widget? header;

  /// Main content widget.
  final Widget child;

  /// Whether to show divider between header and content.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) ...[
          header!,
          if (showDivider)
            const Divider(height: 1, thickness: 1),
        ],
        Expanded(child: child),
      ],
    );
  }
}

/// Header for a sidebar with title and optional action.
class SidebarHeader extends StatelessWidget {
  const SidebarHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTap,
  });

  /// Header title.
  final String title;

  /// Optional trailing widget (e.g., add button).
  final Widget? trailing;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: AppSpacing.appBarHeight,
        padding: AppSpacing.paddingHorizontalLg,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.headlineMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
