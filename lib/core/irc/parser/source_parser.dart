import 'package:equatable/equatable.dart';

/// Represents a parsed IRC message source (nick!user@host).
class IrcSource extends Equatable {
  final String nick;
  final String? user;
  final String? host;

  const IrcSource({
    required this.nick,
    this.user,
    this.host,
  });

  /// Parses a source string in the format `nick!user@host`.
  ///
  /// Supports variations:
  /// - `nick!user@host` (full)
  /// - `nick@host` (no user)
  /// - `nick!user` (no host)
  /// - `nick` (nick only)
  /// - `server.example.com` (server name)
  factory IrcSource.parse(String source) {
    String nick;
    String? user;
    String? host;

    final bangIndex = source.indexOf('!');
    final atIndex = source.indexOf('@');

    if (bangIndex != -1 && atIndex != -1 && bangIndex < atIndex) {
      // Full format: nick!user@host
      nick = source.substring(0, bangIndex);
      user = source.substring(bangIndex + 1, atIndex);
      host = source.substring(atIndex + 1);
    } else if (bangIndex != -1 && atIndex == -1) {
      // nick!user (no host)
      nick = source.substring(0, bangIndex);
      user = source.substring(bangIndex + 1);
    } else if (atIndex != -1 && bangIndex == -1) {
      // nick@host (no user)
      nick = source.substring(0, atIndex);
      host = source.substring(atIndex + 1);
    } else {
      // nick only or server name
      nick = source;
    }

    return IrcSource(nick: nick, user: user, host: host);
  }

  /// Whether this source looks like a server name.
  ///
  /// Returns true if the nick contains dots and has no user/host parts.
  bool get isServer => nick.contains('.') && user == null && host == null;

  /// Serializes back to raw format.
  String toRaw() {
    if (user != null && host != null) {
      return '$nick!$user@$host';
    } else if (user != null) {
      return '$nick!$user';
    } else if (host != null) {
      return '$nick@$host';
    } else {
      return nick;
    }
  }

  @override
  List<Object?> get props => [nick, user, host];
}
