import 'dart:async';

import '../parser/irc_message.dart';
import '../parser/irc_message_extensions.dart';
import '../parser/message_tags.dart';
import '../parser/source_parser.dart';

/// Represents a reply relationship between messages.
class ReplyInfo {
  /// The message ID of the reply message.
  final String msgId;

  /// The message ID of the parent message being replied to.
  final String parentMsgId;

  /// The target channel or nick.
  final String target;

  /// The sender's nick.
  final String? senderNick;

  /// The message text.
  final String? text;

  /// When the reply was received.
  final DateTime receivedAt;

  const ReplyInfo({
    required this.msgId,
    required this.parentMsgId,
    required this.target,
    this.senderNick,
    this.text,
    required this.receivedAt,
  });

  @override
  String toString() =>
      'ReplyInfo(msgId: $msgId, parentMsgId: $parentMsgId, target: $target)';
}

/// Handles IRCv3 +draft/reply client tag for message threading.
///
/// Tracks reply relationships between messages and provides utilities
/// for building reply chains and threads.
///
/// See: https://ircv3.net/specs/client-tags/reply
class ReplyHandler {
  /// Maximum number of reply relationships to cache.
  final int maxCacheSize;

  /// Map of msgId -> ReplyInfo for messages that are replies.
  final Map<String, ReplyInfo> _replies = {};

  /// Map of parentMsgId -> Set of reply msgIds.
  final Map<String, Set<String>> _childReplies = {};

  final StreamController<ReplyInfo> _replyController =
      StreamController<ReplyInfo>.broadcast();

  /// Creates a reply handler.
  ///
  /// [maxCacheSize] limits the number of cached reply relationships (default 1000).
  ReplyHandler({this.maxCacheSize = 1000});

  /// Stream of reply notifications.
  Stream<ReplyInfo> get replies => _replyController.stream;

  /// Handles an incoming IRC message.
  ///
  /// Returns a [ReplyInfo] if the message is a reply, null otherwise.
  ReplyInfo? handleMessage(IrcMessage message) {
    // Only handle PRIVMSG and NOTICE
    if (message.command != 'PRIVMSG' && message.command != 'NOTICE') {
      return null;
    }

    // Check for reply tag
    final parentMsgId = message.replyTargetMsgId;
    if (parentMsgId == null) {
      return null;
    }

    // Must have a msgId to track
    final msgId = message.msgId;
    if (msgId == null) {
      return null;
    }

    // Get target and text
    if (message.params.isEmpty) {
      return null;
    }

    final target = message.params[0];
    final text = message.params.length > 1 ? message.params[1] : null;

    // Parse sender
    final parsedSource = message.parsedSource;

    final replyInfo = ReplyInfo(
      msgId: msgId,
      parentMsgId: parentMsgId,
      target: target,
      senderNick: parsedSource?.nick,
      text: text,
      receivedAt: DateTime.now(),
    );

    _addReply(replyInfo);
    _replyController.add(replyInfo);

    return replyInfo;
  }

  /// Checks if a message is a reply.
  bool isReply(IrcMessage message) => message.isReply;

  /// Gets the parent message ID for a reply.
  String? getParentMsgId(IrcMessage message) => message.replyTargetMsgId;

  /// Gets all direct replies to a message.
  List<ReplyInfo> getReplies(String msgId) {
    final childIds = _childReplies[msgId];
    if (childIds == null) return const [];

    return childIds
        .map((id) => _replies[id])
        .whereType<ReplyInfo>()
        .toList();
  }

  /// Gets the reply info for a specific message if it's a reply.
  ReplyInfo? getReplyInfo(String msgId) => _replies[msgId];

  /// Checks if a message has any replies.
  bool hasReplies(String msgId) {
    final children = _childReplies[msgId];
    return children != null && children.isNotEmpty;
  }

  /// Gets the count of direct replies to a message.
  int getReplyCount(String msgId) => _childReplies[msgId]?.length ?? 0;

  /// Builds a reply chain from a message up to its root.
  ///
  /// Returns a list of msgIds from the given message to the root,
  /// with the root first and the given message last.
  List<String> getReplyChain(String msgId) {
    final chain = <String>[msgId];
    var currentId = msgId;

    // Walk up the chain
    while (true) {
      final reply = _replies[currentId];
      if (reply == null) break;

      chain.insert(0, reply.parentMsgId);
      currentId = reply.parentMsgId;
    }

    return chain;
  }

  /// Gets the depth of a message in its reply chain.
  ///
  /// Returns 0 for root messages (not replies).
  int getReplyDepth(String msgId) {
    var depth = 0;
    var currentId = msgId;

    while (true) {
      final reply = _replies[currentId];
      if (reply == null) break;
      depth++;
      currentId = reply.parentMsgId;
    }

    return depth;
  }

  /// Clears all cached reply relationships.
  void clear() {
    _replies.clear();
    _childReplies.clear();
  }

  /// Removes reply relationships for a specific target.
  void clearTarget(String target) {
    final toRemove = <String>[];

    for (final entry in _replies.entries) {
      if (entry.value.target == target) {
        toRemove.add(entry.key);
      }
    }

    for (final msgId in toRemove) {
      _removeReply(msgId);
    }
  }

  /// Disposes resources.
  void dispose() {
    _replyController.close();
    _replies.clear();
    _childReplies.clear();
  }

  void _addReply(ReplyInfo info) {
    // Enforce cache size limit
    if (_replies.length >= maxCacheSize) {
      _evictOldest();
    }

    _replies[info.msgId] = info;

    // Track in child map
    _childReplies.putIfAbsent(info.parentMsgId, () => {});
    _childReplies[info.parentMsgId]!.add(info.msgId);
  }

  void _removeReply(String msgId) {
    final reply = _replies.remove(msgId);
    if (reply != null) {
      _childReplies[reply.parentMsgId]?.remove(msgId);
      if (_childReplies[reply.parentMsgId]?.isEmpty ?? false) {
        _childReplies.remove(reply.parentMsgId);
      }
    }
  }

  void _evictOldest() {
    // Simple FIFO eviction - remove first entry
    if (_replies.isNotEmpty) {
      final oldestKey = _replies.keys.first;
      _removeReply(oldestKey);
    }
  }
}
