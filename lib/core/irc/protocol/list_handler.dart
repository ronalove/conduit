import 'dart:async';

import '../parser/irc_message.dart';

/// Information about a channel from LIST response.
class ListedChannel {
  const ListedChannel({
    required this.name,
    required this.userCount,
    this.topic,
  });

  /// Channel name (including # prefix).
  final String name;

  /// Number of users in the channel.
  final int userCount;

  /// Channel topic, if set.
  final String? topic;

  @override
  String toString() => 'ListedChannel($name, $userCount users)';
}

/// Complete channel list from a LIST command.
class ChannelListUpdate {
  const ChannelListUpdate({
    required this.channels,
  });

  /// List of channels returned by the server.
  final List<ListedChannel> channels;

  /// Number of channels in the list.
  int get count => channels.length;

  /// Whether the list is empty.
  bool get isEmpty => channels.isEmpty;

  /// Whether the list is not empty.
  bool get isNotEmpty => channels.isNotEmpty;

  @override
  String toString() => 'ChannelListUpdate(${channels.length} channels)';
}

/// Handles LIST responses (321, 322, 323) to get channel list.
///
/// The LIST command returns channel information:
/// - 321 (RPL_LISTSTART): Start of channel list (optional, some servers skip this)
/// - 322 (RPL_LIST): Channel info with name, user count, and topic
/// - 323 (RPL_LISTEND): End of the channel list
///
/// This handler accumulates 322 responses and emits a complete
/// [ChannelListUpdate] when 323 is received.
///
/// See: https://modern.ircdocs.horse/#list-message
class ListHandler {
  List<ListedChannel>? _pendingChannels;
  bool _isListening = false;

  final StreamController<ChannelListUpdate> _listController =
      StreamController<ChannelListUpdate>.broadcast();

  /// Stream of completed channel list updates.
  Stream<ChannelListUpdate> get onListReceived => _listController.stream;

  /// Whether a LIST response is currently being accumulated.
  bool get isListPending => _pendingChannels != null;

  /// Handles an incoming IRC message.
  ///
  /// Returns a [ChannelListUpdate] if this message completed a list,
  /// or null otherwise.
  ChannelListUpdate? handleMessage(IrcMessage message) {
    switch (message.command) {
      case '321':
        _handleListStart(message);
        return null;
      case '322':
        _handleList(message);
        return null;
      case '323':
        return _handleListEnd(message);
      default:
        return null;
    }
  }

  /// Start listening for LIST responses.
  ///
  /// Call this before sending a LIST command to ensure the handler
  /// is ready to accumulate responses.
  void startListening() {
    _isListening = true;
    _pendingChannels = [];
  }

  /// Stop listening and clear any pending data.
  void stopListening() {
    _isListening = false;
    _pendingChannels = null;
  }

  /// RPL_LISTSTART (321): :server 321 nick Channel :Users Name
  void _handleListStart(IrcMessage message) {
    // Some servers send this, some don't.
    // Initialize the list if we're listening but haven't started yet.
    if (_isListening && _pendingChannels == null) {
      _pendingChannels = [];
    }
  }

  /// RPL_LIST (322): `:server 322 nick #channel user_count :topic`
  void _handleList(IrcMessage message) {
    // Auto-start listening if we receive a 322 without explicit startListening
    if (!_isListening) {
      _isListening = true;
      _pendingChannels = [];
    }

    // Format: 322 <nick> <channel> <user_count> :<topic>
    if (message.params.length < 3) return;

    final channelName = message.params[1];
    final userCount = int.tryParse(message.params[2]) ?? 0;
    final topic = message.params.length > 3 ? message.params[3] : null;

    final channel = ListedChannel(
      name: channelName,
      userCount: userCount,
      topic: topic?.isNotEmpty == true ? topic : null,
    );

    _pendingChannels?.add(channel);
  }

  /// RPL_LISTEND (323): :server 323 nick :End of /LIST
  ChannelListUpdate? _handleListEnd(IrcMessage message) {
    final channels = _pendingChannels ?? [];
    _pendingChannels = null;
    _isListening = false;

    final update = ChannelListUpdate(channels: channels);
    _listController.add(update);
    return update;
  }

  /// Check if a message is a LIST reply (321, 322, or 323).
  static bool isListMessage(IrcMessage message) {
    return message.command == '321' ||
        message.command == '322' ||
        message.command == '323';
  }

  /// Gets the current count of pending channels.
  int get pendingCount => _pendingChannels?.length ?? 0;

  /// Disposes resources.
  void dispose() {
    _pendingChannels = null;
    _isListening = false;
    _listController.close();
  }
}
