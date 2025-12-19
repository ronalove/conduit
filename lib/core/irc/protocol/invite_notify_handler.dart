import 'dart:async';

import '../parser/irc_message.dart';
import '../parser/source_parser.dart';

/// Represents an invitation to a channel.
class InviteNotification {
  /// The nickname of the inviter.
  final String inviterNick;

  /// The username (ident) of the inviter.
  final String? inviterUser;

  /// The hostname of the inviter.
  final String? inviterHost;

  /// The nickname being invited.
  final String invitee;

  /// The channel being invited to.
  final String channel;

  /// The timestamp of this invitation.
  final DateTime timestamp;

  const InviteNotification({
    required this.inviterNick,
    this.inviterUser,
    this.inviterHost,
    required this.invitee,
    required this.channel,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InviteNotification &&
          runtimeType == other.runtimeType &&
          inviterNick == other.inviterNick &&
          inviterUser == other.inviterUser &&
          inviterHost == other.inviterHost &&
          invitee == other.invitee &&
          channel == other.channel;

  @override
  int get hashCode =>
      Object.hash(inviterNick, inviterUser, inviterHost, invitee, channel);

  @override
  String toString() =>
      'InviteNotification(inviter: $inviterNick, invitee: $invitee, channel: $channel)';
}

/// Handler for IRCv3 invite-notify extension.
///
/// Processes INVITE messages to notify channel members of invitations.
/// Requires the 'invite-notify' capability to be enabled.
///
/// Reference: https://ircv3.net/specs/extensions/invite-notify
class InviteNotifyHandler {
  final _inviteController = StreamController<InviteNotification>.broadcast();

  /// Stream of invite notifications.
  Stream<InviteNotification> get invitations => _inviteController.stream;

  /// Handles an incoming INVITE message.
  ///
  /// Format: `:inviter!user@host INVITE invitee #channel`
  ///
  /// Returns the parsed [InviteNotification] if the message is an INVITE,
  /// or null if it's not an INVITE message or malformed.
  InviteNotification? handleMessage(IrcMessage message) {
    if (message.command != 'INVITE') {
      return null;
    }

    final source = message.parsedSource;
    if (source == null) {
      return null;
    }

    // INVITE requires at least 2 params: invitee and channel
    if (message.params.length < 2) {
      return null;
    }

    final invitee = message.params[0];
    final channel = message.params[1];

    final notification = InviteNotification(
      inviterNick: source.nick,
      inviterUser: source.user,
      inviterHost: source.host,
      invitee: invitee,
      channel: channel,
      timestamp: DateTime.now(),
    );

    _inviteController.add(notification);
    return notification;
  }

  /// Checks if a message is an INVITE message.
  static bool isInviteMessage(IrcMessage message) =>
      message.command == 'INVITE';

  /// Disposes resources used by this handler.
  void dispose() {
    _inviteController.close();
  }
}
