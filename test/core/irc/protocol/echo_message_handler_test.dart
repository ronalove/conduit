import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/protocol/echo_message_handler.dart';
import 'package:test/test.dart';

void main() {
  group('EchoMessageHandler', () {
    late EchoMessageHandler handler;

    setUp(() {
      handler = EchoMessageHandler(currentNick: 'testuser');
    });

    tearDown(() {
      handler.dispose();
    });

    group('trackOutgoing', () {
      test('adds message to pending', () {
        expect(handler.pendingCount, equals(0));

        handler.trackOutgoing(target: '#channel', text: 'Hello');

        expect(handler.pendingCount, equals(1));
      });

      test('tracks multiple pending messages', () {
        handler.trackOutgoing(target: '#channel', text: 'Message 1');
        handler.trackOutgoing(target: '#channel', text: 'Message 2');
        handler.trackOutgoing(target: 'user', text: 'Private message');

        expect(handler.pendingCount, equals(3));
      });
    });

    group('checkMessage', () {
      test('returns IsEcho for matching pending message', () {
        handler.trackOutgoing(target: '#channel', text: 'Hello world');

        final message = IrcMessage(
          tags: {
            'msgid': 'server123',
            'time': '2024-01-15T10:30:00.000Z',
          },
          source: 'testuser!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello world'],
        );

        final result = handler.checkMessage(message);

        expect(result, isA<IsEcho>());
        final echo = result as IsEcho;
        expect(echo.pending.target, equals('#channel'));
        expect(echo.pending.text, equals('Hello world'));
        expect(echo.confirmed.msgId, equals('server123'));
        expect(echo.confirmed.serverTime, isNotNull);
      });

      test('returns NotEcho for message from different user', () {
        handler.trackOutgoing(target: '#channel', text: 'Hello');

        final message = IrcMessage(
          source: 'otheruser!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = handler.checkMessage(message);
        expect(result, isA<NotEcho>());
        expect(handler.pendingCount, equals(1)); // Still pending
      });

      test('returns NotEcho for untracked message', () {
        // No trackOutgoing called

        final message = IrcMessage(
          source: 'testuser!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Untracked message'],
        );

        final result = handler.checkMessage(message);
        expect(result, isA<NotEcho>());
      });

      test('returns NotEcho for non-PRIVMSG/NOTICE', () {
        handler.trackOutgoing(target: '#channel', text: 'Hello');

        final message = IrcMessage(
          source: 'testuser!user@host',
          command: 'JOIN',
          params: ['#channel'],
        );

        final result = handler.checkMessage(message);
        expect(result, isA<NotEcho>());
      });

      test('handles NOTICE echoes', () {
        handler.trackOutgoing(target: '#channel', text: 'Notice text');

        final message = IrcMessage(
          tags: {'msgid': 'abc'},
          source: 'testuser!user@host',
          command: 'NOTICE',
          params: ['#channel', 'Notice text'],
        );

        final result = handler.checkMessage(message);
        expect(result, isA<IsEcho>());
      });

      test('removes pending message after echo', () {
        handler.trackOutgoing(target: '#channel', text: 'Hello');
        expect(handler.pendingCount, equals(1));

        final message = IrcMessage(
          source: 'testuser!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        handler.checkMessage(message);
        expect(handler.pendingCount, equals(0));
      });

      test('case-insensitive nick comparison', () {
        handler.trackOutgoing(target: '#channel', text: 'Hello');

        final message = IrcMessage(
          source: 'TestUser!user@host', // Different case
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = handler.checkMessage(message);
        expect(result, isA<IsEcho>());
      });

      test('matches correct pending message when multiple', () {
        handler.trackOutgoing(target: '#channel', text: 'First');
        handler.trackOutgoing(target: '#channel', text: 'Second');
        handler.trackOutgoing(target: '#channel', text: 'Third');

        // Echo of second message arrives
        final message = IrcMessage(
          tags: {'msgid': 'second-id'},
          source: 'testuser!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Second'],
        );

        final result = handler.checkMessage(message);
        expect(result, isA<IsEcho>());
        final echo = result as IsEcho;
        expect(echo.pending.text, equals('Second'));
        expect(echo.confirmed.msgId, equals('second-id'));

        // First and Third still pending
        expect(handler.pendingCount, equals(2));
      });
    });

    group('confirmedMessages stream', () {
      test('emits confirmed message on echo', () async {
        handler.trackOutgoing(target: '#channel', text: 'Hello');

        final future = handler.confirmedMessages.first;

        final message = IrcMessage(
          tags: {'msgid': 'xyz'},
          source: 'testuser!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        handler.checkMessage(message);

        final confirmed = await future;
        expect(confirmed.target, equals('#channel'));
        expect(confirmed.text, equals('Hello'));
        expect(confirmed.msgId, equals('xyz'));
      });
    });

    group('clearPending', () {
      test('removes all pending messages', () {
        handler.trackOutgoing(target: '#a', text: '1');
        handler.trackOutgoing(target: '#b', text: '2');
        expect(handler.pendingCount, equals(2));

        handler.clearPending();

        expect(handler.pendingCount, equals(0));
      });
    });

    group('pending timeout', () {
      test('expired messages are cleaned up', () async {
        final shortTimeoutHandler = EchoMessageHandler(
          currentNick: 'testuser',
          pendingTimeout: const Duration(milliseconds: 50),
        );

        shortTimeoutHandler.trackOutgoing(target: '#channel', text: 'Old');
        expect(shortTimeoutHandler.pendingCount, equals(1));

        // Wait for timeout
        await Future.delayed(const Duration(milliseconds: 100));

        // Tracking a new message triggers cleanup
        shortTimeoutHandler.trackOutgoing(target: '#channel', text: 'New');

        // Old message should be cleaned up
        expect(shortTimeoutHandler.pendingCount, equals(1));

        shortTimeoutHandler.dispose();
      });
    });
  });

  group('MutableEchoMessageHandler', () {
    test('updateNick changes comparison nick', () {
      final handler = MutableEchoMessageHandler(currentNick: 'oldnick');

      handler.trackOutgoing(target: '#channel', text: 'Hello');

      // Message from old nick - should still match
      var message = IrcMessage(
        source: 'oldnick!user@host',
        command: 'PRIVMSG',
        params: ['#channel', 'Hello'],
      );

      var result = handler.checkMessage(message);
      expect(result, isA<IsEcho>());

      // Track another and change nick
      handler.trackOutgoing(target: '#channel', text: 'Hello again');
      handler.updateNick('newnick');

      // Message from new nick
      message = IrcMessage(
        source: 'newnick!user@host',
        command: 'PRIVMSG',
        params: ['#channel', 'Hello again'],
      );

      result = handler.checkMessage(message);
      expect(result, isA<IsEcho>());

      // Message from old nick should not match anymore
      handler.trackOutgoing(target: '#channel', text: 'Test');
      message = IrcMessage(
        source: 'oldnick!user@host',
        command: 'PRIVMSG',
        params: ['#channel', 'Test'],
      );

      result = handler.checkMessage(message);
      expect(result, isA<NotEcho>());

      handler.dispose();
    });
  });
}
