import 'package:equatable/equatable.dart';
import 'source_parser.dart';
import 'irc_parser.dart';

/// Represents a parsed IRC message.
///
/// Format: `[@tags] [:source] <command> [params] [:trailing]`
class IrcMessage extends Equatable {
  final Map<String, String?> tags;
  final String? source;
  final String command;
  final List<String> params;

  const IrcMessage({
    this.tags = const {},
    this.source,
    required this.command,
    this.params = const [],
  });

  /// Whether the message has any tags.
  bool get hasTags => tags.isNotEmpty;

  /// Whether the message has a source.
  bool get hasSource => source != null;

  /// Returns the last parameter (trailing), or null if no params.
  String? get trailing => params.isNotEmpty ? params.last : null;

  /// Parses the source into an [IrcSource], or null if no source.
  IrcSource? get parsedSource =>
      source != null ? IrcSource.parse(source!) : null;

  /// Whether the command is a numeric (3-digit number).
  bool get isNumeric => int.tryParse(command) != null;

  /// Returns the numeric value if [isNumeric], otherwise null.
  int? get numericValue => int.tryParse(command);

  /// Serializes the message to raw IRC format with CRLF.
  String toRaw() => IrcParser.serialize(this);

  @override
  List<Object?> get props => [tags, source, command, params];
}
