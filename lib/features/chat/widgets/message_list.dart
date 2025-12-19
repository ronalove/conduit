import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../models/chat_message.dart';
import 'message_bubble.dart';

/// Scrollable message list with auto-scroll and scroll-to-bottom button.
class MessageList extends StatefulWidget {
  const MessageList({
    super.key,
    required this.messages,
    this.messagesById,
    this.currentUserNick,
    this.onLoadMore,
    this.onReply,
    this.onUserTap,
    this.isLoading = false,
    this.isCompact = true,
  });

  /// List of messages to display.
  final List<ChatMessage> messages;

  /// Map of message IDs to messages (for reply lookups).
  final Map<String, ChatMessage>? messagesById;

  /// Current user's nickname for mention highlighting.
  final String? currentUserNick;

  /// Called when user scrolls to top to load more history.
  final VoidCallback? onLoadMore;

  /// Called when user taps reply on a message.
  final void Function(ChatMessage message)? onReply;

  /// Called when user taps on a nickname.
  final void Function(String nickname)? onUserTap;

  /// Whether history is currently loading.
  final bool isLoading;

  /// Whether to use compact display mode.
  final bool isCompact;

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = true;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to bottom when new messages arrive and user is at bottom
    if (widget.messages.length > oldWidget.messages.length && _isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _onScroll() {
    final atBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;

    if (atBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = atBottom;
        _showScrollToBottom = !atBottom;
      });
    }

    // Load more when scrolling near top
    if (_scrollController.position.pixels < 100 && widget.onLoadMore != null) {
      widget.onLoadMore!();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  ChatMessage? _getReplyTo(ChatMessage message) {
    if (message.replyTo == null || widget.messagesById == null) return null;
    return widget.messagesById![message.replyTo];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Message list
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.md,
          ),
          itemCount: widget.messages.length + (widget.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (widget.isLoading && index == 0) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final messageIndex = widget.isLoading ? index - 1 : index;
            final message = widget.messages[messageIndex];
            final showDateSeparator = _shouldShowDateSeparator(messageIndex);

            return Column(
              children: [
                if (showDateSeparator) _buildDateSeparator(message.timestamp),
                MessageBubble(
                  message: message,
                  replyTo: _getReplyTo(message),
                  currentUserNick: widget.currentUserNick,
                  isCompact: widget.isCompact,
                  showTimestamp: true,
                  onReply: widget.onReply != null
                      ? () => widget.onReply!(message)
                      : null,
                  onUserTap: widget.onUserTap,
                ),
              ],
            );
          },
        ),

        // Scroll to bottom button
        if (_showScrollToBottom)
          Positioned(
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: FloatingActionButton.small(
              onPressed: _scrollToBottom,
              backgroundColor: AppColors.surfaceElevated,
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;
    final current = widget.messages[index];
    final previous = widget.messages[index - 1];

    final currentDate = DateTime(
      current.timestamp.year,
      current.timestamp.month,
      current.timestamp.day,
    );
    final previousDate = DateTime(
      previous.timestamp.year,
      previous.timestamp.month,
      previous.timestamp.day,
    );

    return currentDate != previousDate;
  }

  Widget _buildDateSeparator(DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              _formatDate(timestamp),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  String _formatDate(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${weekdays[timestamp.weekday - 1]}, ${months[timestamp.month - 1]} ${timestamp.day}';
    }
  }
}
