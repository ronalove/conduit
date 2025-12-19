/// IRCv3 message tags parser.
///
/// Parses tags in the format: `tag1=value1;tag2;tag3=value3`
/// Handles escape sequences per IRCv3 spec.
///
/// See: https://ircv3.net/specs/extensions/message-tags
abstract class TagParser {
  /// Escape sequences per IRCv3 spec.
  /// When escaping: char -> escaped
  static const _escapeMap = <String, String>{
    ';': r'\:',
    ' ': r'\s',
    r'\': r'\\',
    '\r': r'\r',
    '\n': r'\n',
  };

  /// Unescape sequences per IRCv3 spec.
  /// When unescaping: char after backslash -> actual char
  static const _unescapeMap = <String, String>{
    ':': ';',
    's': ' ',
    r'\': r'\',
    'r': '\r',
    'n': '\n',
  };

  /// Parses a tag string into a map of tag names to values.
  ///
  /// Tags without values have `null` as their value.
  /// Duplicate keys keep the last value.
  static Map<String, String?> parse(String tagString) {
    if (tagString.isEmpty) {
      return {};
    }

    final result = <String, String?>{};
    final tags = tagString.split(';');

    for (final tag in tags) {
      if (tag.isEmpty) continue;

      final equalsIndex = tag.indexOf('=');
      if (equalsIndex == -1) {
        // Tag without value
        result[tag] = null;
      } else {
        // Tag with value
        final key = tag.substring(0, equalsIndex);
        final rawValue = tag.substring(equalsIndex + 1);
        result[key] = unescapeValue(rawValue);
      }
    }

    return result;
  }

  /// Serializes a map of tags to a tag string.
  ///
  /// Tags with `null` values are serialized without `=`.
  /// Values are escaped according to IRCv3 spec.
  static String serialize(Map<String, String?> tags) {
    if (tags.isEmpty) {
      return '';
    }

    final parts = <String>[];
    for (final entry in tags.entries) {
      if (entry.value == null) {
        parts.add(entry.key);
      } else {
        parts.add('${entry.key}=${escapeValue(entry.value!)}');
      }
    }

    return parts.join(';');
  }

  /// Escapes special characters in a tag value.
  ///
  /// Characters escaped: `;` `\` ` ` `\r` `\n`
  static String escapeValue(String value) {
    final buffer = StringBuffer();

    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      final escaped = _escapeMap[char];
      if (escaped != null) {
        buffer.write(escaped);
      } else {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }

  /// Unescapes special characters in a tag value.
  ///
  /// Handles: `\:` `\s` `\\` `\r` `\n`
  /// Invalid escapes drop the backslash per spec.
  static String unescapeValue(String value) {
    final buffer = StringBuffer();
    var i = 0;

    while (i < value.length) {
      final char = value[i];

      if (char == r'\' && i + 1 < value.length) {
        final nextChar = value[i + 1];
        final unescaped = _unescapeMap[nextChar];
        if (unescaped != null) {
          buffer.write(unescaped);
        } else {
          // Invalid escape: drop backslash, keep char
          buffer.write(nextChar);
        }
        i += 2;
      } else if (char == r'\') {
        // Trailing backslash: drop it
        i++;
      } else {
        buffer.write(char);
        i++;
      }
    }

    return buffer.toString();
  }
}
