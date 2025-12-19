import '../parser/irc_message.dart';
import '../parser/message_tags.dart';
import 'irc_command.dart';

/// PRIVMSG command with reply reference.
///
/// Sends a message that references another message by its msgid.
/// Format: `@+draft/reply=<msgid> PRIVMSG #channel :Reply text`
///
/// See: https://ircv3.net/specs/client-tags/reply
class ReplyCommand extends IrcCommand {
  /// The target channel or nick.
  final String target;

  /// The message text.
  final String message;

  /// The msgid of the message being replied to.
  final String replyToMsgId;

  /// Additional tags to include.
  final Map<String, String?>? additionalTags;

  const ReplyCommand({
    required this.target,
    required this.message,
    required this.replyToMsgId,
    this.additionalTags,
  });

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'PRIVMSG',
        params: [target, message],
        tags: {
          ...?additionalTags,
          IrcTags.replyTo: replyToMsgId,
        },
      );
}

/// NOTICE command with reply reference.
///
/// Sends a notice that references another message by its msgid.
class ReplyNoticeCommand extends IrcCommand {
  /// The target channel or nick.
  final String target;

  /// The notice text.
  final String message;

  /// The msgid of the message being replied to.
  final String replyToMsgId;

  /// Additional tags to include.
  final Map<String, String?>? additionalTags;

  const ReplyNoticeCommand({
    required this.target,
    required this.message,
    required this.replyToMsgId,
    this.additionalTags,
  });

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'NOTICE',
        params: [target, message],
        tags: {
          ...?additionalTags,
          IrcTags.replyTo: replyToMsgId,
        },
      );
}
