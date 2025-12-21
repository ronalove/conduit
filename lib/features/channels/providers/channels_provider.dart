import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/irc/commands/channel_commands.dart';
import '../../../core/irc/parser/extended_join.dart';
import '../../../core/irc/parser/irc_message.dart';
import '../../../core/irc/parser/irc_parser.dart';
import '../../../core/irc/protocol/names_handler.dart';
import '../../../core/irc/protocol/topic_handler.dart';
import '../../../core/irc/state/connection_state.dart';
import '../../connection/providers/connection_provider.dart';
import '../../connection/providers/irc_session_manager.dart';
import '../../users/models/channel_user.dart';
import '../models/channel.dart';
import '../screens/channel_list_screen.dart';

/// State containing all channel information.
class ChannelsState {
  const ChannelsState({
    this.channels = const {},
    this.selectedChannel,
  });

  /// All joined channels, keyed by lowercase channel name.
  final Map<String, Channel> channels;

  /// Currently selected channel name.
  final String? selectedChannel;

  /// Whether any channels are joined.
  bool get hasChannels => channels.isNotEmpty;

  /// Number of joined channels.
  int get channelCount => channels.length;

  /// Get a channel by name (case-insensitive).
  Channel? getChannel(String name) => channels[name.toLowerCase()];

  /// Get the currently selected channel.
  Channel? get currentChannel =>
      selectedChannel != null ? channels[selectedChannel!.toLowerCase()] : null;

  /// Convert to list of ChannelInfo for UI display.
  List<ChannelInfo> toChannelInfoList() {
    final list = channels.values.map((c) => c.toChannelInfo()).toList();
    // Sort alphabetically by name
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// List of channel names.
  List<String> get channelNames => channels.keys.toList()..sort();

  ChannelsState copyWith({
    Map<String, Channel>? channels,
    String? selectedChannel,
    bool clearSelected = false,
  }) {
    return ChannelsState(
      channels: channels ?? this.channels,
      selectedChannel: clearSelected ? null : (selectedChannel ?? this.selectedChannel),
    );
  }
}

/// Provider for channel state management.
final channelsProvider = NotifierProvider<ChannelsNotifier, ChannelsState>(
  ChannelsNotifier.new,
);

/// Provider for the list of channel info (for UI).
final channelListProvider = Provider<List<ChannelInfo>>((ref) {
  return ref.watch(channelsProvider).toChannelInfoList();
});

/// Provider for the currently selected channel.
final selectedChannelProvider = Provider<Channel?>((ref) {
  return ref.watch(channelsProvider).currentChannel;
});

/// Manages channel state and IRC channel operations.
class ChannelsNotifier extends Notifier<ChannelsState> {
  late NamesHandler _namesHandler;
  late TopicHandler _topicHandler;

  StreamSubscription<String>? _linesSubscription;
  StreamSubscription<NamesUpdate>? _namesSubscription;
  StreamSubscription<TopicUpdate>? _topicSubscription;

  @override
  ChannelsState build() {
    _namesHandler = NamesHandler();
    _topicHandler = TopicHandler();

    // Subscribe to handler streams
    _namesSubscription = _namesHandler.onNamesReceived.listen(_handleNamesUpdate);
    _topicSubscription = _topicHandler.onTopicReceived.listen(_handleTopicUpdate);

    // Check if connection is already active (in case provider is created after login)
    final connection = ref.read(connectionProvider);
    if (connection.phase == ConnectionPhase.registering ||
        connection.phase == ConnectionPhase.connected) {
      // Use Future.microtask to avoid modifying state during build
      Future.microtask(_subscribeToLines);
    }

    // Subscribe to IRC lines as soon as connection enters registering phase
    // This ensures we catch JOIN messages sent by the bouncer immediately after 001
    ref.listen(connectionProvider, (prev, next) {
      final wasActive = prev?.phase == ConnectionPhase.registering ||
          prev?.phase == ConnectionPhase.connected;
      final isActive = next.phase == ConnectionPhase.registering ||
          next.phase == ConnectionPhase.connected;

      if (isActive && !wasActive) {
        _subscribeToLines();
      } else if (!isActive && wasActive) {
        _handleDisconnect();
      }
    });

    // Clean up on dispose
    ref.onDispose(() {
      _linesSubscription?.cancel();
      _namesSubscription?.cancel();
      _topicSubscription?.cancel();
      _namesHandler.dispose();
      _topicHandler.dispose();
    });

    return const ChannelsState();
  }

