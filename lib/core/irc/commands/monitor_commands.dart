import '../parser/irc_message.dart';
import 'irc_command.dart';

/// Base class for MONITOR commands.
///
/// MONITOR allows tracking user presence (online/offline) without
/// adding them to your friends list or channels.
///
/// Reference: https://ircv3.net/specs/extensions/monitor
sealed class MonitorCommand extends IrcCommand {
  const MonitorCommand();
}

/// MONITOR + - Add targets to the monitor list.
class MonitorAddCommand extends MonitorCommand {
  /// The nicknames to add to the monitor list.
  final List<String> targets;

  /// Creates a MONITOR + command to add targets.
  const MonitorAddCommand(this.targets);

  /// Creates a MONITOR + command with a single target.
  const MonitorAddCommand.single(String target) : targets = const [];

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'MONITOR',
        params: ['+', targets.join(',')],
      );
}

/// MONITOR - - Remove targets from the monitor list.
class MonitorRemoveCommand extends MonitorCommand {
  /// The nicknames to remove from the monitor list.
  final List<String> targets;

  /// Creates a MONITOR - command to remove targets.
  const MonitorRemoveCommand(this.targets);

  /// Creates a MONITOR - command with a single target.
  const MonitorRemoveCommand.single(String target) : targets = const [];

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'MONITOR',
        params: ['-', targets.join(',')],
      );
}

/// MONITOR C - Clear the entire monitor list.
class MonitorClearCommand extends MonitorCommand {
  const MonitorClearCommand();

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'MONITOR',
        params: ['C'],
      );
}

/// MONITOR L - List all monitored nicknames.
class MonitorListCommand extends MonitorCommand {
  const MonitorListCommand();

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'MONITOR',
        params: ['L'],
      );
}

/// MONITOR S - Get the status of all monitored nicknames.
class MonitorStatusCommand extends MonitorCommand {
  const MonitorStatusCommand();

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'MONITOR',
        params: ['S'],
      );
}
