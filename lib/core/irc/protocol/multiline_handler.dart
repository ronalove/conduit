import 'dart:async';
import 'dart:math';

import '../parser/irc_message.dart';
import '../parser/irc_message_extensions.dart';
import '../parser/message_tags.dart';
import '../commands/batch_commands.dart';
import 'batch_handler.dart';

/// Represents a multiline message with multiple lines combined.
class MultilineMessage {
  /// The target (channel or nickname).
  final String target;

  /// The sender's source (nick!user@host).
  final String? source;

  /// All lines of the message.
  final List<String> lines;

  /// Combined message text with newlines.
  final String text;

  /// Message ID of the first line, if available.
  final String? msgId;

  /// Server timestamp, if available.
  final DateTime? serverTime;

  /// Sender's account, if available.
  final String? account;

  /// The batch reference this message came from.
  final String batchRef;

  const MultilineMessage({
    required this.target,
    this.source,
    required this.lines,
    required this.text,
    this.msgId,
    this.serverTime,
    this.account,
    required this.batchRef,
  });

  /// Number of lines in the message.
  int get lineCount => lines.length;

  /// Whether this is actually multiline (more than one line).
  bool get isMultiline => lines.length > 1;
}

/// A builder for creating multiline messages to send.
class MultilineMessageBuilder {
  final String target;
  final List<String> _lines = [];
  String? _batchRef;

  MultilineMessageBuilder(this.target);

  /// Adds a line to the message.
  void addLine(String line) {
    _lines.add(line);
  }

  /// Adds multiple lines to the message.
  void addLines(Iterable<String> lines) {
    _lines.addAll(lines);
  }

  /// Sets the text, splitting on newlines.
  ///
  /// Empty text results in no lines.
  void setText(String text) {
    _lines.clear();
    if (text.isEmpty) return;
    _lines.addAll(text.split('\n'));
  }

  /// Number of lines currently added.
  int get lineCount => _lines.length;

  /// Whether the builder has any lines.
  bool get hasLines => _lines.isNotEmpty;

  /// Builds the IRC messages to send.
  ///
  /// Returns a list of messages: BATCH start, PRIVMSG lines, BATCH end.
  List<IrcMessage> build() {
    if (_lines.isEmpty) return [];

    _batchRef = _generateBatchRef();
    final messages = <IrcMessage>[];

    // Batch start
    messages.add(BatchCommand.start(
      _batchRef!,
      BatchTypes.multiline,
      [target],
    ).toMessage());

    // Lines as PRIVMSG with batch tag
    for (final line in _lines) {
      messages.add(IrcMessage(
        tags: {IrcTags.batch: _batchRef},
        command: 'PRIVMSG',
        params: [target, line],
      ));
    }

    // Batch end
    messages.add(BatchCommand.end(_batchRef!).toMessage());

    return messages;
  }

  static final _random = Random();

  static String _generateBatchRef() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buffer = StringBuffer();
    for (var i = 0; i < 8; i++) {
      buffer.write(chars[_random.nextInt(chars.length)]);
    }
    return buffer.toString();
  }
}

/// Handles multiline message batches.
///
/// Multiline messages are sent and received as batches of type draft/multiline.
/// This handler processes incoming multiline batches and provides utilities
/// for building outgoing multiline messages.
///
/// See: https://ircv3.net/specs/extensions/multiline
class MultilineHandler {
  final StreamController<MultilineMessage> _messageController =
      StreamController<MultilineMessage>.broadcast();

  /// Stream of received multiline messages.
  Stream<MultilineMessage> get onMessage => _messageController.stream;

  /// Processes a completed multiline batch.
  ///
  /// Call this when a batch of type 'draft/multiline' completes.
  /// Returns the parsed [MultilineMessage], or null if not a multiline batch.
  MultilineMessage? processBatch(CompletedBatch batch) {
    if (batch.type != BatchTypes.multiline) return null;

    // Target is in batch params
    final target = batch.params.isNotEmpty ? batch.params[0] : '';

    // Extract PRIVMSG lines
    final privmsgs = batch.messages
        .where((m) => m.command == 'PRIVMSG')
        .toList();

    if (privmsgs.isEmpty) return null;

    // Extract lines (last param of each PRIVMSG)
    final lines = privmsgs.map((m) => m.params.isNotEmpty
        ? m.params.last
        : '').toList();

    // Get metadata from first message
    final firstMsg = privmsgs.first;
    final msgId = firstMsg.msgId;
    final serverTime = firstMsg.serverTime;
    final account = firstMsg.senderAccount;

    final message = MultilineMessage(
      target: target,
      source: firstMsg.source,
      lines: lines,
      text: lines.join('\n'),
      msgId: msgId,
      serverTime: serverTime,
      account: account,
      batchRef: batch.reference,
    );

    _messageController.add(message);
    return message;
  }

  /// Creates a builder for a multiline message.
  MultilineMessageBuilder createBuilder(String target) {
    return MultilineMessageBuilder(target);
  }

  /// Creates multiline messages from text.
  ///
  /// Splits the text on newlines and creates the batch messages.
  /// Returns empty list if text is empty.
  List<IrcMessage> buildFromText(String target, String text) {
    final builder = MultilineMessageBuilder(target);
    builder.setText(text);
    return builder.build();
  }

  /// Checks if a batch is a multiline batch.
  static bool isMultilineBatch(CompletedBatch batch) {
    return batch.type == BatchTypes.multiline;
  }

  /// Checks if multiline capability is present.
  ///
  /// The capability is typically 'draft/multiline'.
  static const String capabilityName = 'draft/multiline';

  /// Disposes resources.
  void dispose() {
    _messageController.close();
  }
}