  void _subscribeToLines() {
    _linesSubscription?.cancel();
    final connectionNotifier = ref.read(connectionProvider.notifier);
    _linesSubscription = connectionNotifier.lines.listen(_handleLine);
  }

  void _handleDisconnect() {
    // Clear all channels on disconnect
    _namesHandler.cancelAllPending();
    _topicHandler.cancelAllPending();
    state = const ChannelsState();
  }

  void _handleLine(String line) {
    final message = IrcParser.parse(line);
    _handleMessage(message);
  }

  void _handleMessage(IrcMessage message) {
    // Route to appropriate handler
    switch (message.command) {
      case 'JOIN':
        _handleJoin(message);
      case 'PART':
        _handlePart(message);
      case 'KICK':
        _handleKick(message);
      case 'QUIT':
        _handleQuit(message);
      case 'NICK':
        _handleNick(message);
      case '353':
      case '366':
        _namesHandler.handleMessage(message);
      case '331':
      case '332':
      case '333':
      case 'TOPIC':
        _topicHandler.handleMessage(message);
    }
  }

  /// Handle JOIN message.
  void _handleJoin(IrcMessage message) {
    final session = ref.read(ircSessionProvider);
    final myNick = session.nickname?.toLowerCase();

    // Parse extended-join or standard join
    final extJoin = ExtendedJoinParser.parse(message);

    final nick = extJoin?.nick ?? message.parsedSource?.nick;
    final channelName = extJoin?.channel ?? (message.params.isNotEmpty ? message.params[0] : null);

    if (nick == null || channelName == null) return;

    final channelKey = channelName.toLowerCase();
    final isMe = nick.toLowerCase() == myNick;

    if (isMe) {
      // We joined a channel - create it if it doesn't exist
      if (!state.channels.containsKey(channelKey)) {
        final newChannel = Channel(
          name: channelName,
          joinedAt: DateTime.now(),
          isJoining: true, // Waiting for NAMES
        );

        state = state.copyWith(
          channels: {...state.channels, channelKey: newChannel},
        );
      }
    } else {
      // Someone else joined - add them to the channel
      final channel = state.channels[channelKey];
      if (channel != null) {
        final user = ChannelUser(
          nickname: nick,
          account: extJoin?.account,
          realname: extJoin?.realname,
        );

        state = state.copyWith(
          channels: {...state.channels, channelKey: channel.addUser(user)},
        );
      }
    }
  }

  /// Handle PART message.
  void _handlePart(IrcMessage message) {
    final session = ref.read(ircSessionProvider);
    final myNick = session.nickname?.toLowerCase();

    final nick = message.parsedSource?.nick;
    final channelName = message.params.isNotEmpty ? message.params[0] : null;

    if (nick == null || channelName == null) return;

    final channelKey = channelName.toLowerCase();
    final isMe = nick.toLowerCase() == myNick;

    if (isMe) {
      // We left the channel - remove it
      final newChannels = Map<String, Channel>.from(state.channels);
      newChannels.remove(channelKey);

      // Clear selection if we left the selected channel
      final clearSelected = state.selectedChannel?.toLowerCase() == channelKey;

      state = state.copyWith(
        channels: newChannels,
        clearSelected: clearSelected,
      );
    } else {
      // Someone else left - remove them from the channel
      final channel = state.channels[channelKey];
      if (channel != null) {
        state = state.copyWith(
          channels: {...state.channels, channelKey: channel.removeUser(nick)},
        );
      }
    }
  }

  /// Handle KICK message.
  void _handleKick(IrcMessage message) {
    final session = ref.read(ircSessionProvider);
    final myNick = session.nickname?.toLowerCase();

    // KICK #channel target :reason
    if (message.params.length < 2) return;

    final channelName = message.params[0];
    final targetNick = message.params[1];
    final channelKey = channelName.toLowerCase();
    final isMe = targetNick.toLowerCase() == myNick;

    if (isMe) {
      // We were kicked - remove the channel
      final newChannels = Map<String, Channel>.from(state.channels);
      newChannels.remove(channelKey);

      final clearSelected = state.selectedChannel?.toLowerCase() == channelKey;

      state = state.copyWith(
        channels: newChannels,
        clearSelected: clearSelected,
      );
    } else {
      // Someone else was kicked - remove them from the channel
      final channel = state.channels[channelKey];
      if (channel != null) {
        state = state.copyWith(
          channels: {...state.channels, channelKey: channel.removeUser(targetNick)},
        );
      }
    }
  }

