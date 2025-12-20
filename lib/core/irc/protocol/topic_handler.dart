import 'dart:async';

import '../../../features/channels/models/channel.dart';
import '../parser/irc_message.dart';

/// Update containing topic information for a channel.
class TopicUpdate {
  const TopicUpdate({
    required this.channel,
    this.topic,
  });

  /// Channel name.
  final String channel;

  /// The topic, or null if no topic is set.
  final ChannelTopic? topic;

  /// Whether the channel has a topic.
  bool get hasTopic => topic != null;

  @override
  String toString() => 'TopicUpdate($channel, ${topic?.text ?? "no topic"})';
}

/// Handles TOPIC-related messages (331, 332, 333, TOPIC).
///
/// IRC topic messages:
/// - 331 (RPL_NOTOPIC): No topic is set
/// - 332 (RPL_TOPIC): The channel's topic
/// - 333 (RPL_TOPICWHOTIME): Who set the topic and when
/// - TOPIC: Real-time topic change notification
///
/// This handler emits [TopicUpdate]s when topic information is received.
///
/// See: https://modern.ircdocs.horse/#topic-message
class TopicHandler {
  final Map<String, ChannelTopic> _pendingTopics = {};

  final StreamController<TopicUpdate> _topicController =
      StreamController<TopicUpdate>.broadcast();

  /// Stream of topic updates.
  Stream<TopicUpdate> get onTopicReceived => _topicController.stream;

  /// Handles an incoming IRC message.
  ///
  /// Returns a [TopicUpdate] if this message contains complete topic info,
  /// or null otherwise.
  TopicUpdate? handleMessage(IrcMessage message) {
    switch (message.command) {
      case '331':
        return _handleNoTopic(message);
      case '332':
        return _handleTopic(message);
      case '333':
        return _handleTopicWhoTime(message);
      case 'TOPIC':
        return _handleTopicCommand(message);
      default:
        return null;
    }
  }

  /// RPL_NOTOPIC (331): :server 331 nick #channel :No topic is set.
  TopicUpdate? _handleNoTopic(IrcMessage message) {
    if (message.params.length < 2) return null;

    final channel = message.params[1].toLowerCase();

    final update = TopicUpdate(channel: channel, topic: null);
    _topicController.add(update);
    return update;
  }

  /// RPL_TOPIC (332): :server 332 nick #channel :The topic text
  TopicUpdate? _handleTopic(IrcMessage message) {
    if (message.params.length < 3) return null;

    final channel = message.params[1].toLowerCase();
    final topicText = message.params[2];

    // Store pending topic, wait for 333 for setter/time info
    _pendingTopics[channel] = ChannelTopic(text: topicText);

    // Return null - we'll emit when we get 333 or can emit without it
    return null;
  }

  /// RPL_TOPICWHOTIME (333): :server 333 nick #channel setter timestamp
  TopicUpdate? _handleTopicWhoTime(IrcMessage message) {
    if (message.params.length < 4) return null;

    final channel = message.params[1].toLowerCase();
    final setter = message.params[2];
    final timestamp = int.tryParse(message.params[3]);
    final setAt =
        timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000) : null;

    // Check if we have a pending topic
    final pendingTopic = _pendingTopics.remove(channel);

    if (pendingTopic != null) {
      // Complete the topic with setter/time info
      final topic = ChannelTopic(
        text: pendingTopic.text,
        setBy: setter,
        setAt: setAt,
      );

      final update = TopicUpdate(channel: channel, topic: topic);
      _topicController.add(update);
      return update;
    }

    // No pending topic - this shouldn't happen normally
    return null;
  }

  /// TOPIC command: :nick!user@host TOPIC #channel :New topic
  TopicUpdate? _handleTopicCommand(IrcMessage message) {
    if (message.params.isEmpty) return null;

    final channel = message.params[0].toLowerCase();

    // Extract setter from source
    final setter = message.parsedSource?.nick;

    // Topic text - can be empty (clearing topic) or the new topic
    final topicText = message.params.length > 1 ? message.params[1] : null;

    if (topicText == null || topicText.isEmpty) {
      // Topic cleared
      final update = TopicUpdate(channel: channel, topic: null);
      _topicController.add(update);
      return update;
    }

    // New topic set
    final topic = ChannelTopic(
      text: topicText,
      setBy: setter,
      setAt: DateTime.now(),
    );

    final update = TopicUpdate(channel: channel, topic: topic);
    _topicController.add(update);
    return update;
  }

  /// Emit any pending topic that didn't get a 333 response.
  ///
  /// Call this after receiving RPL_ENDOFNAMES (366) to ensure
  /// topics are emitted even if the server doesn't send 333.
  TopicUpdate? flushPendingTopic(String channel) {
    final key = channel.toLowerCase();
    final pending = _pendingTopics.remove(key);

    if (pending != null) {
      final update = TopicUpdate(channel: key, topic: pending);
      _topicController.add(update);
      return update;
    }

    return null;
  }

  /// Check if a message is a topic-related message.
  static bool isTopicMessage(IrcMessage message) {
    return message.command == '331' ||
        message.command == '332' ||
        message.command == '333' ||
        message.command == 'TOPIC';
  }

  /// Gets the list of channels with pending topics.
  List<String> get pendingChannels => _pendingTopics.keys.toList();

  /// Cancels pending topic for a channel.
  void cancelPending(String channel) {
    _pendingTopics.remove(channel.toLowerCase());
  }

  /// Cancels all pending topics.
  void cancelAllPending() {
    _pendingTopics.clear();
  }

  /// Disposes resources.
  void dispose() {
    _pendingTopics.clear();
    _topicController.close();
  }
}
