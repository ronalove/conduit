import 'dart:async';

import '../../../features/users/models/channel_user.dart';
import '../parser/irc_message.dart';
import '../parser/user_prefix.dart';

/// Update containing the complete user list for a channel.
class NamesUpdate {
  const NamesUpdate({
    required this.channel,
    required this.users,
  });

  /// Channel name.
  final String channel;

  /// Complete list of users in the channel.
  final List<ChannelUser> users;

  @override
  String toString() => 'NamesUpdate($channel, ${users.length} users)';
}

/// Handles NAMES replies (353, 366) to track channel membership.
///
/// The NAMES command returns user lists for channels:
/// - 353 (RPL_NAMREPLY): List of nicknames with mode prefixes
/// - 366 (RPL_ENDOFNAMES): End of the names list
///
/// This handler accumulates 353 responses and emits a complete
/// [NamesUpdate] when 366 is received.
///
/// See: https://modern.ircdocs.horse/#names-message
class NamesHandler {
  final Map<String, List<ChannelUser>> _pendingNames = {};

  final StreamController<NamesUpdate> _namesController =
      StreamController<NamesUpdate>.broadcast();

  /// Stream of completed names updates.
  Stream<NamesUpdate> get onNamesReceived => _namesController.stream;

  /// Handles an incoming IRC message.
  ///
  /// Returns a [NamesUpdate] if this message completed a names list,
  /// or null otherwise.
  NamesUpdate? handleMessage(IrcMessage message) {
    switch (message.command) {
      case '353':
        _handleNamReply(message);
        return null;
      case '366':
        return _handleEndOfNames(message);
      default:
        return null;
    }
  }

  /// RPL_NAMREPLY (353): :server 353 nick = #channel :@op +voice user
  void _handleNamReply(IrcMessage message) {
    // Format: 353 <nick> <symbol> <channel> :<names>
    // symbol: = (public), * (private), @ (secret)
    if (message.params.length < 4) return;

    final channel = message.params[2].toLowerCase();
    final names = message.params[3];

    // Parse the names with their prefixes
    final prefixedUsers = UserPrefixParser.parseNamesReply(names);

    // Convert to ChannelUser objects
    final users = prefixedUsers.map(_prefixedUserToChannelUser).toList();

    // Accumulate users for this channel
    _pendingNames.putIfAbsent(channel, () => []);
    _pendingNames[channel]!.addAll(users);
  }

  /// RPL_ENDOFNAMES (366): :server 366 nick #channel :End of /NAMES list.
  NamesUpdate? _handleEndOfNames(IrcMessage message) {
    // Format: 366 <nick> <channel> :End of /NAMES list.
    if (message.params.length < 2) return null;

    final channel = message.params[1].toLowerCase();
    final users = _pendingNames.remove(channel) ?? [];

    final update = NamesUpdate(
      channel: channel,
      users: users,
    );

    _namesController.add(update);
    return update;
  }

  /// Convert a PrefixedUser to ChannelUser.
  ChannelUser _prefixedUserToChannelUser(PrefixedUser prefixed) {
    return ChannelUser(
      nickname: prefixed.nick,
      mode: _prefixToUserMode(prefixed.highestPrefix),
    );
  }

  /// Convert UserPrefix to UserMode.
  UserMode _prefixToUserMode(UserPrefix? prefix) {
    if (prefix == null) return UserMode.regular;

    // Map by precedence (lower = higher privilege)
    if (prefix.precedence <= UserPrefix.op.precedence) {
      return UserMode.operator;
    } else if (prefix.precedence <= UserPrefix.halfop.precedence) {
      return UserMode.halfOp;
    } else if (prefix.precedence <= UserPrefix.voice.precedence) {
      return UserMode.voice;
    }
    return UserMode.regular;
  }

  /// Check if a message is a NAMES reply (353 or 366).
  static bool isNamesMessage(IrcMessage message) {
    return message.command == '353' || message.command == '366';
  }

  /// Gets the list of channels currently waiting for names.
  List<String> get pendingChannels => _pendingNames.keys.toList();

  /// Cancels pending names for a channel.
  void cancelPending(String channel) {
    _pendingNames.remove(channel.toLowerCase());
  }

  /// Cancels all pending names.
  void cancelAllPending() {
    _pendingNames.clear();
  }

  /// Disposes resources.
  void dispose() {
    _pendingNames.clear();
    _namesController.close();
  }
}
