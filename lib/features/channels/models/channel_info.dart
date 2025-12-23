/// Information about a channel for UI display.
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
