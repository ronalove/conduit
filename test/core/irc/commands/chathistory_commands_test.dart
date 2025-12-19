import 'package:conduit/core/irc/commands/chathistory_commands.dart';
import 'package:test/test.dart';

void main() {
  group('ChathistoryCommand', () {
    group('latest', () {
      test('creates LATEST command', () {
        final cmd = ChathistoryCommand.latest('#channel', 50);
        final message = cmd.toMessage();

        expect(message.command, equals('CHATHISTORY'));
        expect(message.params[0], equals('LATEST'));
        expect(message.params[1], equals('#channel'));
        expect(message.params[2], equals('*'));
        expect(message.params[3], equals('50'));
      });

      test('toRaw formats correctly', () {
        final cmd = ChathistoryCommand.latest('#test', 100);
        expect(
          cmd.toRaw(),
          equals('CHATHISTORY LATEST #test * 100\r\n'),
        );
      });
    });

    group('before', () {
      test('creates BEFORE command with msgid', () {
        final cmd = ChathistoryCommand.before('#channel', 'msgid=abc123', 25);
        final message = cmd.toMessage();

        expect(message.command, equals('CHATHISTORY'));
        expect(message.params[0], equals('BEFORE'));
        expect(message.params[1], equals('#channel'));
        expect(message.params[2], equals('msgid=abc123'));
        expect(message.params[3], equals('25'));
      });

      test('creates BEFORE command with timestamp', () {
        final cmd = ChathistoryCommand.before(
          '#channel',
          'timestamp=2024-01-01T00:00:00Z',
          50,
        );
        final message = cmd.toMessage();

        expect(message.params[2], equals('timestamp=2024-01-01T00:00:00Z'));
      });
    });

    group('after', () {
      test('creates AFTER command', () {
        final cmd = ChathistoryCommand.after('#channel', 'msgid=xyz789', 30);
        final message = cmd.toMessage();

        expect(message.params[0], equals('AFTER'));
        expect(message.params[1], equals('#channel'));
        expect(message.params[2], equals('msgid=xyz789'));
        expect(message.params[3], equals('30'));
      });
    });

    group('around', () {
      test('creates AROUND command', () {
        final cmd = ChathistoryCommand.around('#channel', 'msgid=middle', 20);
        final message = cmd.toMessage();

        expect(message.params[0], equals('AROUND'));
        expect(message.params[1], equals('#channel'));
        expect(message.params[2], equals('msgid=middle'));
        expect(message.params[3], equals('20'));
      });
    });

    group('between', () {
      test('creates BETWEEN command', () {
        final cmd = ChathistoryCommand.between(
          '#channel',
          'msgid=start',
          'msgid=end',
          100,
        );
        final message = cmd.toMessage();

        expect(message.params[0], equals('BETWEEN'));
        expect(message.params[1], equals('#channel'));
        expect(message.params[2], equals('msgid=start'));
        expect(message.params[3], equals('msgid=end'));
        expect(message.params[4], equals('100'));
      });

      test('creates BETWEEN command with timestamps', () {
        final cmd = ChathistoryCommand.between(
          '#channel',
          'timestamp=2024-01-01T00:00:00Z',
          'timestamp=2024-01-02T00:00:00Z',
          50,
        );
        final message = cmd.toMessage();

        expect(message.params.length, equals(5));
      });
    });

    group('targets', () {
      test('creates TARGETS command', () {
        final cmd = ChathistoryCommand.targets(
          'timestamp=2024-01-01T00:00:00Z',
          'timestamp=2024-01-02T00:00:00Z',
          10,
        );
        final message = cmd.toMessage();

        expect(message.params[0], equals('TARGETS'));
        expect(message.params[1], equals('timestamp=2024-01-01T00:00:00Z'));
        expect(message.params[2], equals('timestamp=2024-01-02T00:00:00Z'));
        expect(message.params[3], equals('10'));
      });
    });

    group('properties', () {
      test('exposes subcommand', () {
        expect(
          ChathistoryCommand.latest('#ch', 10).subcommand,
          equals(ChathistorySubcommand.latest),
        );
        expect(
          ChathistoryCommand.before('#ch', '*', 10).subcommand,
          equals(ChathistorySubcommand.before),
        );
        expect(
          ChathistoryCommand.after('#ch', '*', 10).subcommand,
          equals(ChathistorySubcommand.after),
        );
        expect(
          ChathistoryCommand.around('#ch', '*', 10).subcommand,
          equals(ChathistorySubcommand.around),
        );
        expect(
          ChathistoryCommand.between('#ch', '*', '*', 10).subcommand,
          equals(ChathistorySubcommand.between),
        );
        expect(
          ChathistoryCommand.targets('*', '*', 10).subcommand,
          equals(ChathistorySubcommand.targets),
        );
      });

      test('exposes target and limit', () {
        final cmd = ChathistoryCommand.latest('#channel', 50);
        expect(cmd.target, equals('#channel'));
        expect(cmd.limit, equals(50));
      });
    });
  });

  group('ChathistoryCriteria', () {
    group('msgid', () {
      test('creates msgid criteria', () {
        expect(
          ChathistoryCriteria.msgid('abc123'),
          equals('msgid=abc123'),
        );
      });
    });

    group('timestamp', () {
      test('creates timestamp from DateTime', () {
        final time = DateTime.utc(2024, 1, 15, 12, 30, 0);
        final criteria = ChathistoryCriteria.timestamp(time);
        expect(criteria, startsWith('timestamp='));
        expect(criteria, contains('2024-01-15'));
      });

      test('creates timestamp from string', () {
        expect(
          ChathistoryCriteria.timestampString('2024-01-01T00:00:00Z'),
          equals('timestamp=2024-01-01T00:00:00Z'),
        );
      });
    });

    group('parse', () {
      test('parses msgid criteria', () {
        final result = ChathistoryCriteria.parse('msgid=abc123');
        expect(result, isNotNull);
        expect(result!.type, equals('msgid'));
        expect(result.value, equals('abc123'));
      });

      test('parses timestamp criteria', () {
        final result = ChathistoryCriteria.parse('timestamp=2024-01-01T00:00:00Z');
        expect(result, isNotNull);
        expect(result!.type, equals('timestamp'));
        expect(result.value, equals('2024-01-01T00:00:00Z'));
      });

      test('returns null for wildcard', () {
        expect(ChathistoryCriteria.parse('*'), isNull);
      });

      test('returns null for invalid format', () {
        expect(ChathistoryCriteria.parse('invalid'), isNull);
      });
    });

    group('type checks', () {
      test('isMsgid', () {
        expect(ChathistoryCriteria.isMsgid('msgid=abc'), isTrue);
        expect(ChathistoryCriteria.isMsgid('timestamp=abc'), isFalse);
      });

      test('isTimestamp', () {
        expect(ChathistoryCriteria.isTimestamp('timestamp=abc'), isTrue);
        expect(ChathistoryCriteria.isTimestamp('msgid=abc'), isFalse);
      });
    });
  });

  group('ChathistorySubcommand', () {
    test('has all required values', () {
      expect(ChathistorySubcommand.values, containsAll([
        ChathistorySubcommand.latest,
        ChathistorySubcommand.before,
        ChathistorySubcommand.after,
        ChathistorySubcommand.around,
        ChathistorySubcommand.between,
        ChathistorySubcommand.targets,
      ]));
    });
  });
}
