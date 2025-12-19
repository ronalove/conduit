import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../widgets/channel_tile.dart';

/// Screen displaying the list of channels and PMs.
class ChannelListScreen extends StatelessWidget {
  const ChannelListScreen({
    super.key,
    required this.channels,
    required this.privateMessages,
    this.selectedChannel,
    this.onChannelTap,
    this.onChannelLongPress,
    this.onLeaveChannel,
    this.onAddChannel,
    this.showServerStatus = true,
    this.serverName,
  });

  /// List of joined channels.
  final List<ChannelInfo> channels;

  /// List of private message conversations.
  final List<PrivateMessageInfo> privateMessages;

  /// Currently selected channel/PM name.
  final String? selectedChannel;

  /// Called when a channel is tapped.
  final void Function(String name, ChannelType type)? onChannelTap;

  /// Called when a channel is long pressed.
  final void Function(String name, ChannelType type)? onChannelLongPress;

  /// Called when user swipes to leave a channel.
  final void Function(String name)? onLeaveChannel;

  /// Called when add channel button is pressed.
  final VoidCallback? onAddChannel;

  /// Whether to show server status at top.
  final bool showServerStatus;

  /// Server name for status display.
  final String? serverName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        _buildHeader(context),
        const Divider(height: 1),

        // Channel list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            children: [
              // Server status
              if (showServerStatus && serverName != null) ...[
                ChannelTile(
                  name: serverName!,
                  type: ChannelType.server,
                  topic: 'Connected',
                  isSelected: selectedChannel == serverName,
                  onTap: () => onChannelTap?.call(serverName!, ChannelType.server),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Channels section
              if (channels.isNotEmpty) ...[
                ChannelSectionHeader(
                  title: 'Channels',
                  trailing: Text(
                    '${channels.length}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                ...channels.map((channel) => ChannelTile(
                      name: channel.name,
                      type: ChannelType.channel,
                      topic: channel.topic,
                      unreadCount: channel.unreadCount,
                      hasMention: channel.hasMention,
                      isSelected: selectedChannel == channel.name,
                      onTap: () => onChannelTap?.call(channel.name, ChannelType.channel),
                      onLongPress: () =>
                          onChannelLongPress?.call(channel.name, ChannelType.channel),
                      onDismissed:
                          onLeaveChannel != null ? () => onLeaveChannel!(channel.name) : null,
                    )),
                const SizedBox(height: AppSpacing.md),
              ],

              // Private messages section
              if (privateMessages.isNotEmpty) ...[
                ChannelSectionHeader(
                  title: 'Direct Messages',
                  trailing: Text(
                    '${privateMessages.length}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                ...privateMessages.map((pm) => ChannelTile(
                      name: pm.nickname,
                      type: ChannelType.private,
                      unreadCount: pm.unreadCount,
                      hasMention: pm.hasMention,
                      isAway: pm.isAway,
                      isSelected: selectedChannel == pm.nickname,
                      onTap: () => onChannelTap?.call(pm.nickname, ChannelType.private),
                      onLongPress: () =>
                          onChannelLongPress?.call(pm.nickname, ChannelType.private),
                    )),
              ],

              // Empty state
              if (channels.isEmpty && privateMessages.isEmpty)
                _buildEmptyState(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: AppSpacing.appBarHeight,
      padding: AppSpacing.paddingHorizontalLg,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Channels',
              style: AppTextStyles.headlineMedium,
            ),
          ),
          if (onAddChannel != null)
            IconButton(
              icon: const Icon(Icons.add, size: 22),
              onPressed: onAddChannel,
              tooltip: 'Join channel',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: AppSpacing.paddingXxl,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tag,
            size: 48,
            color: AppColors.textTertiary,
          ),
          AppSpacing.gapVerticalLg,
          Text(
            'No channels yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapVerticalSm,
          Text(
            'Join a channel to start chatting',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Information about a channel.
class ChannelInfo {
  const ChannelInfo({
    required this.name,
    this.topic,
    this.unreadCount = 0,
    this.hasMention = false,
  });

  final String name;
  final String? topic;
  final int unreadCount;
  final bool hasMention;
}

/// Information about a private message conversation.
class PrivateMessageInfo {
  const PrivateMessageInfo({
    required this.nickname,
    this.unreadCount = 0,
    this.hasMention = false,
    this.isAway = false,
  });

  final String nickname;
  final int unreadCount;
  final bool hasMention;
  final bool isAway;
}
