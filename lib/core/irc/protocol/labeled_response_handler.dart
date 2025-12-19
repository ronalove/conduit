import 'dart:async';
import 'dart:math';

import '../parser/irc_message.dart';
import '../parser/irc_message_extensions.dart';
import '../parser/message_tags.dart';

/// Represents a pending labeled request.
class PendingRequest {
  final String label;
  final IrcMessage originalCommand;
  final DateTime sentAt;
  final Completer<LabeledResponse> completer;

  PendingRequest({
    required this.label,
    required this.originalCommand,
    required this.sentAt,
    required this.completer,
  });
}

/// A response to a labeled request.
sealed class LabeledResponse {}

/// Single message response.
class SingleResponse extends LabeledResponse {
  final IrcMessage message;

  SingleResponse(this.message);
}

/// Batch response (multiple messages).
class BatchResponse extends LabeledResponse {
  final String batchRef;
  final List<IrcMessage> messages;

  BatchResponse({required this.batchRef, required this.messages});
}

/// Timeout waiting for response.
class TimeoutResponse extends LabeledResponse {
  final String label;

  TimeoutResponse(this.label);
}

/// ACK response (command accepted, no further response).
class AckResponse extends LabeledResponse {
  final String label;

  AckResponse(this.label);
}

/// Handles IRCv3 labeled-response extension.
///
/// Allows correlating server responses with client requests using labels.
///
/// Usage:
/// 1. Use [labelCommand] to add a label to an outgoing command
/// 2. Send the command and wait for [waitForResponse]
/// 3. Handler matches incoming messages by label
///
/// Supports:
/// - Single message responses
/// - Batch responses (labeled-response batch type)
/// - ACK (empty response confirmation)
///
/// See: https://ircv3.net/specs/extensions/labeled-response
class LabeledResponseHandler {
  final Map<String, PendingRequest> _pending = {};
  final Map<String, List<IrcMessage>> _batchMessages = {};
  final Map<String, String> _batchLabels = {}; // batchRef -> label
  final Duration _defaultTimeout;
  final Random _random = Random();

  /// Creates a labeled response handler.
  ///
  /// [defaultTimeout] is how long to wait for responses (default 30s).
  LabeledResponseHandler({
    Duration defaultTimeout = const Duration(seconds: 30),
  }) : _defaultTimeout = defaultTimeout;

  /// Number of pending requests.
  int get pendingCount => _pending.length;

  /// Generates a unique label.
  String generateLabel() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buffer = StringBuffer();
    for (var i = 0; i < 12; i++) {
      buffer.write(chars[_random.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  /// Adds a label to an outgoing command.
  ///
  /// Returns the labeled message and the label used.
  ({IrcMessage message, String label}) labelCommand(IrcMessage command) {
    final label = generateLabel();
    final labeled = command.withLabel(label);
    return (message: labeled, label: label);
  }

  /// Sends a command with a label and waits for the response.
  ///
  /// [sendCommand] is a callback that sends the command to the server.
  /// Returns the labeled response when received.
  /// Throws [TimeoutException] if no response received within timeout.
  Future<LabeledResponse> sendAndWait(
    IrcMessage command,
    Future<void> Function(IrcMessage) sendCommand, {
    Duration? timeout,
  }) async {
    final labeled = labelCommand(command);
    final completer = Completer<LabeledResponse>();

    _pending[labeled.label] = PendingRequest(
      label: labeled.label,
      originalCommand: command,
      sentAt: DateTime.now(),
      completer: completer,
    );

    await sendCommand(labeled.message);

    final effectiveTimeout = timeout ?? _defaultTimeout;

    try {
      return await completer.future.timeout(
        effectiveTimeout,
        onTimeout: () {
          _pending.remove(labeled.label);
          return TimeoutResponse(labeled.label);
        },
      );
    } catch (e) {
      _pending.remove(labeled.label);
      rethrow;
    }
  }

  /// Tracks a labeled command manually (without waiting).
  ///
  /// Use [waitForResponse] to get the response later.
  String trackCommand(IrcMessage command) {
    final labeled = labelCommand(command);
    final completer = Completer<LabeledResponse>();

    _pending[labeled.label] = PendingRequest(
      label: labeled.label,
      originalCommand: command,
      sentAt: DateTime.now(),
      completer: completer,
    );

    return labeled.label;
  }

  /// Waits for a response to a tracked label.
  Future<LabeledResponse> waitForResponse(String label, {Duration? timeout}) {
    final pending = _pending[label];
    if (pending == null) {
      return Future.value(TimeoutResponse(label));
    }

    final effectiveTimeout = timeout ?? _defaultTimeout;

    return pending.completer.future.timeout(
      effectiveTimeout,
      onTimeout: () {
        _pending.remove(label);
        return TimeoutResponse(label);
      },
    );
  }

  /// Handles an incoming message, checking for labeled responses.
  ///
  /// Returns true if the message was a labeled response (consumed).
  /// Returns false if the message should be processed normally.
  bool handleMessage(IrcMessage message) {
    // Check for BATCH start/end
    if (message.command == 'BATCH') {
      return _handleBatch(message);
    }

    // Check if message is part of a batch
    final batchRef = message.batchRef;
    if (batchRef != null && _batchLabels.containsKey(batchRef)) {
      _batchMessages[batchRef]?.add(message);
      return true; // Consumed as part of batch
    }

    // Check for direct labeled response
    final label = message.responseLabel;
    if (label == null) return false;

    final pending = _pending.remove(label);
    if (pending == null) return false;

    // Check for ACK (empty response)
    if (message.command == 'ACK') {
      pending.completer.complete(AckResponse(label));
      return true;
    }

    pending.completer.complete(SingleResponse(message));
    return true;
  }

  bool _handleBatch(IrcMessage message) {
    if (message.params.isEmpty) return false;

    final refParam = message.params[0];

    if (refParam.startsWith('+')) {
      // Batch start: BATCH +ref type [params...]
      final batchRef = refParam.substring(1);

      // Check if this is a labeled-response batch
      final label = message.responseLabel;
      if (label == null || !_pending.containsKey(label)) {
        return false; // Not a labeled batch we're tracking
      }

      // Check batch type
      if (message.params.length >= 2 && message.params[1] == 'labeled-response') {
        _batchLabels[batchRef] = label;
        _batchMessages[batchRef] = [];
        return true;
      }

      return false;
    } else if (refParam.startsWith('-')) {
      // Batch end: BATCH -ref
      final batchRef = refParam.substring(1);
      final label = _batchLabels.remove(batchRef);

      if (label == null) return false;

      final messages = _batchMessages.remove(batchRef) ?? [];
      final pending = _pending.remove(label);

      if (pending != null) {
        pending.completer.complete(BatchResponse(
          batchRef: batchRef,
          messages: messages,
        ));
      }

      return true;
    }

    return false;
  }

  /// Cancels a pending request.
  void cancelRequest(String label) {
    final pending = _pending.remove(label);
    if (pending != null && !pending.completer.isCompleted) {
      pending.completer.complete(TimeoutResponse(label));
    }
  }

  /// Clears all pending requests.
  void clearPending() {
    for (final pending in _pending.values) {
      if (!pending.completer.isCompleted) {
        pending.completer.complete(TimeoutResponse(pending.label));
      }
    }
    _pending.clear();
    _batchMessages.clear();
    _batchLabels.clear();
  }

  /// Disposes resources.
  void dispose() {
    clearPending();
  }
}
