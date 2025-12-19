import '../parser/irc_message.dart';
import 'irc_command.dart';

/// WHOX field flags.
///
/// These flags specify which fields to include in the WHO response.
abstract class WhoxFields {
  /// Query type token (for matching responses).
  static const String queryType = 't';

  /// Channel name.
  static const String channel = 'c';

  /// Username (ident).
  static const String username = 'u';

  /// IP address.
  static const String ip = 'i';

  /// Hostname.
  static const String hostname = 'h';

  /// Server name.
  static const String server = 's';

  /// Nickname.
  static const String nickname = 'n';

  /// Flags (H/G for here/gone, *, @, +).
  static const String flags = 'f';

  /// Hop count (distance from server).
  static const String hopCount = 'd';

  /// Idle time in seconds.
  static const String idle = 'l';

  /// Account name.
  static const String account = 'a';

  /// Channel op level.
  static const String opLevel = 'o';

  /// Real name (gecos).
  static const String realname = 'r';

  /// Standard fields for most use cases: nick, user, host, flags, account, realname.
  static const String standard = 'tcuhnfar';

  /// All available fields.
  static const String all = 'tcuihsnfdlaor';
}

/// WHOX command - Extended WHO query.
///
/// WHOX allows specifying which fields to include in WHO responses,
/// including the account name which is not available in standard WHO.
///
/// Reference: https://ircv3.net/specs/extensions/whox
class WhoxCommand extends IrcCommand {
  /// The target (channel, nickname, or mask).
  final String target;

  /// The fields to request (see [WhoxFields]).
  final String fields;

  /// Optional query type token for matching responses.
  final String? queryType;

  /// Creates a WHOX command.
  ///
  /// [target] is the channel, nickname, or mask to query.
  /// [fields] specifies which fields to return (default: standard fields).
  /// [queryType] is an optional token to match responses to requests.
  const WhoxCommand(
    this.target, {
    this.fields = WhoxFields.standard,
    this.queryType,
  });

  /// Creates a WHOX command to query a channel.
  const WhoxCommand.channel(
    String channel, {
    String fields = WhoxFields.standard,
    String? queryType,
  }) : this(channel, fields: fields, queryType: queryType);

  /// Creates a WHOX command to query a user by nickname.
  const WhoxCommand.user(
    String nick, {
    String fields = WhoxFields.standard,
    String? queryType,
  }) : this(nick, fields: fields, queryType: queryType);

  @override
  IrcMessage toMessage() {
    final flagsParam =
        queryType != null ? '%$fields,$queryType' : '%$fields';

    return IrcMessage(
      command: 'WHO',
      params: [target, flagsParam],
    );
  }
}
