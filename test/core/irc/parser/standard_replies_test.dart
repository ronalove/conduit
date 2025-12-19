import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/parser/standard_replies.dart';
import 'package:test/test.dart';

void main() {
  group('StandardReplyParser', () {
    group('parse', () {
      test('parses FAIL message', () {
        final message = IrcMessage(
          command: 'FAIL',
          params: ['CHATHISTORY', 'INVALID_TARGET', '#channel', 'Cannot fetch history'],
        );

        final reply = StandardReplyParser.parse(message);

        expect(reply, isNotNull);
        expect(reply!.type, equals(StandardReplyType.fail));
        expect(reply.command, equals('CHATHISTORY'));
        expect(reply.code, equals('INVALID_TARGET'));
        expect(reply.context, equals(['#channel']));
        expect(reply.description, equals('Cannot fetch history'));
      });

      test('parses WARN message', () {
        final message = IrcMessage(
          command: 'WARN',
          params: ['*', 'ACCOUNT_REQUIRED', 'You need to authenticate'],
        );

        final reply = StandardReplyParser.parse(message);

        expect(reply, isNotNull);
        expect(reply!.type, equals(StandardReplyType.warn));
        expect(reply.command, equals('*'));
        expect(reply.code, equals('ACCOUNT_REQUIRED'));
        expect(reply.context, isEmpty);
        expect(reply.description, equals('You need to authenticate'));
      });

      test('parses NOTE message', () {
        final message = IrcMessage(
          command: 'NOTE',
          params: ['JOIN', 'CHANNEL_RENAMED', '#old', '#new', 'Channel was renamed'],
        );

        final reply = StandardReplyParser.parse(message);

        expect(reply, isNotNull);
        expect(reply!.type, equals(StandardReplyType.note));
        expect(reply.command, equals('JOIN'));
        expect(reply.code, equals('CHANNEL_RENAMED'));
        expect(reply.context, equals(['#old', '#new']));
        expect(reply.description, equals('Channel was renamed'));
      });

      test('handles lowercase command', () {
        final message = IrcMessage(
          command: 'fail',
          params: ['TEST', 'ERROR', 'Something failed'],
        );

        final reply = StandardReplyParser.parse(message);

        expect(reply, isNotNull);
        expect(reply!.type, equals(StandardReplyType.fail));
      });

      test('returns null for non-standard commands', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        expect(StandardReplyParser.parse(message), isNull);
      });

      test('returns null for insufficient params', () {
        final message = IrcMessage(
          command: 'FAIL',
          params: ['COMMAND', 'CODE'],
        );

        expect(StandardReplyParser.parse(message), isNull);
      });

      test('handles message without context', () {
        final message = IrcMessage(
          command: 'FAIL',
          params: ['COMMAND', 'CODE', 'Description only'],
        );

        final reply = StandardReplyParser.parse(message);

        expect(reply, isNotNull);
        expect(reply!.context, isEmpty);
        expect(reply.description, equals('Description only'));
      });

      test('handles multiple context params', () {
        final message = IrcMessage(
          command: 'FAIL',
          params: ['CMD', 'CODE', 'ctx1', 'ctx2', 'ctx3', 'Description'],
        );

        final reply = StandardReplyParser.parse(message);

        expect(reply, isNotNull);
        expect(reply!.context, equals(['ctx1', 'ctx2', 'ctx3']));
      });
    });

    group('isStandardReply', () {
      test('returns true for FAIL/WARN/NOTE', () {
        expect(
          StandardReplyParser.isStandardReply(IrcMessage(command: 'FAIL', params: ['a', 'b', 'c'])),
          isTrue,
        );
        expect(
          StandardReplyParser.isStandardReply(IrcMessage(command: 'WARN', params: ['a', 'b', 'c'])),
          isTrue,
        );
        expect(
          StandardReplyParser.isStandardReply(IrcMessage(command: 'NOTE', params: ['a', 'b', 'c'])),
          isTrue,
        );
      });

      test('returns false for other commands', () {
        expect(
          StandardReplyParser.isStandardReply(IrcMessage(command: 'PRIVMSG')),
          isFalse,
        );
        expect(
          StandardReplyParser.isStandardReply(IrcMessage(command: 'ERROR')),
          isFalse,
        );
      });
    });

    group('isStandardReplyCommand', () {
      test('identifies standard reply commands', () {
        expect(StandardReplyParser.isStandardReplyCommand('FAIL'), isTrue);
        expect(StandardReplyParser.isStandardReplyCommand('WARN'), isTrue);
        expect(StandardReplyParser.isStandardReplyCommand('NOTE'), isTrue);
        expect(StandardReplyParser.isStandardReplyCommand('fail'), isTrue);
        expect(StandardReplyParser.isStandardReplyCommand('PRIVMSG'), isFalse);
      });
    });
  });

  group('StandardReply', () {
    test('isFail returns correct value', () {
      final fail = StandardReply(
        type: StandardReplyType.fail,
        command: 'CMD',
        code: 'CODE',
        description: 'desc',
      );
      final warn = StandardReply(
        type: StandardReplyType.warn,
        command: 'CMD',
        code: 'CODE',
        description: 'desc',
      );

      expect(fail.isFail, isTrue);
      expect(fail.isWarn, isFalse);
      expect(warn.isFail, isFalse);
      expect(warn.isWarn, isTrue);
    });

    test('isServerWide returns correct value', () {
      final serverWide = StandardReply(
        type: StandardReplyType.warn,
        command: '*',
        code: 'CODE',
        description: 'desc',
      );
      final specific = StandardReply(
        type: StandardReplyType.warn,
        command: 'PRIVMSG',
        code: 'CODE',
        description: 'desc',
      );

      expect(serverWide.isServerWide, isTrue);
      expect(specific.isServerWide, isFalse);
    });

    test('fullCode formats correctly', () {
      final reply = StandardReply(
        type: StandardReplyType.fail,
        command: 'CHATHISTORY',
        code: 'INVALID_TARGET',
        description: 'desc',
      );
      final serverWide = StandardReply(
        type: StandardReplyType.warn,
        command: '*',
        code: 'ACCOUNT_REQUIRED',
        description: 'desc',
      );

      expect(reply.fullCode, equals('CHATHISTORY_INVALID_TARGET'));
      expect(serverWide.fullCode, equals('ACCOUNT_REQUIRED'));
    });

    test('toString formats correctly', () {
      final reply = StandardReply(
        type: StandardReplyType.fail,
        command: 'CMD',
        code: 'CODE',
        context: ['ctx1', 'ctx2'],
        description: 'Description',
      );

      expect(reply.toString(), equals('StandardReply(FAIL CMD CODE ctx1 ctx2: Description)'));
    });

    test('equality works correctly', () {
      final reply1 = StandardReply(
        type: StandardReplyType.fail,
        command: 'CMD',
        code: 'CODE',
        context: ['ctx'],
        description: 'desc',
      );
      final reply2 = StandardReply(
        type: StandardReplyType.fail,
        command: 'CMD',
        code: 'CODE',
        context: ['ctx'],
        description: 'desc',
      );
      final reply3 = StandardReply(
        type: StandardReplyType.warn,
        command: 'CMD',
        code: 'CODE',
        context: ['ctx'],
        description: 'desc',
      );

      expect(reply1, equals(reply2));
      expect(reply1, isNot(equals(reply3)));
    });
  });

  group('StandardReplyExtension', () {
    test('isStandardReply works on IrcMessage', () {
      final fail = IrcMessage(command: 'FAIL', params: ['a', 'b', 'c']);
      final privmsg = IrcMessage(command: 'PRIVMSG', params: ['#channel', 'Hello']);

      expect(fail.isStandardReply, isTrue);
      expect(privmsg.isStandardReply, isFalse);
    });

    test('asStandardReply parses correctly', () {
      final message = IrcMessage(
        command: 'FAIL',
        params: ['CMD', 'CODE', 'Description'],
      );

      final reply = message.asStandardReply;

      expect(reply, isNotNull);
      expect(reply!.command, equals('CMD'));
      expect(reply.code, equals('CODE'));
    });

    test('asStandardReply returns null for non-standard', () {
      final message = IrcMessage(command: 'PRIVMSG', params: ['#channel', 'Hello']);

      expect(message.asStandardReply, isNull);
    });
  });

  group('StandardReplyCodes', () {
    test('contains expected codes', () {
      expect(StandardReplyCodes.accountRequired, equals('ACCOUNT_REQUIRED'));
      expect(StandardReplyCodes.invalidTarget, equals('INVALID_TARGET'));
      expect(StandardReplyCodes.rateLimit, equals('RATE_LIMIT'));
    });
  });
}
