import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../models/chat_message.dart';
import '../widgets/message_input.dart';
import '../widgets/message_list.dart';
import '../widgets/typing_indicator.dart';

/// Main chat screen displaying messages and input.
class ChatScreen extends StatelessWidget {
  const ChatScreen({
    super.key,
    required this.channelName,
    required this.messages,
    this.topic,
    this.typingUsers = const [],
    this.onSendMessage,
    this.onLoadMore,
    this.onTyping,
    this.isLoadingHistory = false,
    this.showHeader = true,
    this.onBack,
    this.onShowUsers,
  });

  /// Channel or user name.
  final String channelName;

  /// List of messages.
  final List<ChatMessage> messages;

  /// Channel topic.
  final String? topic;

  /// List of users currently typing.
  final List<String> typingUsers;

  /// Called when user sends a message.
  final void Function(String message)? onSendMessage;

  /// Called to load more history.
  final VoidCallback? onLoadMore;

  /// Called when user typing status changes.
  final void Function(bool isTyping)? onTyping;

  /// Whether history is loading.
  final bool isLoadingHistory;

  /// Whether to show the header (mobile).
  final bool showHeader;

  /// Called when back button is pressed (mobile).
  final VoidCallback? onBack;

  /// Called when users button is pressed (mobile).
  final VoidCallback? onShowUsers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header (optional, for mobile)
        if (showHeader) _buildHeader(context),

        // Messages
        Expanded(
          child: MessageList(
            messages: messages,
            onLoadMore: onLoadMore,
            isLoading: isLoadingHistory,
          ),
        ),

        // Typing indicator
        TypingIndicator(typingUsers: typingUsers),

        // Input
        MessageInput(
          placeholder: 'Message $channelName',
          onSend: onSendMessage,
          onTyping: onTyping,
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: AppSpacing.appBarHeight,
      padding: AppSpacing.paddingHorizontalSm,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
              tooltip: 'Back',
            ),

          // Channel info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channelName,
                  style: AppTextStyles.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if (topic != null && topic!.isNotEmpty)
                  Text(
                    topic!,
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),

          // Users button
          if (onShowUsers != null)
            IconButton(
              icon: const Icon(Icons.people_outline),
              onPressed: onShowUsers,
              tooltip: 'Users',
            ),
        ],
      ),
    );
  }
}

/// Empty state for chat when no channel is selected.
class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textTertiary,
          ),
          AppSpacing.gapVerticalLg,
          Text(
            'Select a channel to start chatting',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
