import 'dart:async';

import '../parser/irc_message.dart';
import '../parser/source_parser.dart';

/// Represents a user's host change.
class HostChange {
  /// The nickname of the user.
  final String nick;

  /// The old username (ident).
  final String? oldUser;

  /// The old hostname.
  final String? oldHost;

  /// The new username (ident).
  final String newUser;

  /// The new hostname.
  final String newHost;

  /// The timestamp of this change.
  final DateTime timestamp;

  const HostChange({
    required this.nick,
    this.oldUser,
    this.oldHost,
    required this.newUser,
    required this.newHost,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HostChange &&
          runtimeType == other.runtimeType &&
          nick == other.nick &&
          oldUser == other.oldUser &&
          oldHost == other.oldHost &&
          newUser == other.newUser &&
          newHost == other.newHost;

  @override
  int get hashCode => Object.hash(nick, oldUser, oldHost, newUser, newHost);

  @override
  String toString() =>
      'HostChange(nick: $nick, $oldUser@$oldHost -> $newUser@$newHost)';
}

/// Handler for IRCv3 chghost extension.
///
/// Processes CHGHOST messages to track user host changes in real-time.
/// Requires the 'chghost' capability to be enabled.
///
/// Reference: https://ircv3.net/specs/extensions/chghost
class ChghostHandler {
  final _changeController = StreamController<HostChange>.broadcast();

  /// Stream of host changes.
  Stream<HostChange> get hostChanges => _changeController.stream;

  /// Handles an incoming CHGHOST message.
  ///
  /// Format: `:nick!olduser@oldhost CHGHOST newuser newhost`
  ///
  /// Returns the parsed [HostChange] if the message is a CHGHOST message,
  /// or null if it's not a CHGHOST message or malformed.
  HostChange? handleMessage(IrcMessage message) {
    if (message.command != 'CHGHOST') {
      return null;
    }

    final source = message.parsedSource;
    if (source == null) {
      return null;
    }

    // CHGHOST requires exactly 2 params: newuser newhost
    if (message.params.length < 2) {
      return null;
    }

    final newUser = message.params[0];
    final newHost = message.params[1];

    final change = HostChange(
      nick: source.nick,
      oldUser: source.user,
      oldHost: source.host,
      newUser: newUser,
      newHost: newHost,
      timestamp: DateTime.now(),
    );

    _changeController.add(change);
    return change;
  }

  /// Checks if a message is a CHGHOST message.
  static bool isChghostMessage(IrcMessage message) =>
      message.command == 'CHGHOST';

  /// Disposes resources used by this handler.
  void dispose() {
    _changeController.close();
  }
}
