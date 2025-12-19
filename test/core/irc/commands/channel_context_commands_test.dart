import 'package:conduit/core/irc/commands/channel_context_commands.dart';
import 'package:conduit/core/irc/parser/message_tags.dart';
import 'package:test/test.dart';

void main() {
  group('ChannelContextPrivmsgCommand', () {
    test('generates PRIVMSG with channel context tag', () {
      const command = ChannelContextPrivmsgCommand(
        target: 'othernick',
        message: 'Hey about that channel',
        channelContext: '#flutter',
      );
      final message = command.toMessage();

      expect(message.command, equals('PRIVMSG'));
      expect(message.params, equals(['othernick', 'Hey about that channel']));
      expect(message.tags[IrcTags.channelContext], equals('#flutter'));
    });

    test('serializes to IRC format correctly', () {
      const command = ChannelContextPrivmsgCommand(
        target: 'bob',
        message: 'Can we discuss the project?',
        channelContext: '#dev',
      );
      final raw = command.toRaw();

      expect(
        raw,
        equals('@+draft/channel-context=#dev PRIVMSG bob :Can we discuss the project?\r\n'),
      );
    });

    test('supports additional tags', () {
      const command = ChannelContextPrivmsgCommand(
        target: 'alice',
        message: 'Question about #help',
        channelContext: '#help',
        additionalTags: {'label': 'abc123'},
      );
      final message = command.toMessage();

      expect(message.tags['label'], equals('abc123'));
      expect(message.tags[IrcTags.channelContext], equals('#help'));
    });

    test('channel context tag overwrites additional tags with same key', () {
      const command = ChannelContextPrivmsgCommand(
        target: 'alice',
        message: 'Message',
        channelContext: '#correct',
        additionalTags: {IrcTags.channelContext: '#wrong'},
      );
      final message = command.toMessage();

      expect(message.tags[IrcTags.channelContext], equals('#correct'));
    });

    test('supports different channel prefixes', () {
      const commands = [
        ChannelContextPrivmsgCommand(
          target: 'nick',
          message: 'msg',
          channelContext: '#channel',
        ),
        ChannelContextPrivmsgCommand(
          target: 'nick',
          message: 'msg',
          channelContext: '&channel',
        ),
        ChannelContextPrivmsgCommand(
          target: 'nick',
          message: 'msg',
          channelContext: '+channel',
        ),
        ChannelContextPrivmsgCommand(
          target: 'nick',
          message: 'msg',
          channelContext: '!channel',
        ),
      ];

      expect(commands[0].toMessage().tags[IrcTags.channelContext], equals('#channel'));
      expect(commands[1].toMessage().tags[IrcTags.channelContext], equals('&channel'));
      expect(commands[2].toMessage().tags[IrcTags.channelContext], equals('+channel'));
      expect(commands[3].toMessage().tags[IrcTags.channelContext], equals('!channel'));
    });
  });

  group('ChannelContextNoticeCommand', () {
    test('generates NOTICE with channel context tag', () {
      const command = ChannelContextNoticeCommand(
        target: 'othernick',
        message: 'FYI about the channel',
        channelContext: '#general',
      );
      final message = command.toMessage();

      expect(message.command, equals('NOTICE'));
      expect(message.params, equals(['othernick', 'FYI about the channel']));
      expect(message.tags[IrcTags.channelContext], equals('#general'));
    });

    test('serializes to IRC format correctly', () {
      const command = ChannelContextNoticeCommand(
        target: 'admin',
        message: 'Issue in channel',
        channelContext: '#support',
      );
      final raw = command.toRaw();

      expect(
        raw,
        equals('@+draft/channel-context=#support NOTICE admin :Issue in channel\r\n'),
      );
    });

    test('supports additional tags', () {
      const command = ChannelContextNoticeCommand(
        target: 'mod',
        message: 'Notice',
        channelContext: '#moderation',
        additionalTags: {'label': 'notice123'},
      );
      final message = command.toMessage();

      expect(message.tags['label'], equals('notice123'));
      expect(message.tags[IrcTags.channelContext], equals('#moderation'));
    });
  });
}
