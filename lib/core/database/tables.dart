import 'package:drift/drift.dart';

/// Message status for tracking send state.
enum MessageStatus {
  /// Message is being sent, waiting for echo.
  pending,

  /// Message confirmed by server echo.
  confirmed,

  /// Message failed to send.
  failed,
}

/// Database table for chat messages.
///
/// Only PRIVMSG and NOTICE messages are persisted.
/// Event messages (JOIN/PART/QUIT) are kept in-memory only.
class Messages extends Table {
  /// Unique message ID (msgid from IRC or UUID for pending).
  TextColumn get id => text()();

  /// Channel name (lowercase for indexing).
  TextColumn get channel => text()();

  /// Sender nickname.
  TextColumn get sender => text()();

  /// Message content.
  TextColumn get content => text()();

  /// Unix timestamp in milliseconds.
  IntColumn get timestamp => integer()();

  /// Message type index (0=normal, 1=notice, 2=event, 3=error).
  IntColumn get type => integer()();

  /// Whether message is from current user.
  BoolColumn get isOwn => boolean()();

  /// Whether this is a /me action.
  BoolColumn get isAction => boolean()();

  /// Optional: msgid of replied message.
  TextColumn get replyTo => text().nullable()();

  /// Message status (0=pending, 1=confirmed, 2=failed).
  IntColumn get status => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Database table for tracking read state per channel.
class ChannelReadStates extends Table {
  /// Channel name (lowercase).
  TextColumn get channel => text()();

  /// Last read message ID.
  TextColumn get lastReadId => text().nullable()();

  /// Last read timestamp for ordering.
  IntColumn get lastReadTimestamp => integer().nullable()();

  /// Number of unread messages.
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  /// Whether there's an unread mention.
  BoolColumn get hasMention => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {channel};
}
