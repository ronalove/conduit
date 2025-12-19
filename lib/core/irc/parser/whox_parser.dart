import 'irc_message.dart';

/// Represents a WHOX response entry.
///
/// The fields present depend on which flags were requested in the WHO query.
class WhoxResponse {
  /// The query type token (if 't' flag was used).
  final String? queryType;

  /// The channel name (if 'c' flag was used).
  final String? channel;

  /// The username/ident (if 'u' flag was used).
  final String? username;

  /// The IP address (if 'i' flag was used).
  final String? ip;

  /// The hostname (if 'h' flag was used).
  final String? hostname;

  /// The server name (if 's' flag was used).
  final String? server;

  /// The nickname (if 'n' flag was used).
  final String? nickname;

  /// The flags (H/G, *, @, +) (if 'f' flag was used).
  final String? flags;

  /// The hop count (if 'd' flag was used).
  final int? hopCount;

  /// The idle time in seconds (if 'l' flag was used).
  final int? idleTime;

  /// The account name (if 'a' flag was used).
  /// Value is '0' if not logged in.
  final String? account;

  /// The channel op level (if 'o' flag was used).
  final String? opLevel;

  /// The real name (if 'r' flag was used).
  final String? realname;

  /// Whether the user is away (H = Here, G = Gone).
  bool get isAway => flags?.contains('G') ?? false;

  /// Whether the user is an IRC operator (*).
  bool get isOper => flags?.contains('*') ?? false;

  /// Whether the user has an account (not '0').
  bool get hasAccount => account != null && account != '0';

  const WhoxResponse({
    this.queryType,
    this.channel,
    this.username,
    this.ip,
    this.hostname,
    this.server,
    this.nickname,
    this.flags,
    this.hopCount,
    this.idleTime,
    this.account,
    this.opLevel,
    this.realname,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WhoxResponse &&
          runtimeType == other.runtimeType &&
          queryType == other.queryType &&
          channel == other.channel &&
          username == other.username &&
          ip == other.ip &&
          hostname == other.hostname &&
          server == other.server &&
          nickname == other.nickname &&
          flags == other.flags &&
          hopCount == other.hopCount &&
          idleTime == other.idleTime &&
          account == other.account &&
          opLevel == other.opLevel &&
          realname == other.realname;

  @override
  int get hashCode => Object.hash(
        queryType,
        channel,
        username,
        ip,
        hostname,
        server,
        nickname,
        flags,
        hopCount,
        idleTime,
        account,
        opLevel,
        realname,
      );

  @override
  String toString() =>
      'WhoxResponse(nick: $nickname, account: $account, channel: $channel)';
}

/// Parser for WHOX responses.
///
/// Parses RPL_WHOSPCRPL (354) responses from WHOX queries.
///
/// Reference: https://ircv3.net/specs/extensions/whox
abstract class WhoxParser {
  /// RPL_WHOSPCRPL numeric code.
  static const int rplWhospcrpl = 354;

  /// Parses a WHOX response message (354).
  ///
  /// The fields in the response correspond to the flags requested
  /// in the original WHO query. The [requestedFields] parameter
  /// should match the fields string used in the query.
  ///
  /// Returns null if the message is not a 354 numeric or is malformed.
  static WhoxResponse? parse(IrcMessage message, String requestedFields) {
    if (message.command != '354') {
      return null;
    }

    // Skip first param (our nick) and parse remaining fields
    if (message.params.length < 2) {
      return null;
    }

    // Build field order from request flags
    final fieldOrder = _buildFieldOrder(requestedFields);

    // Parse params starting from index 1 (skip our nick)
    final values = message.params.sublist(1);

    String? queryType;
    String? channel;
    String? username;
    String? ip;
    String? hostname;
    String? server;
    String? nickname;
    String? flags;
    int? hopCount;
    int? idleTime;
    String? account;
    String? opLevel;
    String? realname;

    for (var i = 0; i < fieldOrder.length && i < values.length; i++) {
      final field = fieldOrder[i];
      final value = values[i];

      switch (field) {
        case 't':
          queryType = value;
        case 'c':
          channel = value;
        case 'u':
          username = value;
        case 'i':
          ip = value;
        case 'h':
          hostname = value;
        case 's':
          server = value;
        case 'n':
          nickname = value;
        case 'f':
          flags = value;
        case 'd':
          hopCount = int.tryParse(value);
        case 'l':
          idleTime = int.tryParse(value);
        case 'a':
          account = value;
        case 'o':
          opLevel = value;
        case 'r':
          realname = value;
      }
    }

    return WhoxResponse(
      queryType: queryType,
      channel: channel,
      username: username,
      ip: ip,
      hostname: hostname,
      server: server,
      nickname: nickname,
      flags: flags,
      hopCount: hopCount,
      idleTime: idleTime,
      account: account,
      opLevel: opLevel,
      realname: realname,
    );
  }

  /// Builds the field order list from the requested fields string.
  static List<String> _buildFieldOrder(String fields) {
    return fields.split('').where((c) => 'tcuihsnfdlaor'.contains(c)).toList();
  }

  /// Checks if a message is a WHOX response.
  static bool isWhoxResponse(IrcMessage message) => message.command == '354';

  /// Checks if a message is an end of WHO list (315).
  static bool isEndOfWho(IrcMessage message) => message.command == '315';
}
