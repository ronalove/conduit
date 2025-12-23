import 'irc_message.dart';

/// Represents extended JOIN information.
///
/// When the 'extended-join' capability is enabled, JOIN messages include
/// the user's account name and realname.
class ExtendedJoin {
  /// The nickname of the joining user.
  final String nick;

  /// The username (ident) of the joining user.
  final String? user;

  /// The hostname of the joining user.
  final String? host;

  /// The channel being joined.
  final String channel;

  /// The account name of the user, or null if not logged in.
  ///
  /// Will be `*` in the raw message if not logged in.
  final String? account;

  /// The realname (gecos) of the user.
  final String? realname;

  /// Whether the user has an account (is logged in).
  bool get hasAccount => account != null;

  const ExtendedJoin({
    required this.nick,
    this.user,
    this.host,
    required this.channel,
    this.account,
    this.realname,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtendedJoin &&
          runtimeType == other.runtimeType &&
          nick == other.nick &&
          user == other.user &&
          host == other.host &&
          channel == other.channel &&
          account == other.account &&
          realname == other.realname;

  @override
  int get hashCode =>
      Object.hash(nick, user, host, channel, account, realname);

  @override
  String toString() =>
      'ExtendedJoin(nick: $nick, channel: $channel, account: $account)';
}

/// Parser for extended-join messages.
///
/// Parses JOIN messages with the additional account and realname fields
/// when the 'extended-join' capability is enabled.
///
/// Reference: https://ircv3.net/specs/extensions/extended-join
abstract class ExtendedJoinParser {
  /// Parses a JOIN message into an [ExtendedJoin].
  ///
  /// Works with both standard JOIN and extended-join formats:
  /// - Standard: `:nick!user@host JOIN #channel`
  /// - Extended: `:nick!user@host JOIN #channel accountname :Real Name`
  ///
  /// Returns null if the message is not a JOIN or is malformed.
  static ExtendedJoin? parse(IrcMessage message) {
    if (message.command != 'JOIN') {
      return null;
    }

    final source = message.parsedSource;
    if (source == null) {
      return null;
    }

    if (message.params.isEmpty) {
      return null;
    }

    final channel = message.params[0];

    // Standard JOIN - only channel parameter
    if (message.params.length == 1) {
      return ExtendedJoin(
        nick: source.nick,
        user: source.user,
        host: source.host,
        channel: channel,
      );
    }

    // Extended JOIN - account and realname parameters
    // Format: JOIN #channel accountname :realname
    String? account;
    String? realname;

    if (message.params.length >= 2) {
      final accountParam = message.params[1];
      // * means not logged in
      account = accountParam == '*' ? null : accountParam;
    }

    if (message.params.length >= 3) {
      realname = message.params[2];
    }

    return ExtendedJoin(
      nick: source.nick,
      user: source.user,
      host: source.host,
      channel: channel,
      account: account,
      realname: realname,
    );
  }

  /// Checks if a message is a JOIN message.
  static bool isJoinMessage(IrcMessage message) => message.command == 'JOIN';

  /// Checks if a JOIN message has extended information.
  ///
  /// Returns true if the message has account and/or realname fields.
  static bool isExtendedJoin(IrcMessage message) =>
      message.command == 'JOIN' && message.params.length >= 2;
}
