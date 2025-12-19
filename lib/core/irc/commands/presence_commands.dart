import '../parser/irc_message.dart';
import 'irc_command.dart';

/// AWAY command - sets or clears away status.
///
/// When sent with a message, marks the user as away.
/// When sent without a message, marks the user as back.
class AwayCommand extends IrcCommand {
  /// The away message, or null to mark as back.
  final String? message;

  /// Creates an AWAY command with an optional away message.
  ///
  /// If [message] is provided, the user is marked as away with that reason.
  /// If [message] is null, the user is marked as back (no longer away).
  const AwayCommand({this.message});

  /// Creates an AWAY command to mark the user as back.
  const AwayCommand.back() : message = null;

  /// Creates an AWAY command to mark the user as away.
  const AwayCommand.away(String this.message);

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'AWAY',
        params: message != null ? [message!] : [],
      );
}

/// SETNAME command - changes the user's realname (gecos).
///
/// Requires the 'setname' capability to be enabled on the server.
class SetnameCommand extends IrcCommand {
  /// The new realname.
  final String realname;

  /// Creates a SETNAME command with the new realname.
  const SetnameCommand(this.realname);

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'SETNAME',
        params: [realname],
      );
}
