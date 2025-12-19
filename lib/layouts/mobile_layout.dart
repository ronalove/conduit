import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Mobile layout navigation destinations.
enum MobileDestination {
  channels,
  chat,
  users,
  settings,
}

/// Mobile layout with bottom navigation.
///
/// ```
/// ┌───────────────────┐
/// │   Channel Name    │  <- App Bar
/// ├───────────────────┤
/// │                   │
/// │    Messages       │  <- Scrollable
/// │                   │
/// ├───────────────────┤
/// │  Input + Send     │  <- Bottom input
/// ├───────────────────┤
/// │ Channels │ Users  │  <- Bottom nav
/// └───────────────────┘
/// ```
class MobileLayout extends StatefulWidget {
  const MobileLayout({
    super.key,
    required this.channelsPage,
    required this.chatPage,
    required this.usersPage,
    this.settingsPage,
    this.initialDestination = MobileDestination.chat,
    this.onDestinationChanged,
    this.showLabels = true,
  });

  /// Widget for channels list page.
  final Widget channelsPage;

  /// Widget for chat page.
  final Widget chatPage;

  /// Widget for users list page.
  final Widget usersPage;

  /// Optional settings page.
  final Widget? settingsPage;

  /// Initial selected destination.
  final MobileDestination initialDestination;

  /// Callback when destination changes.
  final ValueChanged<MobileDestination>? onDestinationChanged;

  /// Whether to show labels in bottom nav.
  final bool showLabels;

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  late MobileDestination _currentDestination;

  @override
  void initState() {
    super.initState();
    _currentDestination = widget.initialDestination;
  }

  void _onDestinationSelected(int index) {
    final destination = MobileDestination.values[index];
    setState(() {
      _currentDestination = destination;
    });
    widget.onDestinationChanged?.call(destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentDestination.index,
        children: [
          widget.channelsPage,
          widget.chatPage,
          widget.usersPage,
          if (widget.settingsPage != null) widget.settingsPage!,
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentDestination.index,
        onDestinationSelected: _onDestinationSelected,
        labelBehavior: widget.showLabels
            ? NavigationDestinationLabelBehavior.alwaysShow
            : NavigationDestinationLabelBehavior.alwaysHide,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.tag_outlined),
            selectedIcon: Icon(Icons.tag),
            label: 'Channels',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          if (widget.settingsPage != null)
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
        ],
      ),
    );
  }
}

/// Mobile page scaffold with app bar and optional bottom input.
class MobilePageScaffold extends StatelessWidget {
  const MobilePageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.leading,
    this.actions,
    this.bottomInput,
    this.onRefresh,
    this.floatingActionButton,
  });

  /// Page title.
  final String title;

  /// Optional subtitle (e.g., channel topic).
  final String? subtitle;

  /// Page body content.
  final Widget body;

  /// Optional leading widget in app bar.
  final Widget? leading;

  /// Optional action widgets in app bar.
  final List<Widget>? actions;

  /// Optional bottom input widget.
  final Widget? bottomInput;

  /// Optional refresh callback for pull-to-refresh.
  final Future<void> Function()? onRefresh;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: leading,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (subtitle != null)
              Text(
                subtitle!,
                style: AppTextStyles.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: actions,
      ),
      body: Column(
        children: [
          Expanded(child: content),
          if (bottomInput != null) bottomInput!,
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Mobile chat input bar.
class MobileChatInput extends StatefulWidget {
  const MobileChatInput({
    super.key,
    required this.onSend,
    this.placeholder = 'Type a message...',
    this.onAttachment,
    this.enabled = true,
  });

  /// Callback when message is sent.
  final ValueChanged<String> onSend;

  /// Input placeholder text.
  final String placeholder;

  /// Optional callback for attachment button.
  final VoidCallback? onAttachment;

  /// Whether the input is enabled.
  final bool enabled;

  @override
  State<MobileChatInput> createState() => _MobileChatInputState();
}

class _MobileChatInputState extends State<MobileChatInput> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (widget.onAttachment != null)
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: widget.enabled ? widget.onAttachment : null,
                color: AppColors.textSecondary,
              ),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _onSend(),
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusFull,
                    borderSide: BorderSide.none,
                  ),
                ),
                minLines: 1,
                maxLines: 4,
              ),
            ),
            AppSpacing.gapXs,
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: widget.enabled && _hasText ? _onSend : null,
              color: _hasText ? AppColors.primary : AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mobile drawer for alternative navigation.
class MobileDrawer extends StatelessWidget {
  const MobileDrawer({
    super.key,
    this.header,
    required this.channels,
    this.selectedChannel,
    this.onChannelTap,
    this.onSettingsTap,
  });

  /// Optional header widget (e.g., server info).
  final Widget? header;

  /// List of channel names.
  final List<String> channels;

  /// Currently selected channel.
  final String? selectedChannel;

  /// Callback when channel is tapped.
  final ValueChanged<String>? onChannelTap;

  /// Callback when settings is tapped.
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            if (header != null) header!,
            Expanded(
              child: ListView.builder(
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  final channel = channels[index];
                  final isSelected = channel == selectedChannel;

                  return ListTile(
                    leading: Icon(
                      Icons.tag,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      channel.startsWith('#') ? channel.substring(1) : channel,
                      style: AppTextStyles.channelName.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                    onTap: () {
                      onChannelTap?.call(channel);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.textSecondary),
              title: Text('Settings', style: AppTextStyles.bodyMedium),
              onTap: () {
                Navigator.of(context).pop();
                onSettingsTap?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Swipeable container for gesture-based navigation.
class SwipeableContainer extends StatelessWidget {
  const SwipeableContainer({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.swipeThreshold = 50.0,
  });

  /// Child widget.
  final Widget child;

  /// Callback when swiped left.
  final VoidCallback? onSwipeLeft;

  /// Callback when swiped right.
  final VoidCallback? onSwipeRight;

  /// Minimum swipe distance to trigger callback.
  final double swipeThreshold;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > swipeThreshold && onSwipeRight != null) {
          onSwipeRight!();
        } else if (velocity < -swipeThreshold && onSwipeLeft != null) {
          onSwipeLeft!();
        }
      },
      child: child,
    );
  }
}
