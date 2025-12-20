import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/irc/commands/message_commands.dart';
import '../../../core/irc/parser/irc_message.dart';
import '../../../core/irc/parser/irc_message_extensions.dart';
import '../../../core/irc/parser/irc_parser.dart';
import '../../../core/irc/parser/message_tags.dart';
import '../../../core/irc/protocol/echo_message_handler.dart';
import '../../channels/providers/channels_provider.dart';
import '../../connection/providers/connection_provider.dart';
import '../../connection/providers/irc_session_manager.dart';
import '../models/chat_message.dart';
import '../models/messages_state.dart';

/// Provider for the application database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();

  // Clean up old messages on startup (90 days retention)
  final cutoff = DateTime.now().subtract(const Duration(days: 90));
  db.deleteMessagesOlderThan(cutoff);

  ref.onDispose(() => db.close());
  return db;
});

/// Provider for messages state management.
final messagesProvider = NotifierProvider<MessagesNotifier, MessagesState>(
  MessagesNotifier.new,
);

/// Provider for current channel's messages.
final currentChannelMessagesProvider = Provider<ChannelMessagesState?>((ref) {
  final selectedChannel = ref.watch(selectedChannelProvider);
  if (selectedChannel == null) return null;
  return ref.watch(messagesProvider).getChannel(selectedChannel.name);
});

/// Manages messages state and IRC message operations.
class MessagesNotifier extends Notifier<MessagesState> {
  late MutableEchoMessageHandler _echoHandler;
  late AppDatabase _db;

  StreamSubscription<String>? _linesSubscription;

  /// Maximum messages to keep in memory per channel.
  static const int _maxMessagesInMemory = 200;

  /// Messages to load per page.
  static const int _loadBatchSize = 50;

  @override
  MessagesState build() {
    _db = ref.read(appDatabaseProvider);

    // Initialize echo handler with current nick
    final session = ref.read(ircSessionProvider);
    _echoHandler = MutableEchoMessageHandler(
      currentNick: session.nickname ?? '',
    );

    // Subscribe to IRC session for nick changes and readiness
    ref.listen(ircSessionProvider, (prev, next) {
      if (next.nickname != null && next.nickname != prev?.nickname) {
        _echoHandler.updateNick(next.nickname!);
      }
      if (next.isReady && (prev == null || !prev.isReady)) {
        _subscribeToLines();
      }
      if (!next.isReady && (prev?.isReady ?? false)) {
        _handleDisconnect();
      }
    });

    // Subscribe if session already ready
    if (session.isReady) {
      Future.microtask(_subscribeToLines);
    }

    // Clean up on dispose
    ref.onDispose(() {
      _linesSubscription?.cancel();
      _echoHandler.dispose();
    });

    return const MessagesState();
  }

  void _subscribeToLines() {
    _linesSubscription?.cancel();
    final connectionNotifier = ref.read(connectionProvider.notifier);
    _linesSubscription = connectionNotifier.lines.listen(_handleLine);
  }

  void _handleDisconnect() {
    _echoHandler.clearPending();
    // Keep messages in state but clear pending status
    state = const MessagesState();
  }

  void _handleLine(String line) {
    final message = IrcParser.parse(line);
    switch (message.command) {
      case 'PRIVMSG':
        _handlePrivmsg(message);
      case 'NOTICE':
        _handleNotice(message);
      case 'JOIN':
        _handleJoin(message);
      case 'PART':
        _handlePart(message);
      case 'QUIT':
        _handleQuit(message);
      case 'KICK':
        _handleKick(message);
      case 'TOPIC':
        _handleTopic(message);
    }
  }

