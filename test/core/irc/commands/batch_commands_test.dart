import 'package:conduit/core/irc/commands/batch_commands.dart';
import 'package:test/test.dart';

void main() {
  group('BatchCommand', () {
    group('start', () {
      test('creates start command with type', () {
        final cmd = BatchCommand.start('abc123', 'chathistory');
        final message = cmd.toMessage();

        expect(message.command, equals('BATCH'));
        expect(message.params.length, equals(2));
        expect(message.params[0], equals('+abc123'));
        expect(message.params[1], equals('chathistory'));
      });

      test('creates start command with type and params', () {
        final cmd = BatchCommand.start('ref1', 'netjoin', ['server.example.com']);
        final message = cmd.toMessage();

        expect(message.command, equals('BATCH'));
        expect(message.params.length, equals(3));
        expect(message.params[0], equals('+ref1'));
        expect(message.params[1], equals('netjoin'));
        expect(message.params[2], equals('server.example.com'));
      });

      test('creates start command with multiple params', () {
        final cmd = BatchCommand.start('ref2', 'draft/multiline', ['#channel']);
        final message = cmd.toMessage();

        expect(message.params.length, equals(3));
        expect(message.params[0], equals('+ref2'));
        expect(message.params[1], equals('draft/multiline'));
        expect(message.params[2], equals('#channel'));
      });
    });

    group('end', () {
      test('creates end command', () {
        final cmd = BatchCommand.end('abc123');
        final message = cmd.toMessage();

        expect(message.command, equals('BATCH'));
        expect(message.params.length, equals(1));
        expect(message.params[0], equals('-abc123'));
      });
    });

    group('toRaw', () {
      test('formats start command correctly', () {
        final cmd = BatchCommand.start('ref', 'chathistory');
        expect(cmd.toRaw(), equals('BATCH +ref chathistory\r\n'));
      });

      test('formats end command correctly', () {
        final cmd = BatchCommand.end('ref');
        // Single param uses trailing format for compatibility
        expect(cmd.toRaw(), equals('BATCH :-ref\r\n'));
      });

      test('formats start command with params', () {
        final cmd = BatchCommand.start('ref', 'netjoin', ['server.irc.com']);
        expect(cmd.toRaw(), equals('BATCH +ref netjoin server.irc.com\r\n'));
      });
    });

    group('action', () {
      test('start has start action', () {
        final cmd = BatchCommand.start('ref', 'type');
        expect(cmd.action, equals(BatchAction.start));
      });

      test('end has end action', () {
        final cmd = BatchCommand.end('ref');
        expect(cmd.action, equals(BatchAction.end));
      });
    });

    group('properties', () {
      test('start command has reference and type', () {
        final cmd = BatchCommand.start('myref', 'chathistory', ['param1']);

        expect(cmd.reference, equals('myref'));
        expect(cmd.type, equals('chathistory'));
        expect(cmd.params, equals(['param1']));
      });

      test('end command has reference only', () {
        final cmd = BatchCommand.end('myref');

        expect(cmd.reference, equals('myref'));
        expect(cmd.type, isNull);
        expect(cmd.params, isEmpty);
      });
    });
  });

  group('BatchTypes', () {
    test('defines standard batch types', () {
      expect(BatchTypes.netjoin, equals('netjoin'));
      expect(BatchTypes.netsplit, equals('netsplit'));
      expect(BatchTypes.chathistory, equals('chathistory'));
      expect(BatchTypes.labeledResponse, equals('labeled-response'));
      expect(BatchTypes.multiline, equals('draft/multiline'));
    });
  });
}
