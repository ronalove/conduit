import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

/// Main application database for message persistence.
@DriftDatabase(tables: [Messages, ChannelReadStates])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations go here
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'conduit');
  }

  // ============================================================
  // Message Operations
  // ============================================================

  /// Insert a new message.
  Future<void> insertMessage(Message message) async {
    await into(messages).insertOnConflictUpdate(message);
  }

  /// Insert multiple messages (for batch history loading).
  Future<void> insertMessages(List<Message> messageList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(messages, messageList);
    });
  }

  /// Get messages for a channel, ordered by timestamp descending.
  /// Returns newest first, use [limit] and [offset] for pagination.
  Future<List<Message>> getMessagesForChannel(
    String channel, {
    int limit = 50,
    int? beforeTimestamp,
  }) async {
    final query = select(messages)
      ..where((m) => m.channel.equals(channel.toLowerCase()));

    if (beforeTimestamp != null) {
      query.where((m) => m.timestamp.isSmallerThanValue(beforeTimestamp));
    }

    query
      ..orderBy([(m) => OrderingTerm.desc(m.timestamp)])
      ..limit(limit);

    return query.get();
  }

  /// Get a single message by ID.
  Future<Message?> getMessageById(String id) async {
    final query = select(messages)..where((m) => m.id.equals(id));
    return query.getSingleOrNull();
  }

  /// Update message status (pending -> confirmed or failed).
  Future<void> updateMessageStatus(String id, MessageStatus status) async {
    await (update(messages)..where((m) => m.id.equals(id)))
        .write(MessagesCompanion(status: Value(status.index)));
  }

  /// Update message ID (when server assigns msgid on echo).
  Future<void> updateMessageId(String oldId, String newId) async {
    final existing = await getMessageById(oldId);
    if (existing != null) {
      await (delete(messages)..where((m) => m.id.equals(oldId))).go();
      await insertMessage(existing.copyWith(id: newId));
    }
  }

  /// Delete messages older than a certain date.
  Future<int> deleteMessagesOlderThan(DateTime date) async {
    final timestamp = date.millisecondsSinceEpoch;
    return (delete(messages)..where((m) => m.timestamp.isSmallerThanValue(timestamp))).go();
  }

  /// Delete all messages for a channel.
  Future<void> deleteMessagesForChannel(String channel) async {
    await (delete(messages)..where((m) => m.channel.equals(channel.toLowerCase()))).go();
  }

  /// Watch messages for a channel (reactive stream).
  Stream<List<Message>> watchMessagesForChannel(String channel, {int limit = 200}) {
    final query = select(messages)
      ..where((m) => m.channel.equals(channel.toLowerCase()))
      ..orderBy([(m) => OrderingTerm.asc(m.timestamp)])
      ..limit(limit);

    return query.watch();
  }

  // ============================================================
  // Read State Operations
  // ============================================================

  /// Get read state for a channel.
  Future<ChannelReadState?> getReadState(String channel) async {
    final query = select(channelReadStates)
      ..where((r) => r.channel.equals(channel.toLowerCase()));
    return query.getSingleOrNull();
  }

  /// Update read state for a channel.
  Future<void> updateReadState({
    required String channel,
    String? lastReadId,
    int? lastReadTimestamp,
    int? unreadCount,
    bool? hasMention,
  }) async {
    await into(channelReadStates).insertOnConflictUpdate(
      ChannelReadState(
        channel: channel.toLowerCase(),
        lastReadId: lastReadId,
        lastReadTimestamp: lastReadTimestamp,
        unreadCount: unreadCount ?? 0,
        hasMention: hasMention ?? false,
      ),
    );
  }

  /// Increment unread count for a channel.
  Future<void> incrementUnreadCount(String channel, {bool hasMention = false}) async {
    final existing = await getReadState(channel);
    final newCount = (existing?.unreadCount ?? 0) + 1;
    final newHasMention = hasMention || (existing?.hasMention ?? false);

    await updateReadState(
      channel: channel,
      lastReadId: existing?.lastReadId,
      lastReadTimestamp: existing?.lastReadTimestamp,
      unreadCount: newCount,
      hasMention: newHasMention,
    );
  }

  /// Mark channel as read.
  Future<void> markChannelAsRead(String channel, String lastMessageId, int timestamp) async {
    await updateReadState(
      channel: channel,
      lastReadId: lastMessageId,
      lastReadTimestamp: timestamp,
      unreadCount: 0,
      hasMention: false,
    );
  }

  /// Get all channels with unread counts.
  Future<Map<String, int>> getAllUnreadCounts() async {
    final results = await select(channelReadStates).get();
    return {for (final r in results) r.channel: r.unreadCount};
  }
}