  /// Handle PRIVMSG command.
  void _handlePrivmsg(IrcMessage message) {
    if (message.params.length < 2) return;

    final target = message.params[0];
    final text = message.params[1];

    // Determine channel: if target is us, use sender's nick (PM)
    final session = ref.read(ircSessionProvider);
    final myNick = session.nickname?.toLowerCase();
    final senderNick = message.parsedSource?.nick ?? 'unknown';

    String channel;
    if (target.toLowerCase() == myNick) {
      // Private message - use sender as channel
      channel = senderNick;
    } else {
      channel = target;
    }

    // Check for CTCP ACTION (/me)
    final isAction = text.startsWith('\x01ACTION ') && text.endsWith('\x01');
    final content = isAction ? text.substring(8, text.length - 1) : text;

    // Check if this is an echo of our own message
    final echoResult = _echoHandler.checkMessage(message);

    switch (echoResult) {
      case IsEcho(:final pending, :final confirmed):
        _confirmPendingMessage(
          channel: channel,
          pendingClientId: pending.clientMsgId,
          serverMsgId: confirmed.msgId,
          serverTime: confirmed.serverTime,
        );
      case NotEcho():
        _addIncomingMessage(
          channel: channel,
          sender: senderNick,
          content: content,
          message: message,
          type: MessageType.normal,
          isAction: isAction,
        );
    }
  }

  /// Handle NOTICE command.
  void _handleNotice(IrcMessage message) {
    if (message.params.length < 2) return;

    final target = message.params[0];
    final text = message.params[1];

    final session = ref.read(ircSessionProvider);
    final myNick = session.nickname?.toLowerCase();
    final senderNick = message.parsedSource?.nick ?? 'server';

    String channel;
    if (target.toLowerCase() == myNick || target == '*') {
      // Server notice or PM notice
      channel = senderNick;
    } else {
      channel = target;
    }

    _addIncomingMessage(
      channel: channel,
      sender: senderNick,
      content: text,
      message: message,
      type: MessageType.notice,
      isAction: false,
    );
  }

  // =====================
  // Event Handlers (in-memory only)
  // =====================

  /// Handle JOIN event.
  void _handleJoin(IrcMessage message) {
    final nick = message.parsedSource?.nick;
    final channelName = message.params.isNotEmpty ? message.params[0] : null;

    if (nick == null || channelName == null) return;

    final session = ref.read(ircSessionProvider);
    final myNick = session.nickname?.toLowerCase();

    // Don't show our own join
    if (nick.toLowerCase() == myNick) return;

    addEventMessage(
      channel: channelName,
      sender: nick,
      content: '$nick has joined',
    );
  }

  /// Handle PART event.
  void _handlePart(IrcMessage message) {
    final nick = message.parsedSource?.nick;
    final channelName = message.params.isNotEmpty ? message.params[0] : null;
    final reason = message.params.length > 1 ? message.params[1] : null;

    if (nick == null || channelName == null) return;

    final session = ref.read(ircSessionProvider);
    final myNick = session.nickname?.toLowerCase();

    // Don't show our own part
    if (nick.toLowerCase() == myNick) return;

    final content = reason != null && reason.isNotEmpty
        ? '$nick has left ($reason)'
        : '$nick has left';

    addEventMessage(
      channel: channelName,
      sender: nick,
      content: content,
    );
  }

  /// Handle QUIT event.
  void _handleQuit(IrcMessage message) {
    final nick = message.parsedSource?.nick;
    final reason = message.params.isNotEmpty ? message.params[0] : null;

    if (nick == null) return;

    final content = reason != null && reason.isNotEmpty
        ? '$nick has quit ($reason)'
        : '$nick has quit';

    // Add quit message to all channels where user was present
    for (final channelKey in state.channels.keys) {
      addEventMessage(
        channel: channelKey,
        sender: nick,
        content: content,
      );
    }
  }

  /// Handle KICK event.
  void _handleKick(IrcMessage message) {
    if (message.params.length < 2) return;

    final channelName = message.params[0];
    final targetNick = message.params[1];
    final reason = message.params.length > 2 ? message.params[2] : null;
    final kickerNick = message.parsedSource?.nick ?? 'server';

    final content = reason != null && reason.isNotEmpty
        ? '$targetNick was kicked by $kickerNick ($reason)'
        : '$targetNick was kicked by $kickerNick';

    addEventMessage(
      channel: channelName,
      sender: kickerNick,
      content: content,
    );
  }

