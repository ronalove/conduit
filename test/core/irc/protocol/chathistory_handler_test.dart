import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/protocol/batch_handler.dart';
import 'package:conduit/core/irc/protocol/chathistory_handler.dart';
import 'package:test/test.dart';

void main() {
  group('ChathistoryHandler', () {
    late ChathistoryHandler handler;

    setUp(() {
      handler = ChathistoryHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('processBatch', () {
      test('returns null for non-chathistory batch', () {
        const batch = CompletedBatch(
          reference: 'ref',
          type: 'netjoin',
        );

        final result = handler.processBatch(batch);
        expect(result, isNull);
      });

      test('processes chathistory batch', () async {
        final batch = CompletedBatch(
          reference: 'ref',
          type: 'chathistory',
          params: ['#channel'],
          messages: [
            IrcMessage(
              tags: {'time': '2024-01-01T00:00:00Z', 'msgid': 'msg1'},
              source: 'user1!user@host',
              command: 'PRIVMSG',
              params: ['#channel', 'Hello'],
            ),
            IrcMessage(
              tags: {'time': '2024-01-01T00:01:00Z', 'msgid': 'msg2'},
              source: 'user2!user@host',
              command: 'PRIVMSG',
              params: ['#channel', 'World'],
            ),
          ],
        );

        final result = handler.processBatch(batch);

        expect(result, isNotNull);
        expect(result!.target, equals('#channel'));
        expect(result.messages.length, equals(2));
        expect(result.count, equals(2));
        expect(result.isEmpty, isFalse);
        expect(result.isNotEmpty, isTrue);
      });

      test('sorts messages by server time', () {
        final batch = CompletedBatch(
          reference: 'ref',
          type: 'chathistory',
          params: ['#channel'],
          messages: [
            IrcMessage(
              tags: {'time': '2024-01-01T00:02:00Z'},
              source: 'user!user@host',
              command: 'PRIVMSG',
              params: ['#channel', 'Third'],
            ),
            IrcMessage(
              tags: {'time': '2024-01-01T00:00:00Z'},
              source: 'user!user@host',
              command: 'PRIVMSG',
              params: ['#channel', 'First'],
            ),
            IrcMessage(
              tags: {'time': '2024-01-01T00:01:00Z'},
              source: 'user!user@host',
              command: 'PRIVMSG',
              params: ['#channel', 'Second'],
            ),
          ],
        );

        final result = handler.processBatch(batch);

        expect(result!.messages[0].params.last, equals('First'));
        expect(result.messages[1].params.last, equals('Second'));
        expect(result.messages[2].params.last, equals('Third'));
      });

      test('filters only PRIVMSG and NOTICE', () {
        final batch = CompletedBatch(
          reference: 'ref',
          type: 'chathistory',
          params: ['#channel'],
          messages: [
            IrcMessage(
              source: 'user!user@host',
              command: 'PRIVMSG',
              params: ['#channel', 'Message'],
            ),
            IrcMessage(
              source: 'user!user@host',
              command: 'NOTICE',
              params: ['#channel', 'Notice'],
            ),
            IrcMessage(
              source: 'user!user@host',
              command: 'JOIN',
              params: ['#channel'],
            ),
          ],
        );

        final result = handler.processBatch(batch);
        expect(result!.messages.length, equals(2));
      });

      test('emits to stream', () async {
        final future = handler.onResult.first;

        handler.processBatch(CompletedBatch(
          reference: 'ref',
          type: 'chathistory',
          params: ['#channel'],
          messages: [
            IrcMessage(
              command: 'PRIVMSG',
              params: ['#channel', 'Test'],
            ),
          ],
        ));

        final result = await future;
        expect(result.target, equals('#channel'));
      });

      test('handles empty batch', () {
        final batch = CompletedBatch(
          reference: 'ref',
          type: 'chathistory',
          params: ['#channel'],
          messages: [],
        );

        final result = handler.processBatch(batch);
        expect(result!.isEmpty, isTrue);
        expect(result.oldest, isNull);
        expect(result.newest, isNull);
      });
    });

    group('ChathistoryResult', () {
      test('oldest and newest', () {
        final batch = CompletedBatch(
          reference: 'ref',
          type: 'chathistory',
          params: ['#ch'],
          messages: [
            IrcMessage(
              tags: {'time': '2024-01-01T00:00:00Z', 'msgid': 'first'},
              command: 'PRIVMSG',
              params: ['#ch', 'First'],
            ),
            IrcMessage(
              tags: {'time': '2024-01-01T00:01:00Z', 'msgid': 'last'},
              command: 'PRIVMSG',
              params: ['#ch', 'Last'],
            ),
          ],
        );

        final result = handler.processBatch(batch);
        expect(result!.oldest!.params.last, equals('First'));
        expect(result.newest!.params.last, equals('Last'));
        expect(result.oldestMsgId, equals('first'));
        expect(result.newestMsgId, equals('last'));
      });
    });

    group('parseError', () {
      test('parses FAIL CHATHISTORY message', () {
        final message = IrcMessage(
          source: 'server',
          command: 'FAIL',
          params: [
            'CHATHISTORY',
            'INVALID_TARGET',
            '#channel',
            'No such channel',
          ],
        );

        final error = ChathistoryHandler.parseError(message);

        expect(error, isNotNull);
        expect(error!.code, equals('INVALID_TARGET'));
        expect(error.context, equals('#channel'));
        expect(error.description, equals('No such channel'));
      });

      test('returns null for non-FAIL message', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        expect(ChathistoryHandler.parseError(message), isNull);
      });

      test('returns null for non-CHATHISTORY FAIL', () {
        final message = IrcMessage(
          command: 'FAIL',
          params: ['SOMETHING', 'ERROR', 'description'],
        );

        expect(ChathistoryHandler.parseError(message), isNull);
      });

      test('handles minimal FAIL message', () {
        final message = IrcMessage(
          command: 'FAIL',
          params: ['CHATHISTORY', 'ERROR'],
        );

        final error = ChathistoryHandler.parseError(message);
        expect(error, isNotNull);
        expect(error!.code, equals('ERROR'));
        expect(error.context, isNull);
        expect(error.description, isNull);
      });

      test('toString includes description', () {
        const error = ChathistoryError(
          code: 'INVALID_PARAMS',
          context: '#channel',
          description: 'Missing required parameter',
        );

        expect(error.toString(), contains('INVALID_PARAMS'));
        expect(error.toString(), contains('Missing required parameter'));
      });

      test('toString without description', () {
        const error = ChathistoryError(code: 'ERROR');
        expect(error.toString(), equals('ChathistoryError: ERROR'));
      });
    });
  });

  group('ChathistoryTarget', () {
    test('creates with name only', () {
      const target = ChathistoryTarget(name: '#channel');
      expect(target.name, equals('#channel'));
      expect(target.timestamp, isNull);
    });

    test('creates with timestamp', () {
      final time = DateTime.utc(2024, 1, 1);
      final target = ChathistoryTarget(name: 'nick', timestamp: time);
      expect(target.name, equals('nick'));
      expect(target.timestamp, equals(time));
    });
  });
}
