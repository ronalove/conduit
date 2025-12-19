import '../parser/irc_message.dart';
import 'irc_command.dart';

/// MARKREAD command for tracking read position.
///
/// Used to mark messages as read and sync read position across sessions.
///
/// Format: `MARKREAD <target> [timestamp=<timestamp>]`
///
/// See: https://ircv3.net/specs/extensions/read-marker
class MarkreadCommand extends IrcCommand {
  /// The target (channel or nickname).
  final String target;

  /// Optional timestamp to mark as read up to.
  final DateTime? timestamp;

  const MarkreadCommand({
    required this.target,
    this.timestamp,
  });

  /// Creates a MARKREAD command to query current read position.
  ///
  /// Sends MARKREAD without timestamp to get the server's stored position.
  factory MarkreadCommand.query(String target) {
    return MarkreadCommand(target: target);
  }

  /// Creates a MARKREAD command to set read position.
  ///
  /// [target] is the channel or nickname.
  /// [timestamp] is the time to mark as read up to.
  factory MarkreadCommand.mark(String target, DateTime timestamp) {
    return MarkreadCommand(target: target, timestamp: timestamp);
  }

  /// Creates a MARKREAD command from a message ID's timestamp.
  ///
  /// This is a convenience for marking read up to a specific message.
  factory MarkreadCommand.fromTimestamp(String target, String timestampString) {
    final time = DateTime.tryParse(timestampString);
    return MarkreadCommand(target: target, timestamp: time);
  }

  @override
  IrcMessage toMessage() {
    final params = <String>[target];

    if (timestamp != null) {
      params.add('timestamp=${timestamp!.toUtc().toIso8601String()}');
    }

    return IrcMessage(
      command: 'MARKREAD',
      params: params,
    );
  }
}
