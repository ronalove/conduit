import 'chat_message.dart';

/// State for messages in a single channel.
class ChannelMessagesState {
  const ChannelMessagesState({
    required this.channel,
    this.messages = const [],
    this.unreadCount = 0,
    this.hasMention = false,
    this.isLoadingHistory = false,
    this.oldestMessageId,
  });

  /// Channel name (lowercase).
  final String channel;

  /// Messages in chronological order (oldest first).
  final List<ChatMessage> messages;

  /// Number of unread messages.
  final int unreadCount;

  /// Whether there's an unread mention.
  final bool hasMention;

  /// Whether older history is being loaded.
  final bool isLoadingHistory;

  /// ID of the oldest message in memory (for pagination).
  final String? oldestMessageId;

  /// Get messages indexed by ID for quick lookup.
  Map<String, ChatMessage> get messagesById {
    return {for (final m in messages) m.id: m};
  }

  /// Create a copy with updated fields.
  ChannelMessagesState copyWith({
    String? channel,
    List<ChatMessage>? messages,
    int? unreadCount,
    bool? hasMention,
    bool? isLoadingHistory,
    String? oldestMessageId,
    bool clearOldestMessageId = false,
  }) {
    return ChannelMessagesState(
      channel: channel ?? this.channel,
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMention: hasMention ?? this.hasMention,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      oldestMessageId:
          clearOldestMessageId ? null : (oldestMessageId ?? this.oldestMessageId),
    );
  }
}

/// Global state for all channel messages.
class MessagesState {
  const MessagesState({
    this.channels = const {},
  });

  /// Messages state per channel (keyed by lowercase channel name).
  final Map<String, ChannelMessagesState> channels;

  /// Get state for a specific channel.
  ChannelMessagesState? getChannel(String channel) {
    return channels[channel.toLowerCase()];
  }

  /// Create a copy with updated channel state.
  MessagesState copyWith({
    Map<String, ChannelMessagesState>? channels,
  }) {
    return MessagesState(
      channels: channels ?? this.channels,
    );
  }

  /// Update state for a specific channel.
  MessagesState updateChannel(String channel, ChannelMessagesState state) {
    return MessagesState(
      channels: {
        ...channels,
        channel.toLowerCase(): state,
      },
    );
  }

  /// Remove a channel from state.
  MessagesState removeChannel(String channel) {
    final newChannels = Map<String, ChannelMessagesState>.from(channels);
    newChannels.remove(channel.toLowerCase());
    return MessagesState(channels: newChannels);
  }
}
