import 'dart:async';

import '../parser/irc_message.dart';
import '../parser/irc_message_extensions.dart';

/// Represents an active batch being accumulated.
class ActiveBatch {
  /// Unique reference for this batch.
  final String reference;

  /// The batch type (e.g., 'chathistory', 'netjoin').
  final String type;

  /// Type-specific parameters.
  final List<String> params;

  /// Parent batch reference for nested batches.
  final String? parentRef;

  /// Accumulated messages in this batch.
  final List<IrcMessage> messages = [];

  /// Nested batches completed within this batch.
  final List<CompletedBatch> nestedBatches = [];

  /// When this batch was started.
  final DateTime startedAt;

  ActiveBatch({
    required this.reference,
    required this.type,
    this.params = const [],
    this.parentRef,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();
}

/// Represents a completed batch with all its messages.
class CompletedBatch {
  /// Unique reference for this batch.
  final String reference;

  /// The batch type.
  final String type;

  /// Type-specific parameters.
  final List<String> params;

  /// All messages in this batch.
  final List<IrcMessage> messages;

  /// Nested batches completed within this batch.
  final List<CompletedBatch> nestedBatches;

  /// Source of the batch opening message.
  final String? source;

  /// Tags from the batch opening message.
  final Map<String, String?> tags;

  const CompletedBatch({
    required this.reference,
    required this.type,
    this.params = const [],
    this.messages = const [],
    this.nestedBatches = const [],
    this.source,
    this.tags = const {},
  });

  /// Whether this batch has any messages.
  bool get isEmpty => messages.isEmpty && nestedBatches.isEmpty;

  /// Whether this batch has messages or nested batches.
  bool get isNotEmpty => !isEmpty;

  /// Total message count including nested batches.
  int get totalMessageCount {
    var count = messages.length;
    for (final nested in nestedBatches) {
      count += nested.totalMessageCount;
    }
    return count;
  }
}

/// Callback for when a batch is completed.
typedef BatchCompletedCallback = void Function(CompletedBatch batch);

/// Handles IRCv3 batch message grouping.
///
/// The batch extension allows servers to group related messages together.
/// This handler accumulates batched messages and delivers them as a group
/// when the batch ends.
///
/// Supports:
/// - Multiple concurrent batches
/// - Nested batches
/// - All standard batch types (netjoin, netsplit, chathistory, etc.)
///
/// See: https://ircv3.net/specs/extensions/batch
class BatchHandler {
  final Map<String, ActiveBatch> _activeBatches = {};
  final Map<String, IrcMessage> _batchStartMessages = {};
  final StreamController<CompletedBatch> _batchController =
      StreamController<CompletedBatch>.broadcast();

  /// Stream of completed batches.
  Stream<CompletedBatch> get onBatchCompleted => _batchController.stream;

  /// Number of active batches.
  int get activeBatchCount => _activeBatches.length;

  /// Whether there are any active batches.
  bool get hasActiveBatches => _activeBatches.isNotEmpty;

  /// Gets an active batch by reference.
  ActiveBatch? getActiveBatch(String reference) => _activeBatches[reference];

  /// Checks if a batch reference is active.
  bool isBatchActive(String reference) => _activeBatches.containsKey(reference);

  /// Handles an incoming message.
  ///
  /// Returns `true` if the message was consumed (part of a batch).
  /// Returns `false` if the message should be processed normally.
  bool handleMessage(IrcMessage message) {
    if (message.command == 'BATCH') {
      return _handleBatchCommand(message);
    }

    // Check if message is part of an active batch
    final batchRef = message.batchRef;
    if (batchRef == null) return false;

    final batch = _activeBatches[batchRef];
    if (batch == null) return false;

    // Add message to the batch
    batch.messages.add(message);
    return true;
  }

  bool _handleBatchCommand(IrcMessage message) {
    if (message.params.isEmpty) return false;

    final refParam = message.params[0];

    if (refParam.startsWith('+')) {
      return _handleBatchStart(message, refParam.substring(1));
    } else if (refParam.startsWith('-')) {
      return _handleBatchEnd(message, refParam.substring(1));
    }

    return false;
  }

  bool _handleBatchStart(IrcMessage message, String reference) {
    if (message.params.length < 2) return false;

    final type = message.params[1];
    final params = message.params.length > 2
        ? message.params.sublist(2)
        : <String>[];

    // Check for parent batch (nested batches)
    final parentRef = message.batchRef;

    _activeBatches[reference] = ActiveBatch(
      reference: reference,
      type: type,
      params: params,
      parentRef: parentRef,
    );

    _batchStartMessages[reference] = message;

    return true;
  }

  bool _handleBatchEnd(IrcMessage message, String reference) {
    final batch = _activeBatches.remove(reference);
    if (batch == null) return false;

    final startMessage = _batchStartMessages.remove(reference);

    final completed = CompletedBatch(
      reference: batch.reference,
      type: batch.type,
      params: batch.params,
      messages: List.unmodifiable(batch.messages),
      nestedBatches: List.unmodifiable(batch.nestedBatches),
      source: startMessage?.source,
      tags: startMessage?.tags ?? const {},
    );

    // If this is a nested batch, add to parent
    if (batch.parentRef != null) {
      final parent = _activeBatches[batch.parentRef!];
      if (parent != null) {
        parent.nestedBatches.add(completed);
        return true;
      }
    }

    // Emit completed batch
    _batchController.add(completed);
    return true;
  }

  /// Cancels an active batch.
  ///
  /// This can be used to clean up stale batches if the connection is lost.
  void cancelBatch(String reference) {
    _activeBatches.remove(reference);
    _batchStartMessages.remove(reference);
  }

  /// Cancels all active batches.
  void cancelAllBatches() {
    _activeBatches.clear();
    _batchStartMessages.clear();
  }

  /// Gets all active batch references.
  List<String> get activeBatchReferences => _activeBatches.keys.toList();

  /// Gets the type of an active batch.
  String? getBatchType(String reference) => _activeBatches[reference]?.type;

  /// Disposes resources.
  void dispose() {
    cancelAllBatches();
    _batchController.close();
  }
}
