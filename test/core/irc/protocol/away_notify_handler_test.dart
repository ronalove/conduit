import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/protocol/away_notify_handler.dart';
import 'package:test/test.dart';

void main() {
  group('AwayNotifyHandler', () {
    late AwayNotifyHandler handler;

    setUp(() {
      handler = AwayNotifyHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('handleMessage', () {
      test('returns null for non-AWAY messages', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('parses AWAY with message (user is away)', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'AWAY',
          params: ['Gone for lunch'],
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.nick, equals('nick'));
        expect(result.user, equals('user'));
        expect(result.host, equals('host'));
        expect(result.isAway, isTrue);
        expect(result.message, equals('Gone for lunch'));
      });

      test('parses AWAY without message (user is back)', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'AWAY',
          params: [],
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.nick, equals('nick'));
        expect(result.isAway, isFalse);
        expect(result.message, isNull);
      });

      test('returns null for AWAY without source', () {
        final message = IrcMessage(
          command: 'AWAY',
          params: ['Away message'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('handles source with only nick', () {
        final message = IrcMessage(
          source: 'nick',
          command: 'AWAY',
          params: ['BRB'],
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.nick, equals('nick'));
        expect(result.user, isNull);
        expect(result.host, isNull);
        expect(result.isAway, isTrue);
        expect(result.message, equals('BRB'));
      });
    });

    group('statusChanges stream', () {
      test('emits status when handling AWAY message', () async {
        final future = handler.statusChanges.first;

        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'AWAY',
          params: ['Meeting'],
        );

        handler.handleMessage(message);

        final status = await future;
        expect(status.nick, equals('nick'));
        expect(status.isAway, isTrue);
        expect(status.message, equals('Meeting'));
      });

      test('emits multiple status changes', () async {
        final statuses = <AwayStatus>[];
        final subscription = handler.statusChanges.listen(statuses.add);

        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'AWAY',
          params: ['Gone'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'bob!user@host',
          command: 'AWAY',
          params: [],
        ));

        // Allow stream to process
        await Future.delayed(Duration.zero);

        expect(statuses.length, equals(2));
        expect(statuses[0].nick, equals('alice'));
        expect(statuses[0].isAway, isTrue);
        expect(statuses[1].nick, equals('bob'));
        expect(statuses[1].isAway, isFalse);

        await subscription.cancel();
      });
    });

    group('isAwayMessage', () {
      test('returns true for AWAY command', () {
        final message = IrcMessage(command: 'AWAY', params: []);
        expect(AwayNotifyHandler.isAwayMessage(message), isTrue);
      });

      test('returns false for other commands', () {
        final message = IrcMessage(command: 'PRIVMSG', params: []);
        expect(AwayNotifyHandler.isAwayMessage(message), isFalse);
      });
    });
  });

  group('AwayStatus', () {
    test('equality', () {
      final status1 = AwayStatus(
        nick: 'nick',
        user: 'user',
        host: 'host',
        isAway: true,
        message: 'Away',
        timestamp: DateTime(2024),
      );

      final status2 = AwayStatus(
        nick: 'nick',
        user: 'user',
        host: 'host',
        isAway: true,
        message: 'Away',
        timestamp: DateTime(2025), // Different timestamp
      );

      final status3 = AwayStatus(
        nick: 'nick',
        user: 'user',
        host: 'host',
        isAway: false,
        message: null,
        timestamp: DateTime(2024),
      );

      // Same except timestamp (not compared)
      expect(status1, equals(status2));

      // Different isAway
      expect(status1, isNot(equals(status3)));
    });

    test('toString', () {
      final status = AwayStatus(
        nick: 'nick',
        isAway: true,
        message: 'BRB',
        timestamp: DateTime.now(),
      );

      expect(status.toString(), contains('nick'));
      expect(status.toString(), contains('isAway: true'));
      expect(status.toString(), contains('BRB'));
    });
  });
}