  /// Handle QUIT message.
  void _handleQuit(IrcMessage message) {
    final nick = message.parsedSource?.nick;
    if (nick == null) return;

    // Remove user from all channels
    final newChannels = <String, Channel>{};
    for (final entry in state.channels.entries) {
      if (entry.value.hasUser(nick)) {
        newChannels[entry.key] = entry.value.removeUser(nick);
      } else {
        newChannels[entry.key] = entry.value;
      }
    }

    if (newChannels != state.channels) {
      state = state.copyWith(channels: newChannels);
    }
  }

  /// Handle NICK message.
  void _handleNick(IrcMessage message) {
    final oldNick = message.parsedSource?.nick;
    final newNick = message.params.isNotEmpty ? message.params[0] : null;

    if (oldNick == null || newNick == null) return;

    // Update nickname in all channels where user exists
    final newChannels = <String, Channel>{};
    for (final entry in state.channels.entries) {
      final channel = entry.value;
      final user = channel.getUser(oldNick);

      if (user != null) {
        // Remove old nick, add with new nick
        var updated = channel.removeUser(oldNick);
        updated = updated.addUser(user.copyWith(nickname: newNick));
        newChannels[entry.key] = updated;
      } else {
        newChannels[entry.key] = channel;
      }
    }

    if (newChannels != state.channels) {
      state = state.copyWith(channels: newChannels);
    }
  }

  /// Handle names update from NamesHandler.
  void _handleNamesUpdate(NamesUpdate update) {
    final channelKey = update.channel.toLowerCase();
    final channel = state.channels[channelKey];

    if (channel != null) {
      // Update channel with new user list
      final updated = channel.withUsers(update.users);

      // Flush any pending topic (some servers don't send 333)
      _topicHandler.flushPendingTopic(update.channel);

      state = state.copyWith(
        channels: {...state.channels, channelKey: updated},
      );
    }
  }

  /// Handle topic update from TopicHandler.
  void _handleTopicUpdate(TopicUpdate update) {
    final channelKey = update.channel.toLowerCase();
    final channel = state.channels[channelKey];

    if (channel != null) {
      final updated = update.hasTopic
          ? channel.copyWith(topic: update.topic)
          : channel.copyWith(clearTopic: true);

      state = state.copyWith(
        channels: {...state.channels, channelKey: updated},
      );
    }
  }

  // =====================
  // Public API
  // =====================

  /// Join a channel.
  void joinChannel(String channel, {String? key}) {
    final session = ref.read(ircSessionProvider);
    if (!session.isReady) return;

    final cmd = JoinCommand(channel, key: key);
    _send(cmd.toRaw());
  }

  /// Part (leave) a channel.
  void partChannel(String channel, {String? message}) {
    final session = ref.read(ircSessionProvider);
    if (!session.isReady) return;

    final cmd = PartCommand(channel, message: message);
    _send(cmd.toRaw());
  }

  /// Set or clear a channel topic.
  void setTopic(String channel, String? topic) {
    final session = ref.read(ircSessionProvider);
    if (!session.isReady) return;

    // Use set with empty string to clear, or set with topic text
    final cmd = TopicCommand.set(channel, topic ?? '');
    _send(cmd.toRaw());
  }

  /// Select a channel.
  void selectChannel(String? channel) {
    state = state.copyWith(
      selectedChannel: channel,
      clearSelected: channel == null,
    );
  }

  /// Mark a channel as read (reset unread count).
  void markAsRead(String channel) {
    final channelKey = channel.toLowerCase();
    final existing = state.channels[channelKey];

    if (existing != null && (existing.unreadCount > 0 || existing.hasMention)) {
      state = state.copyWith(
        channels: {
          ...state.channels,
          channelKey: existing.copyWith(unreadCount: 0, hasMention: false),
        },
      );
    }
  }

  /// Increment unread count for a channel.
  void incrementUnread(String channel, {bool isMention = false}) {
    final channelKey = channel.toLowerCase();
    final existing = state.channels[channelKey];

    if (existing != null) {
      state = state.copyWith(
        channels: {
          ...state.channels,
          channelKey: existing.copyWith(
            unreadCount: existing.unreadCount + 1,
            hasMention: existing.hasMention || isMention,
            lastActivity: DateTime.now(),
          ),
        },
      );
    }
  }

  void _send(String line) {
    try {
      ref.read(connectionProvider.notifier).send(line);
    } catch (e) {
      // Handle send errors
    }
  }
}
