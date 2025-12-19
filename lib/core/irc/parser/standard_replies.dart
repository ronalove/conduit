import 'irc_message.dart';

/// Standard reply types per IRCv3 standard-replies specification.
enum StandardReplyType {
  /// Error that prevents the command from executing.
  fail,

  /// Warning about potential issues.
  warn,

  /// Informational note.
  note,
}

/// Represents a parsed IRCv3 standard reply (FAIL/WARN/NOTE).
///
/// Format: `<TYPE> <command> <code> [context...] :<description>`
///
/// Examples:
/// - `FAIL CHATHISTORY INVALID_TARGET #channel :Cannot fetch history`
/// - `WARN * ACCOUNT_REQUIRED :You need to authenticate`
/// - `NOTE JOIN CHANNEL_RENAMED #old #new :Channel renamed`
///
/// See: https://ircv3.net/specs/extensions/standard-replies
class StandardReply {
  /// The reply type (FAIL, WARN, or NOTE).
  final StandardReplyType type;

  /// The command this reply is for (e.g., "CHATHISTORY", "JOIN").
  /// May be "*" for server-wide messages.
  final String command;

  /// Machine-readable code (e.g., "INVALID_TARGET", "ACCOUNT_REQUIRED").
  final String code;

  /// Optional context parameters between code and description.
  final List<String> context;

  /// Human-readable description.
  final String description;

  const StandardReply({
    required this.type,
    required this.command,
    required this.code,
    this.context = const [],
    required this.description,
  });

  /// Whether this is a failure reply.
  bool get isFail => type == StandardReplyType.fail;

  /// Whether this is a warning reply.
  bool get isWarn => type == StandardReplyType.warn;

  /// Whether this is a note reply.
  bool get isNote => type == StandardReplyType.note;

  /// Whether this is a server-wide message (command is "*").
  bool get isServerWide => command == '*';

  /// Returns the full code as "COMMAND_CODE" format.
  String get fullCode => isServerWide ? code : '${command}_$code';

  @override
  String toString() =>
      'StandardReply(${type.name.toUpperCase()} $command $code${context.isNotEmpty ? ' ${context.join(' ')}' : ''}: $description)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StandardReply &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          command == other.command &&
          code == other.code &&
          _listEquals(context, other.context) &&
          description == other.description;

  @override
  int get hashCode =>
      type.hashCode ^
      command.hashCode ^
      code.hashCode ^
      context.hashCode ^
      description.hashCode;

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Parser for IRCv3 standard replies.
abstract class StandardReplyParser {
  /// Parses an IRC message into a standard reply if applicable.
  ///
  /// Returns null if the message is not a standard reply.
  static StandardReply? parse(IrcMessage message) {
    final type = _parseType(message.command);
    if (type == null) return null;

    // Format: TYPE command code [context...] :description
    // params[0] = command
    // params[1] = code
    // params[2...n-1] = context (optional)
    // params[n] = description (trailing)

    if (message.params.length < 3) return null;

    final command = message.params[0];
    final code = message.params[1];

    // Last param is always the description
    final description = message.params.last;

    // Context is everything between code and description
    final context = message.params.length > 3
        ? message.params.sublist(2, message.params.length - 1)
        : <String>[];

    return StandardReply(
      type: type,
      command: command,
      code: code,
      context: context,
      description: description,
    );
  }

  /// Checks if an IRC message is a standard reply.
  static bool isStandardReply(IrcMessage message) {
    return _parseType(message.command) != null;
  }

  /// Checks if a command string is a standard reply command.
  static bool isStandardReplyCommand(String command) {
    return _parseType(command) != null;
  }

  static StandardReplyType? _parseType(String command) {
    switch (command.toUpperCase()) {
      case 'FAIL':
        return StandardReplyType.fail;
      case 'WARN':
        return StandardReplyType.warn;
      case 'NOTE':
        return StandardReplyType.note;
      default:
        return null;
    }
  }
}

/// Extension on IrcMessage for standard reply handling.
extension StandardReplyExtension on IrcMessage {
  /// Whether this message is a standard reply (FAIL/WARN/NOTE).
  bool get isStandardReply => StandardReplyParser.isStandardReply(this);

  /// Parses this message as a standard reply.
  ///
  /// Returns null if not a standard reply.
  StandardReply? get asStandardReply => StandardReplyParser.parse(this);
}

/// Common standard reply codes.
abstract class StandardReplyCodes {
  // Authentication
  static const String accountRequired = 'ACCOUNT_REQUIRED';
  static const String invalidCredentials = 'INVALID_CREDENTIALS';

  // Channels
  static const String invalidTarget = 'INVALID_TARGET';
  static const String channelRenamed = 'CHANNEL_RENAMED';
  static const String noSuchChannel = 'NO_SUCH_CHANNEL';
  static const String cannotJoin = 'CANNOT_JOIN';

  // Messages
  static const String messageTooLong = 'MESSAGE_TOO_LONG';
  static const String cannotSend = 'CANNOT_SEND';

  // Chat history
  static const String invalidParams = 'INVALID_PARAMS';
  static const String needMoreParams = 'NEED_MORE_PARAMS';

  // Rate limiting
  static const String rateLimit = 'RATE_LIMIT';
  static const String tooManyTargets = 'TOO_MANY_TARGETS';

  // General
  static const String unknownCommand = 'UNKNOWN_COMMAND';
  static const String unknownError = 'UNKNOWN_ERROR';
}
