import 'package:conduit/core/irc/commands/whox_command.dart';
import 'package:test/test.dart';

void main() {
  group('WhoxCommand', () {
    test('generates WHO with default fields', () {
      const command = WhoxCommand('#channel');
      final message = command.toMessage();

      expect(message.command, equals('WHO'));
      expect(message.params[0], equals('#channel'));
      expect(message.params[1], equals('%tcuhnfar'));
    });

    test('generates WHO with custom fields', () {
      const command = WhoxCommand('#channel', fields: 'naf');
      final message = command.toMessage();

      expect(message.command, equals('WHO'));
      expect(message.params[1], equals('%naf'));
    });

    test('generates WHO with query type', () {
      const command = WhoxCommand('#channel', queryType: '123');
      final message = command.toMessage();

      expect(message.command, equals('WHO'));
      expect(message.params[1], equals('%tcuhnfar,123'));
    });

    test('generates WHO with custom fields and query type', () {
      const command = WhoxCommand(
        '#channel',
        fields: 'nua',
        queryType: 'abc',
      );
      final message = command.toMessage();

      expect(message.params[1], equals('%nua,abc'));
    });

    group('named constructors', () {
      test('WhoxCommand.channel', () {
        const command = WhoxCommand.channel('#test', queryType: '42');
        final message = command.toMessage();

        expect(message.params[0], equals('#test'));
        expect(message.params[1], contains('42'));
      });

      test('WhoxCommand.user', () {
        const command = WhoxCommand.user('nick', fields: 'na');
        final message = command.toMessage();

        expect(message.params[0], equals('nick'));
        expect(message.params[1], equals('%na'));
      });
    });

    test('serializes to IRC format', () {
      const command = WhoxCommand('#channel');
      final message = command.toMessage();

      // Verify the command structure
      expect(message.command, equals('WHO'));
      expect(message.params.length, equals(2));
      expect(message.params[0], equals('#channel'));
      expect(message.params[1], equals('%tcuhnfar'));
    });
  });

  group('WhoxFields', () {
    test('defines field constants', () {
      expect(WhoxFields.queryType, equals('t'));
      expect(WhoxFields.channel, equals('c'));
      expect(WhoxFields.username, equals('u'));
      expect(WhoxFields.ip, equals('i'));
      expect(WhoxFields.hostname, equals('h'));
      expect(WhoxFields.server, equals('s'));
      expect(WhoxFields.nickname, equals('n'));
      expect(WhoxFields.flags, equals('f'));
      expect(WhoxFields.hopCount, equals('d'));
      expect(WhoxFields.idle, equals('l'));
      expect(WhoxFields.account, equals('a'));
      expect(WhoxFields.opLevel, equals('o'));
      expect(WhoxFields.realname, equals('r'));
    });

    test('defines standard fields', () {
      expect(WhoxFields.standard, equals('tcuhnfar'));
    });

    test('defines all fields', () {
      expect(WhoxFields.all, equals('tcuihsnfdlaor'));
    });
  });
}
