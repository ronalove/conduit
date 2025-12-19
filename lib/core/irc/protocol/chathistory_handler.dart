import 'dart:async';

import '../parser/irc_message.dart';
import '../parser/irc_message_extensions.dart';
import 'batch_handler.dart';

/// Represents a chathistory response with messages.
class ChathistoryResult {
  /// The target (channel or nickname) this history is for.
  final String target;

  /// The messages in chronological order.
  final List<IrcMessage> messages;

  /// Whether there are more messages available before this batch.
  final bool hasMoreBefore;

  /// Whether there are more messages available after this batch.
  final bool hasMoreAfter;

  const ChathistoryResult({
    required this.target,
    required this.messages,
    this.hasMoreBefore = false,
    this.hasMoreAfter = false,
  });

  /// Whether the result is empty.
  bool get isEmpty => messages.isEmpty;

  /// Whether the result has messages.
  bool get isNotEmpty => messages.isNotEmpty;

  /// Number of messages in the result.
  int get count => messages.length;

  /// The oldest message in the result, if any.
  IrcMessage? get oldest => messages.isNotEmpty ? messages.first : null;

  /// The newest message in the result, if any.
  IrcMessage? get newest => messages.isNotEmpty ? messages.last : null;

  /// The message ID of the oldest message, if available.
  String? get oldestMsgId => oldest?.msgId;

  /// The message ID of the newest message, if available.
  String? get newestMsgId => newest?.msgId;
}

/// Represents a target in a CHATHISTORY TARGETS response.
class ChathistoryTarget {
  /// The target name (channel or nickname).
  final String name;

  /// Timestamp of the most recent message with this target.
  final DateTime? timestamp;

  const ChathistoryTarget({
    required this.name,
    this.timestamp,
  });
}

/// Handles CHATHISTORY batch responses.
///
/// Works in conjunction with [BatchHandler] to process chathistory batches
/// and return structured results.
///
/// See: https://ircv3.net/specs/extensions/chathistory
class ChathistoryHandler {
  final StreamController<ChathistoryResult> _resultController =
      StreamController<ChathistoryResult>.broadcast();

  final StreamController<List<ChathistoryTarget>> _targetsController =
      StreamController<List<ChathistoryTarget>>.broadcast();

  /// Stream of chathistory results.
  Stream<ChathistoryResult> get onResult => _resultController.stream;

  /// Stream of targets responses.
  Stream<List<ChathistoryTarget>> get onTargets => _targetsController.stream;

  /// Processes a completed chathistory batch.
  ///
  /// Call this when a batch of type 'chathistory' completes.
  /// Returns the parsed [ChathistoryResult].
  ChathistoryResult? processBatch(CompletedBatch batch) {
    if (batch.type != 'chathistory') return null;

    // The target is in the batch params
    final target = batch.params.isNotEmpty ? batch.params[0] : '';

    // Extract PRIVMSG and NOTICE messages
    final messages = batch.messages
        .where((m) => m.command == 'PRIVMSG' || m.command == 'NOTICE')
        .toList();

    // Sort by server time if available
    messages.sort((a, b) {
      final timeA = a.serverTime;
      final timeB = b.serverTime;
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return -1;
      if (timeB == null) return 1;
      return timeA.compareTo(timeB);
    });

    final result = ChathistoryResult(
      target: target,
      messages: messages,
    );

    _resultController.add(result);
    return result;
  }

  /// Processes a CHATHISTORY TARGETS batch.
  ///
  /// Extracts the list of targets from the batch messages.
  List<ChathistoryTarget>? processTargetsBatch(CompletedBatch batch) {
    if (batch.type != 'chathistory') return null;

    final targets = <ChathistoryTarget>[];

    for (final message in batch.messages) {
      // TARGETS responses come as messages with target info
      if (message.command == 'CHATHISTORY' &&
          message.params.isNotEmpty &&
          message.params[0] == 'TARGETS') {
        // Format: CHATHISTORY TARGETS <target> <timestamp>
        if (message.params.length >= 3) {
          final targetName = message.params[1];
          final timestampStr = message.params[2];
          DateTime? timestamp;

          // Try to parse timestamp
          if (timestampStr.startsWith('timestamp=')) {
            timestamp = DateTime.tryParse(timestampStr.substring(10));
          } else {
            timestamp = DateTime.tryParse(timestampStr);
          }

          targets.add(ChathistoryTarget(
            name: targetName,
            timestamp: timestamp,
          ));
        }
      }
    }

    if (targets.isNotEmpty) {
      _targetsController.add(targets);
    }

    return targets.isNotEmpty ? targets : null;
  }

  /// Handles a FAIL response for chathistory.
  ///
  /// Common fail codes:
  /// - INVALID_PARAMS: Invalid command syntax
  /// - INVALID_TARGET: Target doesn't exist or no access
  /// - MESSAGE_ERROR: Server-side error
  /// - NEED_MORE_PARAMS: Missing required parameters
  static ChathistoryError? parseError(IrcMessage message) {
    if (message.command != 'FAIL') return null;
    if (message.params.isEmpty || message.params[0] != 'CHATHISTORY') {
      return null;
    }

    final code = message.params.length > 1 ? message.params[1] : 'UNKNOWN';
    final context = message.params.length > 2 ? message.params[2] : null;
    final description = message.params.length > 3 ? message.params[3] : null;

    return ChathistoryError(
      code: code,
      context: context,
      description: description,
    );
  }

  /// Disposes resources.
  void dispose() {
    _resultController.close();
    _targetsController.close();
  }
}

/// Represents a CHATHISTORY error.
class ChathistoryError {
  /// The error code (e.g., INVALID_PARAMS, INVALID_TARGET).
  final String code;

  /// Additional context about the error.
  final String? context;

  /// Human-readable description.
  final String? description;

  const ChathistoryError({
    required this.code,
    this.context,
    this.description,
  });

  @override
  String toString() {
    if (description != null) {
      return 'ChathistoryError: $code - $description';
    }
    return 'ChathistoryError: $code';
  }
}
