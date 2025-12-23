// Application-wide constants.
//
// Centralizes magic numbers and configuration values for maintainability.

/// Constants for UI dimensions.
abstract final class UiConstants {
  /// Width of the timestamp column in message bubbles.
  static const double timestampWidth = 48;

  /// Width of the nickname column in compact message view.
  static const double nicknameColumnWidth = 100;

  /// Radius of user avatars.
  static const double avatarRadius = 16;
}

/// Constants for message management.
abstract final class MessageConstants {
  /// Maximum number of messages to keep in memory per channel.
  static const int maxMessagesInMemory = 200;

  /// Number of messages to load per batch when fetching history.
  static const int loadBatchSize = 50;

  /// Number of days to retain messages in the database.
  static const int retentionDays = 90;

  /// Duration for message retention cleanup.
  static const Duration retentionDuration = Duration(days: retentionDays);
}

/// Constants for window and persistence.
abstract final class AppBehaviorConstants {
  /// Delay between automatic geometry saves.
  static const Duration autoSaveDelay = Duration(seconds: 2);
}
