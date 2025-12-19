import 'package:conduit/core/irc/commands/reply_commands.dart';
import 'package:conduit/core/irc/parser/message_tags.dart';
import 'package:test/test.dart';

void main() {
  group('ReplyCommand', () {
    test('generates PRIVMSG with reply tag', () {
      const command = ReplyCommand(
        target: '#channel',
        message: 'This is my reply',
        replyToMsgId: 'abc123',
      );
      final message = command.toMessage();

      expect(message.command, equals('PRIVMSG'));
      expect(message.params, equals(['#channel', 'This is my reply']));
      expect(message.tags[IrcTags.replyTo], equals('abc123'));
    });

    test('serializes to IRC format correctly', () {
      const command = ReplyCommand(
        target: '#test',
        message: 'Reply text',
        replyToMsgId: 'msgid123',
      );
      final raw = command.toRaw();

      expect(raw, equals('@+draft/reply=msgid123 PRIVMSG #test :Reply text\r\n'));
    });

    test('supports additional tags', () {
      const command = ReplyCommand(
        target: '#channel',
        message: 'Reply',
        replyToMsgId: 'target123',
        additionalTags: {'label': 'label456'},
      );
      final message = command.toMessage();

      expect(message.tags['label'], equals('label456'));
      expect(message.tags[IrcTags.replyTo], equals('target123'));
    });

    test('reply tag overwrites additional tags with same key', () {
      const command = ReplyCommand(
        target: '#channel',
        message: 'Reply',
        replyToMsgId: 'correct',
        additionalTags: {IrcTags.replyTo: 'wrong'},
      );
      final message = command.toMessage();

      expect(message.tags[IrcTags.replyTo], equals('correct'));
    });

    test('works with private message targets', () {
      const command = ReplyCommand(
        target: 'someone',
        message: 'Private reply',
        replyToMsgId: 'pm123',
      );
      final message = command.toMessage();

      expect(message.params[0], equals('someone'));
      expect(message.tags[IrcTags.replyTo], equals('pm123'));
    });

    test('handles complex message IDs', () {
      const command = ReplyCommand(
        target: '#channel',
        message: 'Reply',
        replyToMsgId: 'abcd1234-efgh-5678-ijkl-9012mnop3456',
      );
      final message = command.toMessage();

      expect(message.tags[IrcTags.replyTo], equals('abcd1234-efgh-5678-ijkl-9012mnop3456'));
    });
  });

  group('ReplyNoticeCommand', () {
    test('generates NOTICE with reply tag', () {
      const command = ReplyNoticeCommand(
        target: '#channel',
        message: 'This is a notice reply',
        replyToMsgId: 'notice123',
      );
      final message = command.toMessage();

      expect(message.command, equals('NOTICE'));
      expect(message.params, equals(['#channel', 'This is a notice reply']));
      expect(message.tags[IrcTags.replyTo], equals('notice123'));
    });

    test('serializes to IRC format correctly', () {
      const command = ReplyNoticeCommand(
        target: '#test',
        message: 'Notice reply',
        replyToMsgId: 'msg456',
      );
      final raw = command.toRaw();

      expect(raw, equals('@+draft/reply=msg456 NOTICE #test :Notice reply\r\n'));
    });

    test('supports additional tags', () {
      const command = ReplyNoticeCommand(
        target: '#channel',
        message: 'Notice',
        replyToMsgId: 'target789',
        additionalTags: {'label': 'label111'},
      );
      final message = command.toMessage();

      expect(message.tags['label'], equals('label111'));
      expect(message.tags[IrcTags.replyTo], equals('target789'));
    });
  });
}
