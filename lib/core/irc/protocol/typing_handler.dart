import 'dart:async';

import '../commands/typing_commands.dart';
import '../parser/irc_message.dart';
import '../parser/message_tags.dart';

/// Represents a typing notification from a user.
class TypingNotification {
  /// The user who is typing.
  final String nick;

  /// The user's username (if available).
  final String? user;

  /// The user's host (if available).
  final String? host;

  /// The target channel or nick.
  final String target;

  /// The typing state.
  final TypingState state;

  /// When the notification was received.
  final DateTime receivedAt;

  const TypingNotification({
    required this.nick,
    this.user,
    this.host,
    required this.target,
    required this.state,
    required this.receivedAt,
  });

  /// Whether this is a channel typing notification.
  bool get isChannel =>
      target.startsWith('#') ||
      target.startsWith('&') ||
      target.startsWith('+') ||
      target.startsWith('!');

  /// Whether the user is actively typing.
  bool get isActive => state == TypingState.active;

  /// Whether the user has paused typing.
  bool get isPaused => state == TypingState.paused;

  /// Whether the user is done typing.
  bool get isDone => state == TypingState.done;

  @override
  String toString() =>
      'TypingNotification(nick: $nick, target: $target, state: $state)';
}

/// Handles IRCv3 +typing client tag notifications.
///
/// Tracks typing indicators from other users with automatic expiration.
/// According to the spec, typing indicators should expire after:
/// - 6 seconds without a new `active` notification
/// - Immediately when `done` is received
///
/// See: https://ircv3.net/specs/client-tags/typing
class TypingHandler {
  /// Duration after which active typing expires.
  static const Duration defaultActiveExpiry = Duration(seconds: 6);

  /// Duration after which paused typing expires.
  static const Duration defaultPausedExpiry = Duration(seconds: 30);

  final Duration _activeExpiry;
  final Duration _pausedExpiry;

  /// Current typing users per target.
  /// Key: target (channel or nick), Value: map of nick -> notification
  final Map<String, Map<String, TypingNotification>> _typingUsers = {};

  /// Timers for auto-expiring typing indicators.
  final Map<String, Map<String, Timer>> _expiryTimers = {};

  final StreamController<TypingNotification> _notificationController =
      StreamController<TypingNotification>.broadcast();

  final StreamController<TypingExpired> _expiredController =
      StreamController<TypingExpired>.broadcast();

  /// Creates a typing handler.
  ///
  /// [activeExpiry] is how long to keep active typing (default 6s per spec).
  /// [pausedExpiry] is how long to keep paused typing (default 30s).
  TypingHandler({
    Duration activeExpiry = defaultActiveExpiry,
    Duration pausedExpiry = defaultPausedExpiry,
  })  : _activeExpiry = activeExpiry,
        _pausedExpiry = pausedExpiry;

  /// Stream of typing notifications.
  Stream<TypingNotification> get notifications => _notificationController.stream;

  /// Stream of expired typing indicators.
  Stream<TypingExpired> get expired => _expiredController.stream;

  /// Handles an incoming IRC message.
  ///
  /// Returns true if the message was a typing notification, false otherwise.
  bool handleMessage(IrcMessage message) {
    // TAGMSG is used for typing notifications
    if (message.command != 'TAGMSG') {
      return false;
    }

    // Check for +typing tag
    final typingValue = message.tags[IrcTags.typing];
    if (typingValue == null && !message.tags.containsKey(IrcTags.typing)) {
      return false;
    }

    // Parse the typing state
    final state = TypingStateExtension.fromIrcValue(typingValue);
    if (state == null) {
      return false;
    }

    // Parse source
    final parsedSource = message.parsedSource;
    if (parsedSource == null) {
      return false;
    }

    // Get target
    if (message.params.isEmpty) {
      return false;
    }
    final target = message.params[0];

    final notification = TypingNotification(
      nick: parsedSource.nick,
      user: parsedSource.user,
      host: parsedSource.host,
      target: target,
      state: state,
      receivedAt: DateTime.now(),
    );

    _processNotification(notification);
    return true;
  }

