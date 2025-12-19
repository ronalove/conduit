import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/protocol/setname_handler.dart';
import 'package:test/test.dart';

void main() {
  group('SetnameHandler', () {
    late SetnameHandler handler;

    setUp(() {
      handler = SetnameHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('handleMessage', () {
      test('returns null for non-SETNAME messages', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('parses SETNAME with full source', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'SETNAME',
          params: ['New Real Name'],
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.nick, equals('nick'));
        expect(result.user, equals('user'));
        expect(result.host, equals('host'));
        expect(result.realname, equals('New Real Name'));
      });

      test('returns null for SETNAME without source', () {
        final message = IrcMessage(
          command: 'SETNAME',
          params: ['New Real Name'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('returns null for SETNAME without params', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'SETNAME',
          params: [],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('handles source with only nick', () {
        final message = IrcMessage(
          source: 'nick',
          command: 'SETNAME',
          params: ['New Name'],
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.nick, equals('nick'));
        expect(result.user, isNull);
        expect(result.host, isNull);
        expect(result.realname, equals('New Name'));
      });

      test('handles empty realname', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'SETNAME',
          params: [''],
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.realname, equals(''));
      });
    });

    group('realnameChanges stream', () {
      test('emits change when handling SETNAME message', () async {
        final future = handler.realnameChanges.first;

        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'SETNAME',
          params: ['New Real Name'],
        );

        handler.handleMessage(message);

        final change = await future;
        expect(change.nick, equals('nick'));
        expect(change.realname, equals('New Real Name'));
      });

      test('emits multiple realname changes', () async {
        final changes = <RealnameChange>[];
        final subscription = handler.realnameChanges.listen(changes.add);

        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'SETNAME',
          params: ['Alice Smith'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'bob!user@host',
          command: 'SETNAME',
          params: ['Bob Jones'],
        ));

        // Allow stream to process
        await Future.delayed(Duration.zero);

        expect(changes.length, equals(2));
        expect(changes[0].nick, equals('alice'));
        expect(changes[0].realname, equals('Alice Smith'));
        expect(changes[1].nick, equals('bob'));
        expect(changes[1].realname, equals('Bob Jones'));

        await subscription.cancel();
      });
    });

    group('isSetnameMessage', () {
      test('returns true for SETNAME command', () {
        final message = IrcMessage(command: 'SETNAME', params: ['name']);
        expect(SetnameHandler.isSetnameMessage(message), isTrue);
      });

      test('returns false for other commands', () {
        final message = IrcMessage(command: 'PRIVMSG', params: []);
        expect(SetnameHandler.isSetnameMessage(message), isFalse);
      });
    });
  });

  group('RealnameChange', () {
    test('equality', () {
      final change1 = RealnameChange(
        nick: 'nick',
        user: 'user',
        host: 'host',
        realname: 'Real Name',
        timestamp: DateTime(2024),
      );

      final change2 = RealnameChange(
        nick: 'nick',
        user: 'user',
        host: 'host',
        realname: 'Real Name',
        timestamp: DateTime(2025), // Different timestamp
      );

      final change3 = RealnameChange(
        nick: 'nick',
        user: 'user',
        host: 'host',
        realname: 'Different Name',
        timestamp: DateTime(2024),
      );

      // Same except timestamp (not compared)
      expect(change1, equals(change2));

      // Different realname
      expect(change1, isNot(equals(change3)));
    });

    test('toString', () {
      final change = RealnameChange(
        nick: 'nick',
        realname: 'My Real Name',
        timestamp: DateTime.now(),
      );

      expect(change.toString(), contains('nick'));
      expect(change.toString(), contains('My Real Name'));
    });
  });
}
