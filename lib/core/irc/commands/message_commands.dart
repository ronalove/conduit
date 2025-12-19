import '../parser/irc_message.dart';
import 'irc_command.dart';

/// PRIVMSG command - sends a message to a target.
class PrivmsgCommand extends IrcCommand {
  final String target;
  final String message;
  final Map<String, String?>? tags;

  const PrivmsgCommand({
    required this.target,
    required this.message,
    this.tags,
  });

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'PRIVMSG',
        params: [target, message],
        tags: tags ?? const {},
      );
}

/// NOTICE command - sends a notice to a target.
class NoticeCommand extends IrcCommand {
  final String target;
  final String message;

  const NoticeCommand({
    required this.target,
    required this.message,
  });

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'NOTICE',
        params: [target, message],
      );
}
