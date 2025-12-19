/// User mode in a channel.
enum UserMode {
  /// Channel operator (@).
  operator,

  /// Half-operator (%).
  halfOp,

  /// Voice (+).
  voice,

  /// Regular user.
  regular,
}

/// Extension to get mode prefix.
extension UserModePrefix on UserMode {
  /// Get the IRC prefix for this mode.
  String get prefix => switch (this) {
        UserMode.operator => '@',
        UserMode.halfOp => '%',
        UserMode.voice => '+',
        UserMode.regular => '',
      };

  /// Get sort order (higher modes first).
  int get sortOrder => switch (this) {
        UserMode.operator => 0,
        UserMode.halfOp => 1,
        UserMode.voice => 2,
        UserMode.regular => 3,
      };
}

/// A user in a channel.
class ChannelUser {
  const ChannelUser({
    required this.nickname,
    this.mode = UserMode.regular,
    this.isAway = false,
    this.awayMessage,
    this.account,
    this.realname,
    this.hostname,
  });

  /// User's nickname.
  final String nickname;

  /// User's mode in the channel.
  final UserMode mode;

  /// Whether the user is away.
  final bool isAway;

  /// Away message if set.
  final String? awayMessage;

  /// Account name if logged in.
  final String? account;

  /// Real name.
  final String? realname;

  /// User's hostname.
  final String? hostname;

  /// Get display name with mode prefix.
  String get displayName => '${mode.prefix}$nickname';

  /// Whether user has elevated privileges.
  bool get hasPrivileges =>
      mode == UserMode.operator || mode == UserMode.halfOp;

  /// Copy with new values.
  ChannelUser copyWith({
    String? nickname,
    UserMode? mode,
    bool? isAway,
    String? awayMessage,
    String? account,
    String? realname,
    String? hostname,
  }) {
    return ChannelUser(
      nickname: nickname ?? this.nickname,
      mode: mode ?? this.mode,
      isAway: isAway ?? this.isAway,
      awayMessage: awayMessage ?? this.awayMessage,
      account: account ?? this.account,
      realname: realname ?? this.realname,
      hostname: hostname ?? this.hostname,
    );
  }
}
