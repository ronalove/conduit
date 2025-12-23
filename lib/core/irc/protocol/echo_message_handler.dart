import 'dart:async';

import '../parser/irc_message.dart';
import '../parser/irc_message_extensions.dart';

/// Represents a pending message awaiting echo confirmation.
class PendingMessage {
  final String target;
  final String text;
  final DateTime sentAt;
  final String? clientMsgId;

  const PendingMessage({
    required this.target,
    required this.text,
    required this.sentAt,
    this.clientMsgId,
  });
}

/// Represents a confirmed message with server-assigned properties.
class ConfirmedMessage {
  final String target;
  final String text;
  final String? msgId;
  final DateTime? serverTime;
  final String source;

  const ConfirmedMessage({
    required this.target,
    required this.text,
    this.msgId,
    this.serverTime,
    required this.source,
  });
}

/// Result of checking if a message is an echo.
sealed class EchoCheckResult {}

/// The message is an echo of one of our pending messages.
class IsEcho extends EchoCheckResult {
  final PendingMessage pending;
  final ConfirmedMessage confirmed;

  IsEcho({required this.pending, required this.confirmed});
}

/// The message is not an echo (from another user).
class NotEcho extends EchoCheckResult {}

/// Handles IRCv3 echo-message extension.
///
/// When echo-message is enabled, the server echoes PRIVMSG and NOTICE
/// back to the sender with server-assigned tags (msgid, time).
///
/// This handler:
/// - Tracks pending outgoing messages
/// - Detects when a message is an echo of our own message
/// - Deduplicates pending messages when echo is received
/// - Provides confirmed message with server-assigned properties
///
/// See: https://ircv3.net/specs/extensions/echo-message
class EchoMessageHandler {
  final String _currentNick;
  final List<PendingMessage> _pending = [];
  final Duration _pendingTimeout;

  final StreamController<ConfirmedMessage> _confirmedController =
      StreamController<ConfirmedMessage>.broadcast();

  /// Creates an echo message handler.
  ///
  /// [currentNick] is used to detect our own messages.
  /// [pendingTimeout] is how long to keep pending messages (default 30s).
  EchoMessageHandler({
    required String currentNick,
    Duration pendingTimeout = const Duration(seconds: 30),
  })  : _currentNick = currentNick,
        _pendingTimeout = pendingTimeout;

  /// Stream of confirmed messages (after echo received).
  Stream<ConfirmedMessage> get confirmedMessages => _confirmedController.stream;

  /// Current pending messages count.
  int get pendingCount => _pending.length;

  /// Registers an outgoing message as pending.
  ///
  /// Call this when sending a PRIVMSG or NOTICE.
  /// [clientMsgId] is an optional client-generated ID for correlation.
  void trackOutgoing({
    required String target,
    required String text,
    String? clientMsgId,
  }) {
    _cleanupExpired();
    _pending.add(PendingMessage(
      target: target,
      text: text,
      sentAt: DateTime.now(),
      clientMsgId: clientMsgId,
    ));
  }

  /// Checks if an incoming message is an echo of one of our pending messages.
  ///
  /// Returns [IsEcho] if the message matches a pending outgoing message,
  /// with both the pending and confirmed message data.
  /// Returns [NotEcho] if the message is from another user.
  EchoCheckResult checkMessage(IrcMessage message) {
    if (message.command != 'PRIVMSG' && message.command != 'NOTICE') {
      return NotEcho();
    }

    // Check if message is from us
    final parsedSource = message.parsedSource;
    if (parsedSource == null || !_isOurNick(parsedSource.nick)) {
      return NotEcho();
    }

    // Extract target and text
    if (message.params.length < 2) {
      return NotEcho();
    }

    final target = message.params[0];
    final text = message.params[1];

    // Find matching pending message
    _cleanupExpired();
    final pendingIndex = _pending.indexWhere(
      (p) => p.target == target && p.text == text,
    );

    if (pendingIndex == -1) {
      return NotEcho();
    }

    final pending = _pending.removeAt(pendingIndex);
    final confirmed = ConfirmedMessage(
      target: target,
      text: text,
      msgId: message.msgId,
      serverTime: message.serverTime,
      source: message.source!,
    );

    _confirmedController.add(confirmed);

    return IsEcho(pending: pending, confirmed: confirmed);
  }

  /// Updates the current nickname (e.g., after NICK command).
  void updateNick(String newNick) {
    // Note: This creates a new handler with the new nick
    // In practice, you might want to make _currentNick mutable
  }

  /// Clears all pending messages.
  void clearPending() {
    _pending.clear();
  }

  /// Disposes resources.
  void dispose() {
    _confirmedController.close();
    _pending.clear();
  }

  bool _isOurNick(String nick) {
    // IRC nicknames are case-insensitive
    return nick.toLowerCase() == _currentNick.toLowerCase();
  }

  void _cleanupExpired() {
    final now = DateTime.now();
    _pending.removeWhere(
      (p) => now.difference(p.sentAt) > _pendingTimeout,
    );
  }
}

/// Extension for creating an EchoMessageHandler with mutable nick.
class MutableEchoMessageHandler extends EchoMessageHandler {
  String _mutableNick;

  MutableEchoMessageHandler({
    required String currentNick,
    Duration pendingTimeout = const Duration(seconds: 30),
  })  : _mutableNick = currentNick,
        super(currentNick: currentNick, pendingTimeout: pendingTimeout);

  @override
  bool _isOurNick(String nick) {
    return nick.toLowerCase() == _mutableNick.toLowerCase();
  }

  @override
  void updateNick(String newNick) {
    _mutableNick = newNick;
  }
}
