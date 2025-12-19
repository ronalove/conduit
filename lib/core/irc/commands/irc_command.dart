import '../parser/irc_message.dart';

/// Base class for IRC commands.
abstract class IrcCommand {
  const IrcCommand();

  /// Converts the command to an [IrcMessage].
  IrcMessage toMessage();

  /// Converts the command to raw IRC format with CRLF.
  String toRaw() => toMessage().toRaw();
}
