import 'package:conduit/core/irc/commands/list_command.dart';
import 'package:test/test.dart';

void main() {
  group('ListCommand', () {
    group('all', () {
      test('creates LIST command with no params', () {
        final cmd = ListCommand.all();
        final message = cmd.toMessage();

        expect(message.command, equals('LIST'));
        expect(message.params, isEmpty);
      });

      test('toRaw() generates correct format', () {
        final cmd = ListCommand.all();
        expect(cmd.toRaw(), equals('LIST\r\n'));
      });
    });

    group('channels', () {
      test('creates LIST command for single channel', () {
        final cmd = ListCommand.channels(['#test']);
        final message = cmd.toMessage();

        expect(message.command, equals('LIST'));
        expect(message.params, equals(['#test']));
      });

      test('creates LIST command for multiple channels', () {
        final cmd = ListCommand.channels(['#test', '#general', '#help']);
        final message = cmd.toMessage();

        expect(message.command, equals('LIST'));
        expect(message.params, equals(['#test,#general,#help']));
      });

      test('toRaw() includes channel parameter', () {
        final cmd = ListCommand.channels(['#test']);
        expect(cmd.toRaw(), contains('LIST'));
        expect(cmd.toRaw(), contains('#test'));
      });

      test('toRaw() includes multiple channels', () {
        final cmd = ListCommand.channels(['#a', '#b']);
        expect(cmd.toRaw(), contains('LIST'));
        expect(cmd.toRaw(), contains('#a,#b'));
      });
    });

    group('filtered', () {
      test('creates LIST command with >N filter', () {
        final cmd = ListCommand.filtered('>10');
        final message = cmd.toMessage();

        expect(message.command, equals('LIST'));
        expect(message.params, equals(['>10']));
      });

      test('creates LIST command with <N filter', () {
        final cmd = ListCommand.filtered('<100');
        final message = cmd.toMessage();

        expect(message.command, equals('LIST'));
        expect(message.params, equals(['<100']));
      });

      test('toRaw() includes filter', () {
        final cmd = ListCommand.filtered('>50');
        expect(cmd.toRaw(), contains('LIST'));
        expect(cmd.toRaw(), contains('>50'));
      });
    });
  });
}
