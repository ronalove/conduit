import 'dart:async';

import 'package:conduit/core/irc/commands/typing_commands.dart';
import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/parser/message_tags.dart';
import 'package:conduit/core/irc/protocol/typing_handler.dart';
import 'package:test/test.dart';

void main() {
  group('TypingHandler', () {
    late TypingHandler handler;

    setUp(() {
      handler = TypingHandler(
        activeExpiry: const Duration(milliseconds: 100),
        pausedExpiry: const Duration(milliseconds: 200),
      );
    });

    tearDown(() {
      handler.dispose();
    });

    group('handleMessage', () {
      test('returns false for non-TAGMSG messages', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        expect(handler.handleMessage(message), isFalse);
      });

      test('returns false for TAGMSG without typing tag', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {'+draft/react': 'thumbsup'},
        );

        expect(handler.handleMessage(message), isFalse);
      });

      test('returns true for TAGMSG with typing tag', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        );

        expect(handler.handleMessage(message), isTrue);
      });

      test('returns false for TAGMSG without source', () {
        final message = IrcMessage(
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        );

        expect(handler.handleMessage(message), isFalse);
      });

      test('returns false for TAGMSG without params', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'TAGMSG',
          params: [],
          tags: {IrcTags.typing: 'active'},
        );

        expect(handler.handleMessage(message), isFalse);
      });

      test('returns false for invalid typing state', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'invalid'},
        );

        expect(handler.handleMessage(message), isFalse);
      });

      test('parses active typing state', () {
        final message = IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        );

        handler.handleMessage(message);

        expect(handler.isUserTyping('#channel', 'alice'), isTrue);
        expect(handler.getUserTypingState('#channel', 'alice'), equals(TypingState.active));
      });

      test('parses paused typing state', () {
        final message = IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'paused'},
        );

        handler.handleMessage(message);

        expect(handler.isUserTyping('#channel', 'alice'), isTrue);
        expect(handler.getUserTypingState('#channel', 'alice'), equals(TypingState.paused));
      });

      test('done state removes user from typing list', () {
        // First set active
        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        ));

        expect(handler.isUserTyping('#channel', 'alice'), isTrue);

        // Then send done
        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'done'},
        ));

        expect(handler.isUserTyping('#channel', 'alice'), isFalse);
        expect(handler.getUserTypingState('#channel', 'alice'), isNull);
      });
    });

    group('notifications stream', () {
      test('emits notification for typing state', () async {
        final future = handler.notifications.first;

        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        ));

        final notification = await future;
        expect(notification.nick, equals('alice'));
        expect(notification.user, equals('user'));
        expect(notification.host, equals('host'));
        expect(notification.target, equals('#channel'));
        expect(notification.state, equals(TypingState.active));
      });

      test('emits multiple notifications', () async {
        final notifications = <TypingNotification>[];
        final subscription = handler.notifications.listen(notifications.add);

        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        ));

        handler.handleMessage(IrcMessage(
          source: 'bob!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'paused'},
        ));

        await Future.delayed(Duration.zero);

        expect(notifications.length, equals(2));
        expect(notifications[0].nick, equals('alice'));
        expect(notifications[1].nick, equals('bob'));

        await subscription.cancel();
      });
    });

    group('getTypingUsers', () {
      test('returns empty list for unknown target', () {
        expect(handler.getTypingUsers('#unknown'), isEmpty);
      });

      test('returns all typing users for target', () {
        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        ));

        handler.handleMessage(IrcMessage(
          source: 'bob!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'paused'},
        ));

        final users = handler.getTypingUsers('#channel');
        expect(users.length, equals(2));
        expect(users.map((u) => u.nick).toSet(), equals({'alice', 'bob'}));
      });

      test('excludes users who sent done', () {
        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        ));

        handler.handleMessage(IrcMessage(
          source: 'bob!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'done'},
        ));

        final users = handler.getTypingUsers('#channel');
        expect(users.length, equals(1));
        expect(users[0].nick, equals('alice'));
      });
    });

    group('isUserTyping', () {
      test('returns false for unknown user', () {
        expect(handler.isUserTyping('#channel', 'unknown'), isFalse);
      });

      test('returns true for active user', () {
        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        ));

        expect(handler.isUserTyping('#channel', 'alice'), isTrue);
      });

      test('returns true for paused user', () {
        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'paused'},
        ));

        expect(handler.isUserTyping('#channel', 'alice'), isTrue);
      });

      test('is case insensitive for nick', () {
        handler.handleMessage(IrcMessage(
          source: 'Alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        ));

        expect(handler.isUserTyping('#channel', 'alice'), isTrue);
        expect(handler.isUserTyping('#channel', 'ALICE'), isTrue);
      });
    });

    group('auto expiry', () {
      test('active typing expires after timeout', () async {
        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        ));

        expect(handler.isUserTyping('#channel', 'alice'), isTrue);

        await Future.delayed(const Duration(milliseconds: 150));

        expect(handler.isUserTyping('#channel', 'alice'), isFalse);
      });

      test('paused typing expires after longer timeout', () async {
        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'paused'},
        ));

        expect(handler.isUserTyping('#channel', 'alice'), isTrue);

        // Should still be typing after active timeout
        await Future.delayed(const Duration(milliseconds: 150));
        expect(handler.isUserTyping('#channel', 'alice'), isTrue);

        // Should expire after paused timeout
        await Future.delayed(const Duration(milliseconds: 100));
        expect(handler.isUserTyping('#channel', 'alice'), isFalse);
      });

      test('expired stream emits when typing expires', () async {
        final expiredFuture = handler.expired.first;

        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        ));

        final expired = await expiredFuture;
        expect(expired.nick, equals('alice'));
        expect(expired.target, equals('#channel'));
        expect(expired.lastState, equals(TypingState.active));
      });

      test('new typing notification resets expiry timer', () async {
        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        ));

        await Future.delayed(const Duration(milliseconds: 80));

        // Send another active notification
        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        ));

        await Future.delayed(const Duration(milliseconds: 80));

        // Should still be typing because timer was reset
        expect(handler.isUserTyping('#channel', 'alice'), isTrue);
      });
    });

    group('clearTarget', () {
      test('removes all typing users for target', () {
        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        ));

        handler.handleMessage(IrcMessage(
          source: 'bob!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        ));

        expect(handler.getTypingUsers('#channel').length, equals(2));

        handler.clearTarget('#channel');

        expect(handler.getTypingUsers('#channel'), isEmpty);
      });
    });

    group('clearUser', () {
      test('removes specific user typing indicator', () {
        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        ));

        handler.handleMessage(IrcMessage(
          source: 'bob!user@host',
          command: 'TAGMSG',
          params: ['#channel'],
          tags: {IrcTags.typing: 'active'},
        ));

        handler.clearUser('#channel', 'alice');

        expect(handler.isUserTyping('#channel', 'alice'), isFalse);
        expect(handler.isUserTyping('#channel', 'bob'), isTrue);
      });
    });
  });

  group('TypingNotification', () {
    test('isChannel returns true for channel targets', () {
      final notification = TypingNotification(
        nick: 'alice',
        target: '#channel',
        state: TypingState.active,
        receivedAt: DateTime.now(),
      );

      expect(notification.isChannel, isTrue);
    });

    test('isChannel returns false for private message targets', () {
      final notification = TypingNotification(
        nick: 'alice',
        target: 'bob',
        state: TypingState.active,
        receivedAt: DateTime.now(),
      );

      expect(notification.isChannel, isFalse);
    });

    test('isChannel handles different channel prefixes', () {
      expect(
        TypingNotification(
          nick: 'n',
          target: '&channel',
          state: TypingState.active,
          receivedAt: DateTime.now(),
        ).isChannel,
        isTrue,
      );

      expect(
        TypingNotification(
          nick: 'n',
          target: '+channel',
          state: TypingState.active,
          receivedAt: DateTime.now(),
        ).isChannel,
        isTrue,
      );

      expect(
        TypingNotification(
          nick: 'n',
          target: '!channel',
          state: TypingState.active,
          receivedAt: DateTime.now(),
        ).isChannel,
        isTrue,
      );
    });

    test('isActive/isPaused/isDone return correct values', () {
      final active = TypingNotification(
        nick: 'n',
        target: '#c',
        state: TypingState.active,
        receivedAt: DateTime.now(),
      );
      expect(active.isActive, isTrue);
      expect(active.isPaused, isFalse);
      expect(active.isDone, isFalse);

      final paused = TypingNotification(
        nick: 'n',
        target: '#c',
        state: TypingState.paused,
        receivedAt: DateTime.now(),
      );
      expect(paused.isActive, isFalse);
      expect(paused.isPaused, isTrue);
      expect(paused.isDone, isFalse);

      final done = TypingNotification(
        nick: 'n',
        target: '#c',
        state: TypingState.done,
        receivedAt: DateTime.now(),
      );
      expect(done.isActive, isFalse);
      expect(done.isPaused, isFalse);
      expect(done.isDone, isTrue);
    });

    test('toString returns readable string', () {
      final notification = TypingNotification(
        nick: 'alice',
        target: '#channel',
        state: TypingState.active,
        receivedAt: DateTime.now(),
      );

      final str = notification.toString();
      expect(str, contains('alice'));
      expect(str, contains('#channel'));
      expect(str, contains('active'));
    });
  });

  group('TypingExpired', () {
    test('toString returns readable string', () {
      const expired = TypingExpired(
        nick: 'alice',
        target: '#channel',
        lastState: TypingState.active,
      );

      final str = expired.toString();
      expect(str, contains('alice'));
      expect(str, contains('#channel'));
    });
  });
}
