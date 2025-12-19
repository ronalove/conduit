import '../parser/irc_message.dart';
import '../parser/message_tags.dart';
import 'irc_command.dart';

/// Typing indicator states.
enum TypingState {
  /// User is actively typing.
  active,

  /// User stopped typing briefly.
  paused,

  /// User finished typing (cleared input).
  done,
}

/// Extension for converting TypingState to/from IRC values.
extension TypingStateExtension on TypingState {
  /// Converts to IRC string value.
  String toIrcValue() {
    return switch (this) {
      TypingState.active => 'active',
      TypingState.paused => 'paused',
      TypingState.done => 'done',
    };
  }

  /// Parses from IRC string value.
  static TypingState? fromIrcValue(String? value) {
    return switch (value) {
      'active' => TypingState.active,
      'paused' => TypingState.paused,
      'done' => TypingState.done,
      _ => null,
    };
  }
}

/// TAGMSG command - sends a message with only tags (no text content).
///
/// TAGMSG is used for client-only tags like typing indicators.
/// Format: `@+typing=active TAGMSG #channel`
///
/// See: https://ircv3.net/specs/extensions/message-tags
class TagmsgCommand extends IrcCommand {
  final String target;
  final Map<String, String?> tags;

  const TagmsgCommand({
    required this.target,
    required this.tags,
  });

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'TAGMSG',
        params: [target],
        tags: tags,
      );
}

/// Typing indicator command.
///
/// Sends a TAGMSG with the +typing client tag to indicate typing status.
/// Format: `@+typing=active TAGMSG #channel`
///
/// See: https://ircv3.net/specs/client-tags/typing
class TypingCommand extends IrcCommand {
  final String target;
  final TypingState state;
  final Map<String, String?>? additionalTags;

  const TypingCommand({
    required this.target,
    required this.state,
    this.additionalTags,
  });

  /// Creates a typing command for active state.
  factory TypingCommand.active(String target) => TypingCommand(
        target: target,
        state: TypingState.active,
      );

  /// Creates a typing command for paused state.
  factory TypingCommand.paused(String target) => TypingCommand(
        target: target,
        state: TypingState.paused,
      );

  /// Creates a typing command for done state.
  factory TypingCommand.done(String target) => TypingCommand(
        target: target,
        state: TypingState.done,
      );

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'TAGMSG',
        params: [target],
        tags: {
          ...?additionalTags,
          IrcTags.typing: state.toIrcValue(),
        },
      );
}
