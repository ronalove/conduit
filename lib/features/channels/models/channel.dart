import '../../users/models/channel_user.dart';
import '../screens/channel_list_screen.dart';

/// Topic information for a channel.
class ChannelTopic {
  const ChannelTopic({
    required this.text,
    this.setBy,
    this.setAt,
  });

  /// The topic text.
  final String text;

  /// Nickname of the user who set the topic.
  final String? setBy;

  /// When the topic was set.
  final DateTime? setAt;

  ChannelTopic copyWith({
    String? text,
    String? setBy,
    DateTime? setAt,
  }) {
    return ChannelTopic(
      text: text ?? this.text,
      setBy: setBy ?? this.setBy,
      setAt: setAt ?? this.setAt,
    );
  }

  @override
  String toString() => 'ChannelTopic($text, setBy: $setBy, setAt: $setAt)';
}

/// Represents an IRC channel with its full state.
class Channel {
  const Channel({
    required this.name,
    this.topic,
    this.users = const {},
    this.modes = const {},
    required this.joinedAt,
    this.lastActivity,
    this.unreadCount = 0,
    this.hasMention = false,
    this.isJoining = false,
  });

  /// Channel name (including # prefix).
  final String name;

  /// Channel topic.
  final ChannelTopic? topic;

  /// Users in the channel, keyed by lowercase nickname.
  final Map<String, ChannelUser> users;

  /// Channel modes (e.g., {'n', 't', 's'}).
  final Set<String> modes;

  /// When we joined this channel.
  final DateTime joinedAt;

  /// Last message activity in this channel.
  final DateTime? lastActivity;

  /// Number of unread messages.
  final int unreadCount;

  /// Whether there's an unread mention.
  final bool hasMention;

  /// Whether we're currently joining (waiting for NAMES).
  final bool isJoining;

  /// Number of members in the channel.
  int get memberCount => users.length;

  /// Whether the channel has a topic set.
  bool get hasTopic => topic != null && topic!.text.isNotEmpty;

  /// Get the topic text, or null if not set.
  String? get topicText => topic?.text;

  /// Get a sorted list of users (operators first, then alphabetically).
  List<ChannelUser> get sortedUsers {
    final userList = users.values.toList();
    userList.sort((a, b) {
      // First sort by mode (operators first)
      final modeCompare = a.mode.sortOrder.compareTo(b.mode.sortOrder);
      if (modeCompare != 0) return modeCompare;
      // Then alphabetically
      return a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase());
    });
    return userList;
  }

  /// Get a user by nickname (case-insensitive).
  ChannelUser? getUser(String nickname) => users[nickname.toLowerCase()];

  /// Check if a user is in this channel.
  bool hasUser(String nickname) => users.containsKey(nickname.toLowerCase());

  /// Convert to ChannelInfo for UI display.
  ChannelInfo toChannelInfo() {
    return ChannelInfo(
      name: name,
      topic: topicText,
      unreadCount: unreadCount,
      hasMention: hasMention,
    );
  }

  Channel copyWith({
    String? name,
    ChannelTopic? topic,
    bool clearTopic = false,
    Map<String, ChannelUser>? users,
    Set<String>? modes,
    DateTime? joinedAt,
    DateTime? lastActivity,
    int? unreadCount,
    bool? hasMention,
    bool? isJoining,
  }) {
    return Channel(
      name: name ?? this.name,
      topic: clearTopic ? null : (topic ?? this.topic),
      users: users ?? this.users,
      modes: modes ?? this.modes,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActivity: lastActivity ?? this.lastActivity,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMention: hasMention ?? this.hasMention,
      isJoining: isJoining ?? this.isJoining,
    );
  }

  /// Create a copy with an added user.
  Channel addUser(ChannelUser user) {
    final newUsers = Map<String, ChannelUser>.from(users);
    newUsers[user.nickname.toLowerCase()] = user;
    return copyWith(users: newUsers);
  }

  /// Create a copy with a removed user.
  Channel removeUser(String nickname) {
    final newUsers = Map<String, ChannelUser>.from(users);
    newUsers.remove(nickname.toLowerCase());
    return copyWith(users: newUsers);
  }

  /// Create a copy with an updated user.
  Channel updateUser(String nickname, ChannelUser Function(ChannelUser) update) {
    final key = nickname.toLowerCase();
    final existing = users[key];
    if (existing == null) return this;

    final newUsers = Map<String, ChannelUser>.from(users);
    newUsers[key] = update(existing);
    return copyWith(users: newUsers);
  }

  /// Create a copy with new users (replaces all existing users).
  Channel withUsers(List<ChannelUser> userList) {
    final newUsers = <String, ChannelUser>{};
    for (final user in userList) {
      newUsers[user.nickname.toLowerCase()] = user;
    }
    return copyWith(users: newUsers, isJoining: false);
  }

  @override
  String toString() =>
      'Channel($name, ${users.length} users, topic: ${topic?.text})';
}
