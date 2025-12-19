import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/parser/message_tags.dart';
import 'package:conduit/core/irc/protocol/channel_context_handler.dart';
import 'package:test/test.dart';

void main() {
  group('ChannelContextHandler', () {
    late ChannelContextHandler handler;

    setUp(() {
      handler = ChannelContextHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('handleMessage', () {
      test('returns null for non-PRIVMSG/NOTICE messages', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'JOIN',
          params: ['#channel'],
          tags: {IrcTags.channelContext: '#other'},
        );

        expect(handler.handleMessage(message), isNull);
      });

      test('returns null for messages without channel context tag', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: ['target', 'Hello'],
        );

        expect(handler.handleMessage(message), isNull);
      });

      test('returns null for messages without params', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: [],
          tags: {IrcTags.channelContext: '#channel'},
        );

        expect(handler.handleMessage(message), isNull);
      });

      test('parses valid PRIVMSG with channel context', () {
        final message = IrcMessage(
          source: 'alice!user@host',
          command: 'PRIVMSG',
          params: ['bob', 'Hey about #flutter'],
          tags: {IrcTags.channelContext: '#flutter'},
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.senderNick, equals('alice'));
        expect(result.senderUser, equals('user'));
        expect(result.senderHost, equals('host'));
        expect(result.target, equals('bob'));
        expect(result.text, equals('Hey about #flutter'));
        expect(result.channelContext, equals('#flutter'));
        expect(result.originalMessage, equals(message));
      });

      test('parses valid NOTICE with channel context', () {
        final message = IrcMessage(
          source: 'alice!user@host',
          command: 'NOTICE',
          params: ['bob', 'FYI about #dev'],
          tags: {IrcTags.channelContext: '#dev'},
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.channelContext, equals('#dev'));
      });

      test('handles message without source', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['target', 'Message'],
          tags: {IrcTags.channelContext: '#channel'},
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.senderNick, isNull);
      });

      test('handles message without text', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: ['target'],
          tags: {IrcTags.channelContext: '#channel'},
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.text, isNull);
      });
    });

    group('messages stream', () {
      test('emits channel context messages', () async {
        final future = handler.messages.first;

        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'PRIVMSG',
          params: ['bob', 'Hey'],
          tags: {IrcTags.channelContext: '#test'},
        ));

        final result = await future;
        expect(result.channelContext, equals('#test'));
      });

      test('emits multiple messages', () async {
        final messages = <ChannelContextMessage>[];
        final subscription = handler.messages.listen(messages.add);

        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'PRIVMSG',
          params: ['bob', 'Msg 1'],
          tags: {IrcTags.channelContext: '#channel1'},
        ));

        handler.handleMessage(IrcMessage(
          source: 'bob!user@host',
          command: 'PRIVMSG',
          params: ['alice', 'Msg 2'],
          tags: {IrcTags.channelContext: '#channel2'},
        ));

        await Future.delayed(Duration.zero);

        expect(messages.length, equals(2));
        expect(messages[0].channelContext, equals('#channel1'));
        expect(messages[1].channelContext, equals('#channel2'));

        await subscription.cancel();
      });
    });

    group('static helpers', () {
      test('hasChannelContext returns true for messages with tag', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['target', 'text'],
          tags: {IrcTags.channelContext: '#channel'},
        );

        expect(ChannelContextHandler.hasChannelContext(message), isTrue);
      });

      test('hasChannelContext returns false for messages without tag', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['target', 'text'],
        );

        expect(ChannelContextHandler.hasChannelContext(message), isFalse);
      });

      test('getChannelContext returns channel for messages with tag', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['target', 'text'],
          tags: {IrcTags.channelContext: '#flutter'},
        );

        expect(ChannelContextHandler.getChannelContext(message), equals('#flutter'));
      });

      test('getChannelContext returns null for messages without tag', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['target', 'text'],
        );

        expect(ChannelContextHandler.getChannelContext(message), isNull);
      });
    });
  });

  group('ChannelContextMessage', () {
    test('isValidChannelContext returns true for # prefix', () {
      final msg = ChannelContextMessage(
        target: 'bob',
        channelContext: '#channel',
        receivedAt: DateTime.now(),
        originalMessage: IrcMessage(command: 'PRIVMSG', params: []),
      );

      expect(msg.isValidChannelContext, isTrue);
    });

    test('isValidChannelContext returns true for & prefix', () {
      final msg = ChannelContextMessage(
        target: 'bob',
        channelContext: '&channel',
        receivedAt: DateTime.now(),
        originalMessage: IrcMessage(command: 'PRIVMSG', params: []),
      );

      expect(msg.isValidChannelContext, isTrue);
    });

    test('isValidChannelContext returns true for + prefix', () {
      final msg = ChannelContextMessage(
        target: 'bob',
        channelContext: '+channel',
        receivedAt: DateTime.now(),
        originalMessage: IrcMessage(command: 'PRIVMSG', params: []),
      );

      expect(msg.isValidChannelContext, isTrue);
    });

    test('isValidChannelContext returns true for ! prefix', () {
      final msg = ChannelContextMessage(
        target: 'bob',
        channelContext: '!channel',
        receivedAt: DateTime.now(),
        originalMessage: IrcMessage(command: 'PRIVMSG', params: []),
      );

      expect(msg.isValidChannelContext, isTrue);
    });

    test('isValidChannelContext returns false for invalid prefix', () {
      final msg = ChannelContextMessage(
        target: 'bob',
        channelContext: 'nochannel',
        receivedAt: DateTime.now(),
        originalMessage: IrcMessage(command: 'PRIVMSG', params: []),
      );

      expect(msg.isValidChannelContext, isFalse);
    });

    test('toString returns readable string', () {
      final msg = ChannelContextMessage(
        senderNick: 'alice',
        target: 'bob',
        channelContext: '#flutter',
        receivedAt: DateTime.now(),
        originalMessage: IrcMessage(command: 'PRIVMSG', params: []),
      );

      final str = msg.toString();
      expect(str, contains('alice'));
      expect(str, contains('bob'));
      expect(str, contains('#flutter'));
    });
  });

  group('IrcMessageChannelContextExtension', () {
    test('channelContext returns value when present', () {
      final message = IrcMessage(
        command: 'PRIVMSG',
        params: ['target', 'text'],
        tags: {IrcTags.channelContext: '#test'},
      );

      expect(message.channelContext, equals('#test'));
    });

    test('channelContext returns null when absent', () {
      final message = IrcMessage(
        command: 'PRIVMSG',
        params: ['target', 'text'],
      );

      expect(message.channelContext, isNull);
    });

    test('hasChannelContext returns correct value', () {
      final withContext = IrcMessage(
        command: 'PRIVMSG',
        params: ['target'],
        tags: {IrcTags.channelContext: '#channel'},
      );

      final withoutContext = IrcMessage(
        command: 'PRIVMSG',
        params: ['target'],
      );

      expect(withContext.hasChannelContext, isTrue);
      expect(withoutContext.hasChannelContext, isFalse);
    });

    test('withChannelContext adds tag to message', () {
      final original = IrcMessage(
        command: 'PRIVMSG',
        params: ['target', 'text'],
        tags: {'existing': 'tag'},
      );

      final updated = original.withChannelContext('#newchannel');

      expect(updated.tags[IrcTags.channelContext], equals('#newchannel'));
      expect(updated.tags['existing'], equals('tag'));
      expect(updated.command, equals('PRIVMSG'));
      expect(updated.params, equals(['target', 'text']));
    });
  });
}
