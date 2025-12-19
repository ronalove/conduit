import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/parser/tag_parser.dart';

void main() {
  group('TagParser', () {
    group('parse', () {
      test('parses single tag without value', () {
        final result = TagParser.parse('draft/reply');
        expect(result, {'draft/reply': null});
      });

      test('parses single tag with value', () {
        final result = TagParser.parse('msgid=abc123');
        expect(result, {'msgid': 'abc123'});
      });

      test('parses multiple tags', () {
        final result = TagParser.parse('msgid=abc;time=2024-01-01T00:00:00Z;+typing');
        expect(result, {
          'msgid': 'abc',
          'time': '2024-01-01T00:00:00Z',
          '+typing': null,
        });
      });

      test('handles empty value', () {
        final result = TagParser.parse('key=');
        expect(result, {'key': ''});
      });

      test('handles tag with vendor prefix', () {
        final result = TagParser.parse('+draft/reply=abc123');
        expect(result, {'+draft/reply': 'abc123'});
      });

      test('duplicate keys keep last value', () {
        final result = TagParser.parse('key=first;key=second');
        expect(result, {'key': 'second'});
      });

      test('returns empty map for empty string', () {
        final result = TagParser.parse('');
        expect(result, isEmpty);
      });

      test('parses complex real-world example', () {
        final result = TagParser.parse(
          'msgid=xyz;time=2024-12-19T10:30:00.000Z;account=testuser;+typing',
        );
        expect(result, {
          'msgid': 'xyz',
          'time': '2024-12-19T10:30:00.000Z',
          'account': 'testuser',
          '+typing': null,
        });
      });
    });

    group('unescapeValue', () {
      test('unescapes semicolon', () {
        final result = TagParser.unescapeValue(r'hello\:world');
        expect(result, 'hello;world');
      });

      test('unescapes space', () {
        final result = TagParser.unescapeValue(r'hello\sworld');
        expect(result, 'hello world');
      });

      test('unescapes backslash', () {
        final result = TagParser.unescapeValue(r'hello\\world');
        expect(result, r'hello\world');
      });

      test('unescapes carriage return', () {
        final result = TagParser.unescapeValue(r'line1\rline2');
        expect(result, 'line1\rline2');
      });

      test('unescapes newline', () {
        final result = TagParser.unescapeValue(r'line1\nline2');
        expect(result, 'line1\nline2');
      });

      test('unescapes CRLF sequence', () {
        final result = TagParser.unescapeValue(r'line1\r\nline2');
        expect(result, 'line1\r\nline2');
      });

      test('invalid escape drops backslash per spec', () {
        final result = TagParser.unescapeValue(r'hello\bworld');
        expect(result, 'hellobworld');
      });

      test('trailing backslash is dropped', () {
        final result = TagParser.unescapeValue(r'hello\');
        expect(result, 'hello');
      });

      test('handles multiple escapes in sequence', () {
        final result = TagParser.unescapeValue(r'a\sb\:c\\d');
        expect(result, r'a b;c\d');
      });

      test('returns original string with no escapes', () {
        final result = TagParser.unescapeValue('hello');
        expect(result, 'hello');
      });
    });

    group('escapeValue', () {
      test('escapes semicolon', () {
        final result = TagParser.escapeValue('hello;world');
        expect(result, r'hello\:world');
      });

      test('escapes space', () {
        final result = TagParser.escapeValue('hello world');
        expect(result, r'hello\sworld');
      });

      test('escapes backslash', () {
        final result = TagParser.escapeValue(r'hello\world');
        expect(result, r'hello\\world');
      });

      test('escapes carriage return', () {
        final result = TagParser.escapeValue('line1\rline2');
        expect(result, r'line1\rline2');
      });

      test('escapes newline', () {
        final result = TagParser.escapeValue('line1\nline2');
        expect(result, r'line1\nline2');
      });

      test('escapes CRLF sequence', () {
        final result = TagParser.escapeValue('line1\r\nline2');
        expect(result, r'line1\r\nline2');
      });

      test('escapes multiple special characters', () {
        final result = TagParser.escapeValue(r'a b;c\d');
        expect(result, r'a\sb\:c\\d');
      });

      test('returns original string with no special chars', () {
        final result = TagParser.escapeValue('hello');
        expect(result, 'hello');
      });
    });

    group('round-trip', () {
      test('escape then unescape returns original', () {
        const original = 'hello; world\\test\r\n';
        final escaped = TagParser.escapeValue(original);
        final unescaped = TagParser.unescapeValue(escaped);
        expect(unescaped, original);
      });

      test('complex string round-trip', () {
        const original = 'user said: "hello world"\nand then left';
        final escaped = TagParser.escapeValue(original);
        final unescaped = TagParser.unescapeValue(escaped);
        expect(unescaped, original);
      });
    });

    group('serialize', () {
      test('serializes single tag without value', () {
        final result = TagParser.serialize({'+typing': null});
        expect(result, '+typing');
      });

      test('serializes single tag with value', () {
        final result = TagParser.serialize({'msgid': 'abc123'});
        expect(result, 'msgid=abc123');
      });

      test('serializes multiple tags', () {
        final result = TagParser.serialize({
          'msgid': 'abc',
          'time': '2024-01-01',
          '+typing': null,
        });
        // Order may vary, check contains
        expect(result, contains('msgid=abc'));
        expect(result, contains('time=2024-01-01'));
        expect(result, contains('+typing'));
        expect(';'.allMatches(result).length, 2);
      });

      test('serializes empty map as empty string', () {
        final result = TagParser.serialize({});
        expect(result, '');
      });

      test('escapes special characters in values', () {
        final result = TagParser.serialize({'msg': 'hello world'});
        expect(result, r'msg=hello\sworld');
      });

      test('handles empty string value', () {
        final result = TagParser.serialize({'key': ''});
        expect(result, 'key=');
      });
    });

    group('parse with escaped values', () {
      test('parses tag with escaped semicolon in value', () {
        final result = TagParser.parse(r'msg=hello\:world');
        expect(result, {'msg': 'hello;world'});
      });

      test('parses tag with escaped space in value', () {
        final result = TagParser.parse(r'msg=hello\sworld');
        expect(result, {'msg': 'hello world'});
      });

      test('parses tag with multiple escaped chars', () {
        final result = TagParser.parse(r'msg=a\sb\:c\\d');
        expect(result, {'msg': r'a b;c\d'});
      });
    });
  });
}
