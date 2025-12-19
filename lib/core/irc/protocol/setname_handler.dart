import 'dart:async';

import '../parser/irc_message.dart';
import '../parser/source_parser.dart';

/// Represents a user's realname change.
class RealnameChange {
  /// The nickname of the user.
  final String nick;

  /// The username (ident) of the user.
  final String? user;

  /// The hostname of the user.
  final String? host;

  /// The new realname (gecos).
  final String realname;

  /// The timestamp of this change.
  final DateTime timestamp;

  const RealnameChange({
    required this.nick,
    this.user,
    this.host,
    required this.realname,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RealnameChange &&
          runtimeType == other.runtimeType &&
          nick == other.nick &&
          user == other.user &&
          host == other.host &&
          realname == other.realname;

  @override
  int get hashCode => Object.hash(nick, user, host, realname);

  @override
  String toString() => 'RealnameChange(nick: $nick, realname: $realname)';
}

/// Handler for IRCv3 setname extension.
///
/// Processes SETNAME messages to track user realname changes in real-time.
/// Requires the 'setname' capability to be enabled.
///
/// Reference: https://ircv3.net/specs/extensions/setname
class SetnameHandler {
  final _changeController = StreamController<RealnameChange>.broadcast();

  /// Stream of realname changes.
  Stream<RealnameChange> get realnameChanges => _changeController.stream;

  /// Handles an incoming SETNAME message.
  ///
  /// Format: `:nick!user@host SETNAME :New Real Name`
  ///
  /// Returns the parsed [RealnameChange] if the message is a SETNAME message,
  /// or null if it's not a SETNAME message or malformed.
  RealnameChange? handleMessage(IrcMessage message) {
    if (message.command != 'SETNAME') {
      return null;
    }

    final source = message.parsedSource;
    if (source == null) {
      return null;
    }

    // SETNAME requires at least 1 param: the new realname
    if (message.params.isEmpty) {
      return null;
    }

    final realname = message.params.first;

    final change = RealnameChange(
      nick: source.nick,
      user: source.user,
      host: source.host,
      realname: realname,
      timestamp: DateTime.now(),
    );

    _changeController.add(change);
    return change;
  }

  /// Checks if a message is a SETNAME message.
  static bool isSetnameMessage(IrcMessage message) =>
      message.command == 'SETNAME';

  /// Disposes resources used by this handler.
  void dispose() {
    _changeController.close();
  }
}