  /// Handle TOPIC event.
  void _handleTopic(IrcMessage message) {
    if (message.params.isEmpty) return;

    final channelName = message.params[0];
    final newTopic = message.params.length > 1 ? message.params[1] : null;
    final nick = message.parsedSource?.nick ?? 'server';

    final content = newTopic != null && newTopic.isNotEmpty
        ? '$nick changed the topic to: $newTopic'
        : '$nick cleared the topic';

    addEventMessage(
      channel: channelName,
      sender: nick,
      content: content,
    );
  }

  /// Add incoming message to state and DB.
  void _addIncomingMessage({
    required String channel,
    required String sender,
    required String content,
    required IrcMessage message,
    required MessageType type,
    required bool isAction,
  }) {
    final channelKey = channel.toLowerCase();
    final session = ref.read(ircSessionProvider);
    final myNick = session.nickname?.toLowerCase() ?? '';

    // Extract message metadata
    final msgId = message.msgId ?? _generateId();
    final timestamp = message.serverTime ?? DateTime.now();
    final replyTo = message.replyTargetMsgId;
    final isOwn = sender.toLowerCase() == myNick;

    final chatMessage = ChatMessage(
      id: msgId,
      sender: sender,
      content: content,
      timestamp: timestamp,
      type: type,
      isOwn: isOwn,
      replyTo: replyTo,
      isAction: isAction,
      status: MessageStatus.confirmed,
    );

    // Check for mention
    final hasMention = !isOwn && _isMention(content, session.nickname ?? '');

    // Add to state
    _addMessageToState(channelKey, chatMessage, hasMention: hasMention);

    // Persist to database (only PRIVMSG/NOTICE)
    _persistMessage(channelKey, chatMessage);

    // Update unread count in channels provider if not selected
    _updateUnreadCount(channelKey, hasMention);
  }

  /// Confirm a pending message after echo.
  void _confirmPendingMessage({
    required String channel,
    required String? pendingClientId,
    required String? serverMsgId,
    required DateTime? serverTime,
  }) {
    if (pendingClientId == null) return;

    final channelKey = channel.toLowerCase();
    final channelState = state.getChannel(channelKey);
    if (channelState == null) return;

    // Find pending message
    final messages = List<ChatMessage>.from(channelState.messages);
    final index = messages.indexWhere((m) => m.id == pendingClientId);

    if (index != -1) {
      final pending = messages[index];
      final confirmed = pending.copyWith(
        id: serverMsgId ?? pending.id,
        timestamp: serverTime ?? pending.timestamp,
        status: MessageStatus.confirmed,
      );
      messages[index] = confirmed;

      state = state.updateChannel(
        channelKey,
        channelState.copyWith(messages: messages),
      );

      // Update DB with server ID
      if (serverMsgId != null && serverMsgId != pendingClientId) {
        _db.updateMessageId(pendingClientId, serverMsgId);
      }
      _db.updateMessageStatus(serverMsgId ?? pendingClientId, MessageStatus.confirmed);
    }
  }

  /// Add a message to state.
  void _addMessageToState(String channelKey, ChatMessage message, {bool hasMention = false}) {
    var channelState = state.getChannel(channelKey);

    if (channelState == null) {
      channelState = ChannelMessagesState(
        channel: channelKey,
        messages: [message],
        oldestMessageId: message.id,
      );
    } else {
      var messages = List<ChatMessage>.from(channelState.messages);
      messages.add(message);

      // Trim if exceeding max
      if (messages.length > _maxMessagesInMemory) {
        messages = messages.sublist(messages.length - _maxMessagesInMemory);
      }

      channelState = channelState.copyWith(
        messages: messages,
        oldestMessageId: messages.isNotEmpty ? messages.first.id : null,
      );
    }

    state = state.updateChannel(channelKey, channelState);
  }

