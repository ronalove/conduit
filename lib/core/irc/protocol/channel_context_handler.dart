import 'dart:async';

import '../parser/irc_message.dart';
import '../parser/message_tags.dart';

/// Represents a private message with channel context.
class ChannelContextMessage {
  /// The sender's nick.
  final String? senderNick;

  /// The sender's user.
  final String? senderUser;

  /// The sender's host.
  final String? senderHost;

  /// The target of the message (recipient nick).
  final String target;

  /// The message text.
  final String? text;

  /// The channel being discussed.
  final String channelContext;

  /// When the message was received.
  final DateTime receivedAt;

  /// The original IRC message.
  final IrcMessage originalMessage;

  const ChannelContextMessage({
    this.senderNick,
    this.senderUser,
    this.senderHost,
    required this.target,
    this.text,
    required this.channelContext,
    required this.receivedAt,
    required this.originalMessage,
  });

  /// Whether this is a valid channel name.
  bool get isValidChannelContext =>
      channelContext.startsWith('#') ||
      channelContext.startsWith('&') ||
      channelContext.startsWith('+') ||
      channelContext.startsWith('!');

  @override
  String toString() => 'ChannelContextMessage('
      'sender: $senderNick, '
      'target: $target, '
      'channelContext: $channelContext)';
}

/// Handles IRCv3 +draft/channel-context client tag.
///
/// Parses incoming private messages that include channel context,
/// indicating which channel the message is about.
///
/// See: https://ircv3.net/specs/client-tags/channel-context
class ChannelContextHandler {
  final StreamController<ChannelContextMessage> _messageController =
      StreamController<ChannelContextMessage>.broadcast();

  /// Stream of messages with channel context.
  Stream<ChannelContextMessage> get messages => _messageController.stream;

  /// Handles an incoming IRC message.
  ///
  /// Returns a [ChannelContextMessage] if the message has channel context,
  /// null otherwise.
  ChannelContextMessage? handleMessage(IrcMessage message) {
    // Only handle PRIVMSG and NOTICE
    if (message.command != 'PRIVMSG' && message.command != 'NOTICE') {
      return null;
    }

    // Check for channel context tag
    final channelContext = message.tags[IrcTags.channelContext];
    if (channelContext == null) {
      return null;
    }

    // Get target
    if (message.params.isEmpty) {
      return null;
    }

    final target = message.params[0];
    final text = message.params.length > 1 ? message.params[1] : null;

    // Parse sender
    final parsedSource = message.parsedSource;

    final contextMessage = ChannelContextMessage(
      senderNick: parsedSource?.nick,
      senderUser: parsedSource?.user,
      senderHost: parsedSource?.host,
      target: target,
      text: text,
      channelContext: channelContext,
      receivedAt: DateTime.now(),
      originalMessage: message,
    );

    _messageController.add(contextMessage);
    return contextMessage;
  }

  /// Checks if a message has channel context.
  static bool hasChannelContext(IrcMessage message) =>
      message.tags.containsKey(IrcTags.channelContext);

  /// Gets the channel context from a message.
  static String? getChannelContext(IrcMessage message) =>
      message.tags[IrcTags.channelContext];

  /// Disposes resources.
  void dispose() {
    _messageController.close();
  }
}

/// Extension on IrcMessage for channel context.
extension IrcMessageChannelContextExtension on IrcMessage {
  /// Gets the channel context if present.
  String? get channelContext => tags[IrcTags.channelContext];

  /// Whether this message has channel context.
  bool get hasChannelContext => tags.containsKey(IrcTags.channelContext);

  /// Creates a copy of this message with a channel context tag.
  IrcMessage withChannelContext(String channel) {
    return IrcMessage(
      tags: {...tags, IrcTags.channelContext: channel},
      source: source,
      command: command,
      params: params,
    );
  }
}
