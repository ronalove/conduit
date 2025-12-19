import 'package:conduit/core/irc/commands/monitor_commands.dart';
import 'package:test/test.dart';

void main() {
  group('MonitorAddCommand', () {
    test('generates MONITOR + with multiple targets', () {
      const command = MonitorAddCommand(['alice', 'bob', 'charlie']);
      final message = command.toMessage();

      expect(message.command, equals('MONITOR'));
      expect(message.params, equals(['+', 'alice,bob,charlie']));
    });

    test('generates MONITOR + with single target', () {
      const command = MonitorAddCommand(['alice']);
      final message = command.toMessage();

      expect(message.command, equals('MONITOR'));
      expect(message.params, equals(['+', 'alice']));
    });

    test('serializes to IRC format', () {
      const command = MonitorAddCommand(['alice', 'bob']);
      final raw = command.toMessage().toRaw();

      expect(raw, equals('MONITOR + alice,bob\r\n'));
    });
  });

  group('MonitorRemoveCommand', () {
    test('generates MONITOR - with multiple targets', () {
      const command = MonitorRemoveCommand(['alice', 'bob']);
      final message = command.toMessage();

      expect(message.command, equals('MONITOR'));
      expect(message.params, equals(['-', 'alice,bob']));
    });

    test('serializes to IRC format', () {
      const command = MonitorRemoveCommand(['alice']);
      final raw = command.toMessage().toRaw();

      expect(raw, equals('MONITOR - alice\r\n'));
    });
  });

  group('MonitorClearCommand', () {
    test('generates MONITOR C', () {
      const command = MonitorClearCommand();
      final message = command.toMessage();

      expect(message.command, equals('MONITOR'));
      expect(message.params, equals(['C']));
    });

    test('serializes to IRC format', () {
      const command = MonitorClearCommand();
      final raw = command.toMessage().toRaw();

      // Last param gets : prefix in IRC serialization
      expect(raw, equals('MONITOR :C\r\n'));
    });
  });

  group('MonitorListCommand', () {
    test('generates MONITOR L', () {
      const command = MonitorListCommand();
      final message = command.toMessage();

      expect(message.command, equals('MONITOR'));
      expect(message.params, equals(['L']));
    });

    test('serializes to IRC format', () {
      const command = MonitorListCommand();
      final raw = command.toMessage().toRaw();

      // Last param gets : prefix in IRC serialization
      expect(raw, equals('MONITOR :L\r\n'));
    });
  });

  group('MonitorStatusCommand', () {
    test('generates MONITOR S', () {
      const command = MonitorStatusCommand();
      final message = command.toMessage();

      expect(message.command, equals('MONITOR'));
      expect(message.params, equals(['S']));
    });

    test('serializes to IRC format', () {
      const command = MonitorStatusCommand();
      final raw = command.toMessage().toRaw();

      // Last param gets : prefix in IRC serialization
      expect(raw, equals('MONITOR :S\r\n'));
    });
  });
}