  /// Persist message to database.
  Future<void> _persistMessage(String channelKey, ChatMessage chatMessage) async {
    final dbMessage = Message(
      id: chatMessage.id,
      channel: channelKey,
      sender: chatMessage.sender,
      content: chatMessage.content,
      timestamp: chatMessage.timestamp.millisecondsSinceEpoch,
      type: chatMessage.type.index,
      isOwn: chatMessage.isOwn,
      isAction: chatMessage.isAction,
      replyTo: chatMessage.replyTo,
      status: chatMessage.status.index,
    );
    await _db.insertMessage(dbMessage);
  }

  /// Update unread count for non-selected channel.
  void _updateUnreadCount(String channelKey, bool hasMention) {
    final selectedChannel = ref.read(selectedChannelProvider);
    if (selectedChannel?.name.toLowerCase() == channelKey) {
      return; // Don't increment unread for selected channel
    }

    ref.read(channelsProvider.notifier).incrementUnread(
          channelKey,
          isMention: hasMention,
        );
  }

  /// Check if message mentions the user.
  bool _isMention(String content, String currentNick) {
    if (currentNick.isEmpty) return false;
    final pattern = RegExp(
      r'\b' + RegExp.escape(currentNick) + r'\b',
      caseSensitive: false,
    );
    return pattern.hasMatch(content);
  }

