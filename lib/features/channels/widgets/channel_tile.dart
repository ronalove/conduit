import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Type of channel entry.
enum ChannelType {
  /// Public channel (#channel).
  channel,

  /// Private message conversation.
  private,

  /// Server status/notices.
  server,
}

/// A tile representing a channel or PM in the channel list.
class ChannelTile extends StatelessWidget {
  const ChannelTile({
    super.key,
    required this.name,
    this.type = ChannelType.channel,
    this.topic,
    this.unreadCount = 0,
    this.hasMention = false,
    this.isSelected = false,
    this.isAway = false,
    this.onTap,
    this.onLongPress,
    this.onDismissed,
  });

  /// Channel or user name.
  final String name;

  /// Type of channel.
  final ChannelType type;

  /// Channel topic or user status.
  final String? topic;

  /// Number of unread messages.
  final int unreadCount;

  /// Whether there's an unread mention.
  final bool hasMention;

  /// Whether this channel is currently selected.
  final bool isSelected;

  /// Whether the user is away (for PMs).
  final bool isAway;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Called when the tile is long pressed.
  final VoidCallback? onLongPress;

  /// Called when the tile is dismissed (swipe to leave).
  final VoidCallback? onDismissed;

  /// Whether there are unread messages.
  bool get hasUnread => unreadCount > 0 || hasMention;

  @override
  Widget build(BuildContext context) {
    Widget tile = _buildTile(context);

    // Wrap with Dismissible for swipe-to-leave on mobile
    if (onDismissed != null) {
      tile = Dismissible(
        key: ValueKey(name),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismissed!(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          color: AppColors.error,
          child: const Icon(
            Icons.exit_to_app,
            color: AppColors.textPrimary,
          ),
        ),
        child: tile,
      );
    }

    return tile;
  }

  Widget _buildTile(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : null,
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: () => _showContextMenu(context, null),
            borderRadius: AppSpacing.borderRadiusSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  _buildIcon(),
                  AppSpacing.gapSm,
                  Expanded(child: _buildContent()),
                  if (hasUnread) _buildBadge(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset? position) {
    // Only show context menu for channels (not server status)
    if (type == ChannelType.server) return;

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox box = context.findRenderObject() as RenderBox;

    // Use tap position for right-click, or center of tile for long-press
    final Offset menuPosition = position ??
        box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(menuPosition.dx, menuPosition.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        if (type == ChannelType.channel && onDismissed != null)
          PopupMenuItem<String>(
            value: 'leave',
            child: Row(
              children: [
                Icon(Icons.exit_to_app, size: 20, color: AppColors.error),
                const SizedBox(width: AppSpacing.sm),
                Text('Quitter le canal', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
        if (type == ChannelType.private)
          const PopupMenuItem<String>(
            value: 'close',
            child: Row(
              children: [
                Icon(Icons.close, size: 20),
                SizedBox(width: AppSpacing.sm),
                Text('Fermer la conversation'),
              ],
            ),
          ),
      ],
    ).then((value) {
      if (value == 'leave' && onDismissed != null) {
        onDismissed!();
      } else if (value == 'close' && onDismissed != null) {
        onDismissed!();
      }
    });
  }

  Widget _buildIcon() {
    final (icon, color) = switch (type) {
      ChannelType.channel => (
          Icons.tag,
          isSelected
              ? AppColors.primary
              : (hasUnread ? AppColors.textPrimary : AppColors.textSecondary),
        ),
      ChannelType.private => (
          isAway ? Icons.schedule : Icons.person,
          isSelected
              ? AppColors.primary
              : (hasUnread
                  ? AppColors.nickColor(name)
                  : AppColors.textSecondary),
        ),
      ChannelType.server => (
          Icons.dns,
          isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
    };

    return Icon(icon, size: 20, color: color);
  }

  Widget _buildContent() {
    final displayName = switch (type) {
      ChannelType.channel =>
        name.startsWith('#') ? name.substring(1) : name,
      ChannelType.private =>
        name.startsWith('@') ? name.substring(1) : name,
      ChannelType.server => name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayName,
          style: AppTextStyles.channelName.copyWith(
            color: isSelected
                ? AppColors.primary
                : (hasUnread ? AppColors.textPrimary : AppColors.textSecondary),
            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (topic != null && topic!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            topic!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildBadge() {
    if (hasMention) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        child: Text(
          '@',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (unreadCount > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        constraints: const BoxConstraints(minWidth: 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        child: Text(
          unreadCount > 99 ? '99+' : '$unreadCount',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textInverse,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Section header for channel list.
class ChannelSectionHeader extends StatelessWidget {
  const ChannelSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTap,
  });

  /// Section title.
  final String title;

  /// Optional trailing widget.
  final Widget? trailing;

  /// Called when header is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