  /// Gets all users currently typing in a target.
  List<TypingNotification> getTypingUsers(String target) {
    final users = _typingUsers[target];
    if (users == null) return const [];
    return users.values.toList();
  }

  /// Checks if a specific user is typing in a target.
  bool isUserTyping(String target, String nick) {
    final users = _typingUsers[target];
    if (users == null) return false;
    final notification = users[nick.toLowerCase()];
    if (notification == null) return false;
    return notification.state == TypingState.active ||
        notification.state == TypingState.paused;
  }

  /// Gets the typing state for a user in a target.
  TypingState? getUserTypingState(String target, String nick) {
    final users = _typingUsers[target];
    if (users == null) return null;
    return users[nick.toLowerCase()]?.state;
  }

  /// Clears all typing indicators for a target.
  void clearTarget(String target) {
    _typingUsers.remove(target);
    final timers = _expiryTimers.remove(target);
    timers?.values.forEach((timer) => timer.cancel());
  }

  /// Clears a specific user's typing indicator.
  void clearUser(String target, String nick) {
    final normalizedNick = nick.toLowerCase();
    _typingUsers[target]?.remove(normalizedNick);
    _expiryTimers[target]?[normalizedNick]?.cancel();
    _expiryTimers[target]?.remove(normalizedNick);

    // Clean up empty maps
    if (_typingUsers[target]?.isEmpty ?? false) {
      _typingUsers.remove(target);
    }
    if (_expiryTimers[target]?.isEmpty ?? false) {
      _expiryTimers.remove(target);
    }
  }

  /// Disposes resources.
  void dispose() {
    for (final timers in _expiryTimers.values) {
      for (final timer in timers.values) {
        timer.cancel();
      }
    }
    _expiryTimers.clear();
    _typingUsers.clear();
    _notificationController.close();
    _expiredController.close();
  }

  void _processNotification(TypingNotification notification) {
    final target = notification.target;
    final normalizedNick = notification.nick.toLowerCase();

    // Cancel existing timer
    _expiryTimers[target]?[normalizedNick]?.cancel();

    if (notification.state == TypingState.done) {
      // Remove typing indicator immediately
      _typingUsers[target]?.remove(normalizedNick);
      _expiryTimers[target]?.remove(normalizedNick);

      // Clean up empty maps
      if (_typingUsers[target]?.isEmpty ?? false) {
        _typingUsers.remove(target);
      }
      if (_expiryTimers[target]?.isEmpty ?? false) {
        _expiryTimers.remove(target);
      }
    } else {
      // Update or add typing indicator
      _typingUsers.putIfAbsent(target, () => {});
      _typingUsers[target]![normalizedNick] = notification;

      // Set expiry timer
      final expiry = notification.state == TypingState.active
          ? _activeExpiry
          : _pausedExpiry;

      _expiryTimers.putIfAbsent(target, () => {});
      _expiryTimers[target]![normalizedNick] = Timer(expiry, () {
        _expireTyping(target, normalizedNick, notification);
      });
    }

    // Emit notification
    _notificationController.add(notification);
  }

  void _expireTyping(
    String target,
    String normalizedNick,
    TypingNotification original,
  ) {
    _typingUsers[target]?.remove(normalizedNick);
    _expiryTimers[target]?.remove(normalizedNick);

    // Clean up empty maps
    if (_typingUsers[target]?.isEmpty ?? false) {
      _typingUsers.remove(target);
    }
    if (_expiryTimers[target]?.isEmpty ?? false) {
      _expiryTimers.remove(target);
    }

    _expiredController.add(TypingExpired(
      nick: original.nick,
      target: target,
      lastState: original.state,
    ));
  }
}

/// Represents an expired typing indicator.
class TypingExpired {
  final String nick;
  final String target;
  final TypingState lastState;

  const TypingExpired({
    required this.nick,
    required this.target,
    required this.lastState,
  });

  @override
  String toString() => 'TypingExpired(nick: $nick, target: $target)';
}