  /// Generate a unique ID for messages without msgid tag.
  String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  }

  // =====================
  // Public API
  // =====================

  /// Send a message to a channel.
  Future<void> sendMessage(String channel, String text, {String? replyTo}) async {
    final session = ref.read(ircSessionProvider);
    if (!session.isReady || session.nickname == null) return;

    final channelKey = channel.toLowerCase();
    final clientMsgId = _generateId();

    // Check for CTCP ACTION
    final isAction = text.startsWith('/me ');
    String content;
    String rawMessage;

    if (isAction) {
      content = text.substring(4); // Remove '/me '
      rawMessage = '\x01ACTION $content\x01';
    } else {
      content = text;
      rawMessage = text;
    }

    // Create pending message
    final pendingMessage = ChatMessage(
      id: clientMsgId,
      sender: session.nickname!,
      content: content,
      timestamp: DateTime.now(),
      type: MessageType.normal,
      isOwn: true,
      replyTo: replyTo,
      isAction: isAction,
      status: MessageStatus.pending,
    );

    // Add to state immediately
    _addMessageToState(channelKey, pendingMessage);

    // Track with echo handler
    _echoHandler.trackOutgoing(
      target: channel,
      text: rawMessage,
      clientMsgId: clientMsgId,
    );

    // Build and send command
    final tags = <String, String?>{};
    if (replyTo != null) {
      tags[IrcTags.replyTo] = replyTo;
    }

    final cmd = PrivmsgCommand(
      target: channel,
      message: rawMessage,
      tags: tags.isNotEmpty ? tags : null,
    );

    ref.read(connectionProvider.notifier).send(cmd.toRaw());

    // Persist pending message
    await _persistMessage(channelKey, pendingMessage);
  }

  /// Load older messages from database.
  Future<void> loadMoreHistory(String channel) async {
    final channelKey = channel.toLowerCase();
    var channelState = state.getChannel(channelKey);

    if (channelState == null || channelState.isLoadingHistory) return;

    // Set loading flag
    state = state.updateChannel(
      channelKey,
      channelState.copyWith(isLoadingHistory: true),
    );

    try {
      // Get oldest message timestamp
      int? beforeTimestamp;
      if (channelState.messages.isNotEmpty) {
        beforeTimestamp = channelState.messages.first.timestamp.millisecondsSinceEpoch;
      }

      // Load from database
      final dbMessages = await _db.getMessagesForChannel(
        channelKey,
        limit: _loadBatchSize,
        beforeTimestamp: beforeTimestamp,
      );

      if (dbMessages.isEmpty) {
        // No more history
        state = state.updateChannel(
          channelKey,
          state.getChannel(channelKey)!.copyWith(isLoadingHistory: false),
        );
        return;
      }

      // Convert to ChatMessage
      final olderMessages = dbMessages.reversed.map((m) => ChatMessage(
            id: m.id,
            sender: m.sender,
            content: m.content,
            timestamp: DateTime.fromMillisecondsSinceEpoch(m.timestamp),
            type: MessageType.values[m.type],
            isOwn: m.isOwn,
            replyTo: m.replyTo,
            isAction: m.isAction,
            status: MessageStatus.values[m.status],
          )).toList();

      // Prepend to existing messages
      channelState = state.getChannel(channelKey)!;
      final allMessages = [...olderMessages, ...channelState.messages];

      state = state.updateChannel(
        channelKey,
        channelState.copyWith(
          messages: allMessages,
          isLoadingHistory: false,
          oldestMessageId: olderMessages.isNotEmpty ? olderMessages.first.id : null,
        ),
      );
    } catch (e) {
      // Reset loading flag on error
      state = state.updateChannel(
        channelKey,
        state.getChannel(channelKey)!.copyWith(isLoadingHistory: false),
      );
    }
  }

  /// Load initial messages for a channel from database.
  Future<void> loadChannelMessages(String channel) async {
    final channelKey = channel.toLowerCase();

    // Skip if already loaded
    if (state.getChannel(channelKey) != null) return;

    final dbMessages = await _db.getMessagesForChannel(
      channelKey,
      limit: _loadBatchSize,
    );

    if (dbMessages.isEmpty) {
      // Create empty state
      state = state.updateChannel(
        channelKey,
        ChannelMessagesState(channel: channelKey),
      );
      return;
    }

    // Convert and add to state (reversed because DB returns newest first)
    final messages = dbMessages.reversed.map((m) => ChatMessage(
          id: m.id,
          sender: m.sender,
          content: m.content,
          timestamp: DateTime.fromMillisecondsSinceEpoch(m.timestamp),
          type: MessageType.values[m.type],
          isOwn: m.isOwn,
          replyTo: m.replyTo,
          isAction: m.isAction,
          status: MessageStatus.values[m.status],
        )).toList();

    state = state.updateChannel(
      channelKey,
      ChannelMessagesState(
        channel: channelKey,
        messages: messages,
        oldestMessageId: messages.isNotEmpty ? messages.first.id : null,
      ),
    );
  }

  /// Mark a channel as read.
  void markChannelAsRead(String channel) {
    final channelKey = channel.toLowerCase();
    final channelState = state.getChannel(channelKey);

    if (channelState == null) return;

    // Reset unread count
    state = state.updateChannel(
      channelKey,
      channelState.copyWith(unreadCount: 0, hasMention: false),
    );

    // Update database
    if (channelState.messages.isNotEmpty) {
      final lastMessage = channelState.messages.last;
      _db.markChannelAsRead(
        channelKey,
        lastMessage.id,
        lastMessage.timestamp.millisecondsSinceEpoch,
      );
    }

    // Update channels provider
    ref.read(channelsProvider.notifier).markAsRead(channel);
  }

  /// Add an event message (in-memory only, not persisted).
  void addEventMessage({
    required String channel,
    required String sender,
    required String content,
  }) {
    final channelKey = channel.toLowerCase();
    final message = ChatMessage(
      id: _generateId(),
      sender: sender,
      content: content,
      timestamp: DateTime.now(),
      type: MessageType.event,
      isOwn: false,
      status: MessageStatus.confirmed,
    );

    _addMessageToState(channelKey, message);
    // Note: Event messages are NOT persisted to database
  }

  /// Clear all messages for a channel.
  void clearChannel(String channel) {
    final channelKey = channel.toLowerCase();
    state = state.removeChannel(channelKey);
  }
}
