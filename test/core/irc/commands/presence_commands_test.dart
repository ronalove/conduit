import 'package:conduit/core/irc/commands/presence_commands.dart';
import 'package:test/test.dart';

void main() {
  group('SetnameCommand', () {
    test('generates SETNAME with realname', () {
      const command = SetnameCommand('New Real Name');
      final message = command.toMessage();

      expect(message.command, equals('SETNAME'));
      expect(message.params, equals(['New Real Name']));
    });

    test('serializes to IRC format correctly', () {
      const command = SetnameCommand('My Real Name');
      final message = command.toMessage();
      final raw = message.toRaw();

      expect(raw, equals('SETNAME :My Real Name\r\n'));
    });

    test('handles empty realname', () {
      const command = SetnameCommand('');
      final message = command.toMessage();

      expect(message.command, equals('SETNAME'));
      expect(message.params, equals(['']));
    });
  });

  group('AwayCommand', () {
    test('generates AWAY with message', () {
      const command = AwayCommand(message: 'Gone for lunch');
      final message = command.toMessage();

      expect(message.command, equals('AWAY'));
      expect(message.params, equals(['Gone for lunch']));
    });

    test('generates AWAY without message (back)', () {
      const command = AwayCommand();
      final message = command.toMessage();

      expect(message.command, equals('AWAY'));
      expect(message.params, isEmpty);
    });

    test('AwayCommand.back() generates AWAY without message', () {
      const command = AwayCommand.back();
      final message = command.toMessage();

      expect(message.command, equals('AWAY'));
      expect(message.params, isEmpty);
    });

    test('AwayCommand.away() generates AWAY with message', () {
      const command = AwayCommand.away('BRB');
      final message = command.toMessage();

      expect(message.command, equals('AWAY'));
      expect(message.params, equals(['BRB']));
    });

    test('serializes to IRC format correctly', () {
      const command = AwayCommand(message: 'Be right back');
      final message = command.toMessage();
      final raw = message.toRaw();

      expect(raw, equals('AWAY :Be right back\r\n'));
    });

    test('serializes without message to IRC format', () {
      const command = AwayCommand.back();
      final message = command.toMessage();
      final raw = message.toRaw();

      expect(raw, equals('AWAY\r\n'));
    });
  });
}
