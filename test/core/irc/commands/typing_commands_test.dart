import 'package:conduit/core/irc/commands/typing_commands.dart';
import 'package:conduit/core/irc/parser/message_tags.dart';
import 'package:test/test.dart';

void main() {
  group('TypingState', () {
    test('toIrcValue converts to correct strings', () {
      expect(TypingState.active.toIrcValue(), equals('active'));
      expect(TypingState.paused.toIrcValue(), equals('paused'));
      expect(TypingState.done.toIrcValue(), equals('done'));
    });

    test('fromIrcValue parses valid states', () {
      expect(TypingStateExtension.fromIrcValue('active'), equals(TypingState.active));
      expect(TypingStateExtension.fromIrcValue('paused'), equals(TypingState.paused));
      expect(TypingStateExtension.fromIrcValue('done'), equals(TypingState.done));
    });

    test('fromIrcValue returns null for invalid states', () {
      expect(TypingStateExtension.fromIrcValue('invalid'), isNull);
      expect(TypingStateExtension.fromIrcValue(''), isNull);
      expect(TypingStateExtension.fromIrcValue(null), isNull);
    });
  });

  group('TagmsgCommand', () {
    test('generates TAGMSG with target', () {
      final command = TagmsgCommand(
        target: '#channel',
        tags: {'+typing': 'active'},
      );
      final message = command.toMessage();

      expect(message.command, equals('TAGMSG'));
      expect(message.params, equals(['#channel']));
      expect(message.tags, equals({'+typing': 'active'}));
    });

    test('serializes to IRC format correctly', () {
      final command = TagmsgCommand(
        target: '#test',
        tags: {'+typing': 'active'},
      );
      final raw = command.toRaw();

      // TAGMSG with single param gets : prefix for trailing
      expect(raw, equals('@+typing=active TAGMSG :#test\r\n'));
    });

    test('supports multiple tags', () {
      final command = TagmsgCommand(
        target: 'nick',
        tags: {
          '+typing': 'active',
          '+draft/custom': 'value',
        },
      );
      final message = command.toMessage();

      expect(message.tags.length, equals(2));
      expect(message.tags['+typing'], equals('active'));
      expect(message.tags['+draft/custom'], equals('value'));
    });
  });

  group('TypingCommand', () {
    test('generates TAGMSG with +typing tag for active state', () {
      final command = TypingCommand(
        target: '#channel',
        state: TypingState.active,
      );
      final message = command.toMessage();

      expect(message.command, equals('TAGMSG'));
      expect(message.params, equals(['#channel']));
      expect(message.tags[IrcTags.typing], equals('active'));
    });

    test('generates TAGMSG with +typing tag for paused state', () {
      final command = TypingCommand(
        target: '#channel',
        state: TypingState.paused,
      );
      final message = command.toMessage();

      expect(message.tags[IrcTags.typing], equals('paused'));
    });

    test('generates TAGMSG with +typing tag for done state', () {
      final command = TypingCommand(
        target: '#channel',
        state: TypingState.done,
      );
      final message = command.toMessage();

      expect(message.tags[IrcTags.typing], equals('done'));
    });

    test('TypingCommand.active factory creates active state', () {
      final command = TypingCommand.active('#test');
      final message = command.toMessage();

      expect(message.params, equals(['#test']));
      expect(message.tags[IrcTags.typing], equals('active'));
    });

    test('TypingCommand.paused factory creates paused state', () {
      final command = TypingCommand.paused('#test');
      final message = command.toMessage();

      expect(message.tags[IrcTags.typing], equals('paused'));
    });

    test('TypingCommand.done factory creates done state', () {
      final command = TypingCommand.done('#test');
      final message = command.toMessage();

      expect(message.tags[IrcTags.typing], equals('done'));
    });

    test('serializes to IRC format correctly', () {
      final command = TypingCommand.active('#flutter');
      final raw = command.toRaw();

      // TAGMSG with single param gets : prefix for trailing
      expect(raw, equals('@+typing=active TAGMSG :#flutter\r\n'));
    });

    test('supports additional tags', () {
      final command = TypingCommand(
        target: '#channel',
        state: TypingState.active,
        additionalTags: {'label': 'abc123'},
      );
      final message = command.toMessage();

      expect(message.tags['label'], equals('abc123'));
      expect(message.tags[IrcTags.typing], equals('active'));
    });

    test('typing tag overwrites additional tags with same key', () {
      final command = TypingCommand(
        target: '#channel',
        state: TypingState.active,
        additionalTags: {IrcTags.typing: 'paused'},
      );
      final message = command.toMessage();

      // The typing state should override the additional tag
      expect(message.tags[IrcTags.typing], equals('active'));
    });

    test('works with private message targets', () {
      final command = TypingCommand.active('someone');
      final message = command.toMessage();

      expect(message.params, equals(['someone']));
    });
  });
}
