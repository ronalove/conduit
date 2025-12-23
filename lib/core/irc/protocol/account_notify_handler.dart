import 'dart:async';

import '../parser/irc_message.dart';

/// Represents a user's account status change.
class AccountChange {
  /// The nickname of the user.
  final String nick;

  /// The username (ident) of the user.
  final String? user;

  /// The hostname of the user.
  final String? host;

  /// The account name, or null if logged out.
  final String? account;

  /// Whether the user is logged in.
  bool get isLoggedIn => account != null;

  /// Whether the user is logged out.
  bool get isLoggedOut => account == null;

  /// The timestamp of this change.
  final DateTime timestamp;

  const AccountChange({
    required this.nick,
    this.user,
    this.host,
    this.account,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountChange &&
          runtimeType == other.runtimeType &&
          nick == other.nick &&
          user == other.user &&
          host == other.host &&
          account == other.account;

  @override
  int get hashCode => Object.hash(nick, user, host, account);

  @override
  String toString() => 'AccountChange(nick: $nick, account: $account)';
}

/// Handler for IRCv3 account-notify extension.
///
/// Processes ACCOUNT messages to track user account login/logout in real-time.
/// Requires the 'account-notify' capability to be enabled.
///
/// Reference: https://ircv3.net/specs/extensions/account-notify
class AccountNotifyHandler {
  final _changeController = StreamController<AccountChange>.broadcast();

  /// Stream of account changes.
  Stream<AccountChange> get accountChanges => _changeController.stream;

  /// Handles an incoming ACCOUNT message.
  ///
  /// Returns the parsed [AccountChange] if the message is an ACCOUNT message,
  /// or null if it's not an ACCOUNT message.
  AccountChange? handleMessage(IrcMessage message) {
    if (message.command != 'ACCOUNT') {
      return null;
    }

    final source = message.parsedSource;
    if (source == null) {
      return null;
    }

    if (message.params.isEmpty) {
      return null;
    }

    // ACCOUNT accountname = login
    // ACCOUNT * = logout
    final accountParam = message.params.first;
    final account = accountParam == '*' ? null : accountParam;

    final change = AccountChange(
      nick: source.nick,
      user: source.user,
      host: source.host,
      account: account,
      timestamp: DateTime.now(),
    );

    _changeController.add(change);
    return change;
  }

  /// Checks if a message is an ACCOUNT message.
  static bool isAccountMessage(IrcMessage message) =>
      message.command == 'ACCOUNT';

  /// Disposes resources used by this handler.
  void dispose() {
    _changeController.close();
  }
}
