import 'dart:async';

import '../parser/irc_message.dart';

/// Represents a user's away status change.
class AwayStatus {
  /// The nickname of the user.
  final String nick;

  /// The username (ident) of the user.
  final String? user;

  /// The hostname of the user.
  final String? host;

  /// Whether the user is away.
  final bool isAway;

  /// The away message, or null if back.
  final String? message;

  /// The timestamp of this status change.
  final DateTime timestamp;

  const AwayStatus({
    required this.nick,
    this.user,
    this.host,
    required this.isAway,
    this.message,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AwayStatus &&
          runtimeType == other.runtimeType &&
          nick == other.nick &&
          user == other.user &&
          host == other.host &&
          isAway == other.isAway &&
          message == other.message;

  @override
  int get hashCode => Object.hash(nick, user, host, isAway, message);

  @override
  String toString() =>
      'AwayStatus(nick: $nick, isAway: $isAway, message: $message)';
}

/// Handler for IRCv3 away-notify extension.
///
/// Processes AWAY messages to track user away status in real-time.
/// Requires the 'away-notify' capability to be enabled.
///
/// Reference: https://ircv3.net/specs/extensions/away-notify
class AwayNotifyHandler {
  final _statusController = StreamController<AwayStatus>.broadcast();

  /// Stream of away status changes.
  Stream<AwayStatus> get statusChanges => _statusController.stream;

  /// Handles an incoming AWAY message.
  ///
  /// Returns the parsed [AwayStatus] if the message is an AWAY message,
  /// or null if it's not an AWAY message.
  AwayStatus? handleMessage(IrcMessage message) {
    if (message.command != 'AWAY') {
      return null;
    }

    final source = message.parsedSource;
    if (source == null) {
      return null;
    }

    // AWAY with message = user is away
    // AWAY without message = user is back
    final awayMessage =
        message.params.isNotEmpty ? message.params.first : null;
    final isAway = awayMessage != null;

    final status = AwayStatus(
      nick: source.nick,
      user: source.user,
      host: source.host,
      isAway: isAway,
      message: awayMessage,
      timestamp: DateTime.now(),
    );

    _statusController.add(status);
    return status;
  }

  /// Checks if a message is an AWAY message.
  static bool isAwayMessage(IrcMessage message) => message.command == 'AWAY';

  /// Disposes resources used by this handler.
  void dispose() {
    _statusController.close();
  }
}
