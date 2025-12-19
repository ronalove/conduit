import '../parser/irc_message.dart';
import 'irc_command.dart';

/// CHATHISTORY command for retrieving message history.
///
/// Used to request historical messages from a target (channel or user).
/// The server responds with messages in a chathistory batch.
///
/// See: https://ircv3.net/specs/extensions/chathistory
class ChathistoryCommand extends IrcCommand {
  final ChathistorySubcommand subcommand;
  final String target;
  final String? criteria;
  final String? endCriteria;
  final int limit;

  const ChathistoryCommand._({
    required this.subcommand,
    required this.target,
    this.criteria,
    this.endCriteria,
    required this.limit,
  });

  /// Requests the most recent messages from a target.
  ///
  /// [target] is the channel or nickname.
  /// [limit] is the maximum number of messages to return.
  factory ChathistoryCommand.latest(String target, int limit) {
    return ChathistoryCommand._(
      subcommand: ChathistorySubcommand.latest,
      target: target,
      criteria: '*',
      limit: limit,
    );
  }

  /// Requests messages before a specific message or timestamp.
  ///
  /// [target] is the channel or nickname.
  /// [criteria] is a msgid or timestamp (e.g., "msgid=abc" or "timestamp=2024-01-01T00:00:00Z").
  /// [limit] is the maximum number of messages to return.
  factory ChathistoryCommand.before(String target, String criteria, int limit) {
    return ChathistoryCommand._(
      subcommand: ChathistorySubcommand.before,
      target: target,
      criteria: criteria,
      limit: limit,
    );
  }

  /// Requests messages after a specific message or timestamp.
  ///
  /// [target] is the channel or nickname.
  /// [criteria] is a msgid or timestamp.
  /// [limit] is the maximum number of messages to return.
  factory ChathistoryCommand.after(String target, String criteria, int limit) {
    return ChathistoryCommand._(
      subcommand: ChathistorySubcommand.after,
      target: target,
      criteria: criteria,
      limit: limit,
    );
  }

  /// Requests messages around a specific message or timestamp.
  ///
  /// Returns messages both before and after the criteria.
  /// [target] is the channel or nickname.
  /// [criteria] is a msgid or timestamp.
  /// [limit] is the maximum number of messages to return (split around criteria).
  factory ChathistoryCommand.around(String target, String criteria, int limit) {
    return ChathistoryCommand._(
      subcommand: ChathistorySubcommand.around,
      target: target,
      criteria: criteria,
      limit: limit,
    );
  }

  /// Requests messages between two points.
  ///
  /// [target] is the channel or nickname.
  /// [startCriteria] is the starting msgid or timestamp.
  /// [endCriteria] is the ending msgid or timestamp.
  /// [limit] is the maximum number of messages to return.
  factory ChathistoryCommand.between(
    String target,
    String startCriteria,
    String endCriteria,
    int limit,
  ) {
    return ChathistoryCommand._(
      subcommand: ChathistorySubcommand.between,
      target: target,
      criteria: startCriteria,
      endCriteria: endCriteria,
      limit: limit,
    );
  }

  /// Requests a list of targets with recent messages.
  ///
  /// Returns targets (channels/users) that have messages in the given time range.
  /// [startTimestamp] is the start of the range (ISO 8601 or timestamp=...).
  /// [endTimestamp] is the end of the range.
  /// [limit] is the maximum number of targets to return.
  factory ChathistoryCommand.targets(
    String startTimestamp,
    String endTimestamp,
    int limit,
  ) {
    return ChathistoryCommand._(
      subcommand: ChathistorySubcommand.targets,
      target: startTimestamp,
      criteria: endTimestamp,
      limit: limit,
    );
  }

  @override
  IrcMessage toMessage() {
    final params = <String>[];
    params.add(subcommand.name.toUpperCase());

    switch (subcommand) {
      case ChathistorySubcommand.latest:
        params.add(target);
        params.add(criteria!);
        params.add(limit.toString());

      case ChathistorySubcommand.before:
      case ChathistorySubcommand.after:
      case ChathistorySubcommand.around:
        params.add(target);
        params.add(criteria!);
        params.add(limit.toString());

      case ChathistorySubcommand.between:
        params.add(target);
        params.add(criteria!);
        params.add(endCriteria!);
        params.add(limit.toString());

      case ChathistorySubcommand.targets:
        params.add(target); // startTimestamp
        params.add(criteria!); // endTimestamp
        params.add(limit.toString());
    }

    return IrcMessage(
      command: 'CHATHISTORY',
      params: params,
    );
  }
}

/// Subcommands for CHATHISTORY.
enum ChathistorySubcommand {
  /// Get the most recent messages.
  latest,

  /// Get messages before a specific point.
  before,

  /// Get messages after a specific point.
  after,

  /// Get messages around a specific point.
  around,

  /// Get messages between two points.
  between,

  /// Get list of targets with recent messages.
  targets,
}

/// Utilities for creating CHATHISTORY criteria.
abstract class ChathistoryCriteria {
  /// Creates a msgid criteria.
  static String msgid(String id) => 'msgid=$id';

  /// Creates a timestamp criteria from DateTime.
  static String timestamp(DateTime time) =>
      'timestamp=${time.toUtc().toIso8601String()}';

  /// Creates a timestamp criteria from ISO 8601 string.
  static String timestampString(String iso8601) => 'timestamp=$iso8601';

  /// Parses a criteria string into its type and value.
  ///
  /// Returns null if the criteria is not in a recognized format.
  static ({String type, String value})? parse(String criteria) {
    if (criteria == '*') return null;

    final eqIndex = criteria.indexOf('=');
    if (eqIndex == -1) return null;

    return (
      type: criteria.substring(0, eqIndex),
      value: criteria.substring(eqIndex + 1),
    );
  }

  /// Checks if criteria is a msgid reference.
  static bool isMsgid(String criteria) => criteria.startsWith('msgid=');

  /// Checks if criteria is a timestamp reference.
  static bool isTimestamp(String criteria) => criteria.startsWith('timestamp=');
}
