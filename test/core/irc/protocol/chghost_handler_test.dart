import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/protocol/chghost_handler.dart';
import 'package:test/test.dart';

void main() {
  group('ChghostHandler', () {
    late ChghostHandler handler;

    setUp(() {
      handler = ChghostHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('handleMessage', () {
      test('returns null for non-CHGHOST messages', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('parses CHGHOST with full source', () {
        final message = IrcMessage(
          source: 'nick!olduser@oldhost.example.com',
          command: 'CHGHOST',
          params: ['newuser', 'newhost.example.com'],
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.nick, equals('nick'));
        expect(result.oldUser, equals('olduser'));
        expect(result.oldHost, equals('oldhost.example.com'));
        expect(result.newUser, equals('newuser'));
        expect(result.newHost, equals('newhost.example.com'));
      });

      test('returns null for CHGHOST without source', () {
        final message = IrcMessage(
          command: 'CHGHOST',
          params: ['newuser', 'newhost'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('returns null for CHGHOST with insufficient params', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'CHGHOST',
          params: ['newuser'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('returns null for CHGHOST with empty params', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'CHGHOST',
          params: [],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('handles source with only nick', () {
        final message = IrcMessage(
          source: 'nick',
          command: 'CHGHOST',
          params: ['newuser', 'newhost'],
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.nick, equals('nick'));
        expect(result.oldUser, isNull);
        expect(result.oldHost, isNull);
        expect(result.newUser, equals('newuser'));
        expect(result.newHost, equals('newhost'));
      });
    });

    group('hostChanges stream', () {
      test('emits change when handling CHGHOST message', () async {
        final future = handler.hostChanges.first;

        final message = IrcMessage(
          source: 'nick!olduser@oldhost',
          command: 'CHGHOST',
          params: ['newuser', 'newhost'],
        );

        handler.handleMessage(message);

        final change = await future;
        expect(change.nick, equals('nick'));
        expect(change.newUser, equals('newuser'));
        expect(change.newHost, equals('newhost'));
      });

      test('emits multiple host changes', () async {
        final changes = <HostChange>[];
        final subscription = handler.hostChanges.listen(changes.add);

        handler.handleMessage(IrcMessage(
          source: 'alice!olduser@oldhost',
          command: 'CHGHOST',
          params: ['alice', 'cloak.example.com'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'bob!user@host',
          command: 'CHGHOST',
          params: ['bob', 'vhost.example.com'],
        ));

        // Allow stream to process
        await Future.delayed(Duration.zero);

        expect(changes.length, equals(2));
        expect(changes[0].nick, equals('alice'));
        expect(changes[0].newHost, equals('cloak.example.com'));
        expect(changes[1].nick, equals('bob'));
        expect(changes[1].newHost, equals('vhost.example.com'));

        await subscription.cancel();
      });
    });

    group('isChghostMessage', () {
      test('returns true for CHGHOST command', () {
        final message = IrcMessage(command: 'CHGHOST', params: ['a', 'b']);
        expect(ChghostHandler.isChghostMessage(message), isTrue);
      });

      test('returns false for other commands', () {
        final message = IrcMessage(command: 'PRIVMSG', params: []);
        expect(ChghostHandler.isChghostMessage(message), isFalse);
      });
    });
  });

  group('HostChange', () {
    test('equality', () {
      final change1 = HostChange(
        nick: 'nick',
        oldUser: 'olduser',
        oldHost: 'oldhost',
        newUser: 'newuser',
        newHost: 'newhost',
        timestamp: DateTime(2024),
      );

      final change2 = HostChange(
        nick: 'nick',
        oldUser: 'olduser',
        oldHost: 'oldhost',
        newUser: 'newuser',
        newHost: 'newhost',
        timestamp: DateTime(2025), // Different timestamp
      );

      final change3 = HostChange(
        nick: 'nick',
        oldUser: 'olduser',
        oldHost: 'oldhost',
        newUser: 'different',
        newHost: 'newhost',
        timestamp: DateTime(2024),
      );

      // Same except timestamp (not compared)
      expect(change1, equals(change2));

      // Different newUser
      expect(change1, isNot(equals(change3)));
    });

    test('toString', () {
      final change = HostChange(
        nick: 'nick',
        oldUser: 'olduser',
        oldHost: 'oldhost',
        newUser: 'newuser',
        newHost: 'newhost',
        timestamp: DateTime.now(),
      );

      expect(change.toString(), contains('nick'));
      expect(change.toString(), contains('olduser@oldhost'));
      expect(change.toString(), contains('newuser@newhost'));
    });
  });
}
