import 'irc_message.dart';
import 'tag_parser.dart';

/// Parser for IRC messages.
///
/// Format: `[@tags] [:source] <command> [params] [:trailing]`
abstract class IrcParser {
  /// Parses a raw IRC message string into an [IrcMessage].
  ///
  /// The input should NOT include the trailing CRLF.
  static IrcMessage parse(String raw) {
    var remaining = raw;
    Map<String, String?> tags = {};
    String? source;

    // Parse tags (starts with @)
    if (remaining.startsWith('@')) {
      final spaceIndex = remaining.indexOf(' ');
      if (spaceIndex != -1) {
        final tagString = remaining.substring(1, spaceIndex);
        tags = TagParser.parse(tagString);
        remaining = remaining.substring(spaceIndex + 1);
      }
    }

    // Parse source (starts with :)
    if (remaining.startsWith(':')) {
      final spaceIndex = remaining.indexOf(' ');
      if (spaceIndex != -1) {
        source = remaining.substring(1, spaceIndex);
        remaining = remaining.substring(spaceIndex + 1);
      } else {
        // Edge case: source only, no command (invalid but handle gracefully)
        source = remaining.substring(1);
        remaining = '';
      }
    }

    // Parse command and params
    String command;
    List<String> params = [];

    // Find the trailing (starts with :)
    final trailingIndex = remaining.indexOf(' :');
    String beforeTrailing;
    String? trailing;

    if (trailingIndex != -1) {
      beforeTrailing = remaining.substring(0, trailingIndex);
      trailing = remaining.substring(trailingIndex + 2);
    } else {
      beforeTrailing = remaining;
    }

    // Split command and params
    final parts = beforeTrailing.split(' ').where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) {
      command = '';
    } else {
      command = parts[0];
      params = parts.sublist(1);
    }

    // Add trailing as last param
    if (trailing != null) {
      params.add(trailing);
    }

    return IrcMessage(
      tags: tags,
      source: source,
      command: command,
      params: params,
    );
  }

  /// Serializes an [IrcMessage] to raw IRC format.
  ///
  /// Includes the trailing CRLF.
  static String serialize(IrcMessage message) {
    final buffer = StringBuffer();

    // Tags
    if (message.tags.isNotEmpty) {
      buffer.write('@');
      buffer.write(TagParser.serialize(message.tags));
      buffer.write(' ');
    }

    // Source
    if (message.source != null) {
      buffer.write(':');
      buffer.write(message.source);
      buffer.write(' ');
    }

    // Command
    buffer.write(message.command);

    // Params
    if (message.params.isNotEmpty) {
      final lastIndex = message.params.length - 1;

      for (var i = 0; i < message.params.length; i++) {
        buffer.write(' ');
        final param = message.params[i];

        // Use trailing format for last param if:
        // - It contains spaces or is empty
        // - It starts with ':' (would be ambiguous otherwise)
        // - It's the only param (safer for compatibility)
        final needsTrailing = i == lastIndex &&
            (param.contains(' ') ||
                param.isEmpty ||
                param.startsWith(':') ||
                message.params.length == 1);

        if (needsTrailing) {
          buffer.write(':');
        }

        buffer.write(param);
      }
    }

    buffer.write('\r\n');
    return buffer.toString();
  }
}
