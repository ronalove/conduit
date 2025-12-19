import 'package:conduit/core/irc/commands/read_marker_commands.dart';
import 'package:test/test.dart';

void main() {
  group('MarkreadCommand', () {
    group('query', () {
      test('creates query command without timestamp', () {
        final cmd = MarkreadCommand.query('#channel');
        final message = cmd.toMessage();

        expect(message.command, equals('MARKREAD'));
        expect(message.params.length, equals(1));
        expect(message.params[0], equals('#channel'));
      });

      test('toRaw formats correctly', () {
        final cmd = MarkreadCommand.query('#test');
        expect(cmd.toRaw(), equals('MARKREAD :#test\r\n'));
      });
    });

    group('mark', () {
      test('creates mark command with timestamp', () {
        final timestamp = DateTime.utc(2024, 1, 15, 12, 30, 0);
        final cmd = MarkreadCommand.mark('#channel', timestamp);
        final message = cmd.toMessage();

        expect(message.command, equals('MARKREAD'));
        expect(message.params.length, equals(2));
        expect(message.params[0], equals('#channel'));
        expect(message.params[1], contains('timestamp='));
        expect(message.params[1], contains('2024-01-15'));
      });

      test('formats timestamp as UTC ISO 8601', () {
        final timestamp = DateTime(2024, 6, 15, 10, 30, 0); // Local time
        final cmd = MarkreadCommand.mark('#channel', timestamp);
        final message = cmd.toMessage();

        // Should contain UTC format
        expect(message.params[1], contains('Z'));
      });
    });

    group('fromTimestamp', () {
      test('creates command from timestamp string', () {
        final cmd = MarkreadCommand.fromTimestamp(
          '#channel',
          '2024-01-15T12:30:00Z',
        );
        final message = cmd.toMessage();

        expect(message.params[0], equals('#channel'));
        expect(message.params[1], contains('2024-01-15'));
      });

      test('handles invalid timestamp string', () {
        final cmd = MarkreadCommand.fromTimestamp('#channel', 'invalid');
        final message = cmd.toMessage();

        expect(message.params.length, equals(1));
        expect(cmd.timestamp, isNull);
      });
    });

    group('properties', () {
      test('exposes target', () {
        final cmd = MarkreadCommand.query('#test');
        expect(cmd.target, equals('#test'));
      });

      test('exposes timestamp', () {
        final timestamp = DateTime.utc(2024, 1, 1);
        final cmd = MarkreadCommand.mark('#channel', timestamp);
        expect(cmd.timestamp, equals(timestamp));
      });

      test('timestamp is null for query', () {
        final cmd = MarkreadCommand.query('#channel');
        expect(cmd.timestamp, isNull);
      });
    });

    group('toRaw', () {
      test('formats query command', () {
        final cmd = MarkreadCommand.query('nickname');
        expect(cmd.toRaw(), equals('MARKREAD :nickname\r\n'));
      });

      test('formats mark command', () {
        final timestamp = DateTime.utc(2024, 1, 15, 12, 0, 0);
        final cmd = MarkreadCommand.mark('#channel', timestamp);
        final raw = cmd.toRaw();

        expect(raw, startsWith('MARKREAD #channel timestamp='));
        expect(raw, endsWith('\r\n'));
      });
    });
  });
}
