import 'dart:async';

import '../parser/irc_message.dart';

/// Monitor numeric codes.
abstract class MonitorNumerics {
  /// RPL_MONONLINE - Users are online.
  static const int mononline = 730;

  /// RPL_MONOFFLINE - Users are offline.
  static const int monoffline = 731;

  /// RPL_MONLIST - Entry in monitored list.
  static const int monlist = 732;

  /// RPL_ENDOFMONLIST - End of monitored list.
  static const int endofmonlist = 733;

  /// ERR_MONLISTFULL - Monitor list is full.
  static const int monlistfull = 734;
}

/// Represents a user's online status from Monitor.
class MonitorStatus {
  /// The nickname.
  final String nick;

  /// Whether the user is online.
  final bool isOnline;

  /// The user's full mask (nick!user@host) if online.
  final String? mask;

  const MonitorStatus({
    required this.nick,
    required this.isOnline,
    this.mask,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonitorStatus &&
          runtimeType == other.runtimeType &&
          nick == other.nick &&
          isOnline == other.isOnline &&
          mask == other.mask;

  @override
  int get hashCode => Object.hash(nick, isOnline, mask);

  @override
  String toString() => 'MonitorStatus(nick: $nick, isOnline: $isOnline)';
}

/// Result type for monitor operations.
sealed class MonitorResult {
  const MonitorResult();
}

/// Users came online.
class MonitorOnline extends MonitorResult {
  final List<MonitorStatus> users;
  const MonitorOnline(this.users);
}

/// Users went offline.
class MonitorOffline extends MonitorResult {
  final List<MonitorStatus> users;
  const MonitorOffline(this.users);
}

/// List of monitored nicknames.
class MonitorList extends MonitorResult {
  final List<String> nicks;
  const MonitorList(this.nicks);
}

/// End of monitor list.
class MonitorListEnd extends MonitorResult {
  const MonitorListEnd();
}

/// Monitor list is full.
class MonitorListFull extends MonitorResult {
  /// The maximum number of entries allowed.
  final int limit;

  /// The targets that could not be added.
  final List<String> targets;

  const MonitorListFull({required this.limit, required this.targets});
}

/// Handler for IRCv3 Monitor extension.
///
/// Tracks user presence (online/offline) notifications.
/// Requires the 'monitor' capability to be enabled.
///
/// Reference: https://ircv3.net/specs/extensions/monitor
class MonitorHandler {
  final _onlineController = StreamController<List<MonitorStatus>>.broadcast();
  final _offlineController = StreamController<List<MonitorStatus>>.broadcast();
  final _listController = StreamController<List<String>>.broadcast();
  final _errorController = StreamController<MonitorListFull>.broadcast();

  /// Stream of users coming online.
  Stream<List<MonitorStatus>> get online => _onlineController.stream;

  /// Stream of users going offline.
  Stream<List<MonitorStatus>> get offline => _offlineController.stream;

  /// Stream of monitor list responses.
  Stream<List<String>> get monitorList => _listController.stream;

  /// Stream of monitor list full errors.
  Stream<MonitorListFull> get listFullErrors => _errorController.stream;

  final List<String> _pendingList = [];

  /// Handles an incoming Monitor-related message.
  ///
  /// Returns the parsed result or null if not a Monitor message.
  MonitorResult? handleMessage(IrcMessage message) {
    // Check for numeric commands
    final numericCode = int.tryParse(message.command);
    if (numericCode != null) {
      return _handleNumeric(numericCode, message);
    }
    return null;
  }

  MonitorResult? _handleNumeric(int code, IrcMessage message) {
    switch (code) {
      case MonitorNumerics.mononline:
        return _handleOnline(message);
      case MonitorNumerics.monoffline:
        return _handleOffline(message);
      case MonitorNumerics.monlist:
        return _handleList(message);
      case MonitorNumerics.endofmonlist:
        return _handleEndOfList();
      case MonitorNumerics.monlistfull:
        return _handleListFull(message);
      default:
        return null;
    }
  }

  /// Handles RPL_MONONLINE (730).
  ///
  /// Format: :server 730 mynick :nick1!user@host,nick2!user@host
  MonitorResult? _handleOnline(IrcMessage message) {
    if (message.params.length < 2) return null;

    final targets = message.params.last;
    final users = _parseOnlineTargets(targets);

    if (users.isNotEmpty) {
      _onlineController.add(users);
      return MonitorOnline(users);
    }
    return null;
  }

  /// Handles RPL_MONOFFLINE (731).
  ///
  /// Format: :server 731 mynick :nick1,nick2,nick3
  MonitorResult? _handleOffline(IrcMessage message) {
    if (message.params.length < 2) return null;

    final targets = message.params.last;
    final users = _parseOfflineTargets(targets);

    if (users.isNotEmpty) {
      _offlineController.add(users);
      return MonitorOffline(users);
    }
    return null;
  }

  /// Handles RPL_MONLIST (732).
  ///
  /// Format: :server 732 mynick :nick1,nick2,nick3
  MonitorResult? _handleList(IrcMessage message) {
    if (message.params.length < 2) return null;

    final targets = message.params.last;
    final nicks = targets.split(',').where((n) => n.isNotEmpty).toList();

    _pendingList.addAll(nicks);
    return MonitorList(nicks);
  }

  /// Handles RPL_ENDOFMONLIST (733).
  MonitorResult _handleEndOfList() {
    final list = List<String>.from(_pendingList);
    _pendingList.clear();

    _listController.add(list);
    return const MonitorListEnd();
  }

  /// Handles ERR_MONLISTFULL (734).
  ///
  /// Format: :server 734 mynick limit targets :Monitor list is full
  MonitorResult? _handleListFull(IrcMessage message) {
    if (message.params.length < 3) return null;

    final limit = int.tryParse(message.params[1]) ?? 0;
    final targets = message.params[2].split(',');

    final error = MonitorListFull(limit: limit, targets: targets);
    _errorController.add(error);
    return error;
  }

  /// Parses online targets from RPL_MONONLINE.
  ///
  /// Online targets include the full mask: nick!user@host
  List<MonitorStatus> _parseOnlineTargets(String targets) {
    return targets.split(',').where((t) => t.isNotEmpty).map((mask) {
      final nick = _extractNickFromMask(mask);
      return MonitorStatus(nick: nick, isOnline: true, mask: mask);
    }).toList();
  }

  /// Parses offline targets from RPL_MONOFFLINE.
  ///
  /// Offline targets are just nicknames.
  List<MonitorStatus> _parseOfflineTargets(String targets) {
    return targets
        .split(',')
        .where((t) => t.isNotEmpty)
        .map((nick) => MonitorStatus(nick: nick, isOnline: false))
        .toList();
  }

  /// Extracts the nickname from a full mask (nick!user@host).
  String _extractNickFromMask(String mask) {
    final bangIndex = mask.indexOf('!');
    if (bangIndex == -1) return mask;
    return mask.substring(0, bangIndex);
  }

  /// Checks if a message is a Monitor-related numeric.
  static bool isMonitorNumeric(IrcMessage message) {
    final code = int.tryParse(message.command);
    if (code == null) return false;
    return code >= 730 && code <= 734;
  }

  /// Disposes resources used by this handler.
  void dispose() {
    _onlineController.close();
    _offlineController.close();
    _listController.close();
    _errorController.close();
  }
}
