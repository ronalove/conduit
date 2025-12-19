import '../parser/irc_message.dart';
import '../parser/message_tags.dart';
import 'irc_command.dart';

/// PRIVMSG command with channel context for private messages.
///
/// When sending a private message about a specific channel, include the
/// channel context so the recipient knows which channel is being discussed.
/// Format: `@+draft/channel-context=#channel PRIVMSG othernick :Hey about #channel`
///
/// See: https://ircv3.net/specs/client-tags/channel-context
class ChannelContextPrivmsgCommand extends IrcCommand {
  /// The target nick (private message recipient).
  final String target;

  /// The message text.
  final String message;

  /// The channel being discussed.
  final String channelContext;

  /// Additional tags to include.
  final Map<String, String?>? additionalTags;

  const ChannelContextPrivmsgCommand({
    required this.target,
    required this.message,
    required this.channelContext,
    this.additionalTags,
  });

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'PRIVMSG',
        params: [target, message],
        tags: {
          ...?additionalTags,
          IrcTags.channelContext: channelContext,
        },
      );
}

/// NOTICE command with channel context.
///
/// Similar to [ChannelContextPrivmsgCommand] but for notices.
class ChannelContextNoticeCommand extends IrcCommand {
  /// The target nick.
  final String target;

  /// The notice text.
  final String message;

  /// The channel being discussed.
  final String channelContext;

  /// Additional tags to include.
  final Map<String, String?>? additionalTags;

  const ChannelContextNoticeCommand({
    required this.target,
    required this.message,
    required this.channelContext,
    this.additionalTags,
  });

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'NOTICE',
        params: [target, message],
        tags: {
          ...?additionalTags,
          IrcTags.channelContext: channelContext,
        },
      );
}
