import 'dart:async';

import '../parser/irc_message.dart';

/// Represents a read marker update.
class ReadMarkerUpdate {
  /// The target (channel or nickname).
  final String target;

  /// The timestamp up to which messages are read.
  final DateTime? timestamp;

  /// The source of the update (nick!user@host).
  final String? source;

  /// Whether this update is from the current user.
  final bool isOwnUpdate;

  const ReadMarkerUpdate({
    required this.target,
    this.timestamp,
    this.source,
    this.isOwnUpdate = false,
  });

  @override
  String toString() {
    return 'ReadMarkerUpdate(target: $target, timestamp: $timestamp, isOwnUpdate: $isOwnUpdate)';
  }
}

/// Handles IRCv3 read-marker extension.
///
/// Tracks read position for channels and conversations, allowing sync
/// across multiple sessions/devices.
///
/// See: https://ircv3.net/specs/extensions/read-marker
class ReadMarkerHandler {
  final StreamController<ReadMarkerUpdate> _updateController =
      StreamController<ReadMarkerUpdate>.broadcast();

  /// Current user's nickname for detecting own updates.
  String? currentNick;

  /// Stream of read marker updates.
  Stream<ReadMarkerUpdate> get onUpdate => _updateController.stream;

  /// Stored read positions by target.
  final Map<String, DateTime> _readPositions = {};

  /// Gets the stored read position for a target.
  DateTime? getReadPosition(String target) => _readPositions[target.toLowerCase()];

  /// Gets all stored read positions.
  Map<String, DateTime> get readPositions => Map.unmodifiable(_readPositions);

  /// Handles an incoming MARKREAD message.
  ///
  /// Returns a [ReadMarkerUpdate] if the message was handled.
  /// Returns null if the message is not a MARKREAD.
  ReadMarkerUpdate? handleMessage(IrcMessage message) {
    if (message.command != 'MARKREAD') return null;
    if (message.params.isEmpty) return null;

    final target = message.params[0];
    DateTime? timestamp;

    // Look for timestamp parameter
    if (message.params.length > 1) {
      final timestampParam = message.params[1];
      timestamp = _parseTimestamp(timestampParam);
    }

    // Determine if this is from current user
    final isOwn = _isOwnUpdate(message.source);

    // Store the position
    if (timestamp != null) {
      final key = target.toLowerCase();
      final existing = _readPositions[key];
      // Only update if newer
      if (existing == null || timestamp.isAfter(existing)) {
        _readPositions[key] = timestamp;
      }
    }

    final update = ReadMarkerUpdate(
      target: target,
      timestamp: timestamp,
      source: message.source,
      isOwnUpdate: isOwn,
    );

    _updateController.add(update);
    return update;
  }

  DateTime? _parseTimestamp(String param) {
    // Format: timestamp=2024-01-01T00:00:00Z
    if (param.startsWith('timestamp=')) {
      final timeStr = param.substring(10);
      return DateTime.tryParse(timeStr);
    }
    // Try parsing directly in case it's just a timestamp
    return DateTime.tryParse(param);
  }

  bool _isOwnUpdate(String? source) {
    if (source == null || currentNick == null) return false;

    // Extract nick from source (nick!user@host)
    final bangIndex = source.indexOf('!');
    final nick = bangIndex > 0 ? source.substring(0, bangIndex) : source;

    return nick.toLowerCase() == currentNick!.toLowerCase();
  }

  /// Updates the read position for a target locally.
  ///
  /// This should be called after sending a MARKREAD command.
  void setReadPosition(String target, DateTime timestamp) {
    final key = target.toLowerCase();
    final existing = _readPositions[key];
    if (existing == null || timestamp.isAfter(existing)) {
      _readPositions[key] = timestamp;
    }
  }

  /// Checks if a message is unread based on the read position.
  ///
  /// Returns true if the message timestamp is after the read position.
  /// Returns null if no read position is stored for the target.
  bool? isUnread(String target, DateTime messageTimestamp) {
    final readTime = _readPositions[target.toLowerCase()];
    if (readTime == null) return null;
    return messageTimestamp.isAfter(readTime);
  }

  /// Clears the read position for a target.
  void clearReadPosition(String target) {
    _readPositions.remove(target.toLowerCase());
  }

  /// Clears all stored read positions.
  void clearAllReadPositions() {
    _readPositions.clear();
  }

  /// The capability name for read-marker.
  static const String capabilityName = 'draft/read-marker';

  /// Disposes resources.
  void dispose() {
    _updateController.close();
  }
}
