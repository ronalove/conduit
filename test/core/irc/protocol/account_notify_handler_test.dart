import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/protocol/account_notify_handler.dart';
import 'package:test/test.dart';

void main() {
  group('AccountNotifyHandler', () {
    late AccountNotifyHandler handler;

    setUp(() {
      handler = AccountNotifyHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('handleMessage', () {
      test('returns null for non-ACCOUNT messages', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('parses ACCOUNT with account name (login)', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'ACCOUNT',
          params: ['myaccount'],
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.nick, equals('nick'));
        expect(result.user, equals('user'));
        expect(result.host, equals('host'));
        expect(result.account, equals('myaccount'));
        expect(result.isLoggedIn, isTrue);
        expect(result.isLoggedOut, isFalse);
      });

      test('parses ACCOUNT * (logout)', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'ACCOUNT',
          params: ['*'],
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.nick, equals('nick'));
        expect(result.account, isNull);
        expect(result.isLoggedIn, isFalse);
        expect(result.isLoggedOut, isTrue);
      });

      test('returns null for ACCOUNT without source', () {
        final message = IrcMessage(
          command: 'ACCOUNT',
          params: ['myaccount'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('returns null for ACCOUNT without params', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'ACCOUNT',
          params: [],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('handles source with only nick', () {
        final message = IrcMessage(
          source: 'nick',
          command: 'ACCOUNT',
          params: ['myaccount'],
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.nick, equals('nick'));
        expect(result.user, isNull);
        expect(result.host, isNull);
        expect(result.account, equals('myaccount'));
      });
    });

    group('accountChanges stream', () {
      test('emits change when handling ACCOUNT message', () async {
        final future = handler.accountChanges.first;

        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'ACCOUNT',
          params: ['myaccount'],
        );

        handler.handleMessage(message);

        final change = await future;
        expect(change.nick, equals('nick'));
        expect(change.account, equals('myaccount'));
      });

      test('emits multiple account changes', () async {
        final changes = <AccountChange>[];
        final subscription = handler.accountChanges.listen(changes.add);

        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'ACCOUNT',
          params: ['alice_account'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'bob!user@host',
          command: 'ACCOUNT',
          params: ['*'],
        ));

        // Allow stream to process
        await Future.delayed(Duration.zero);

        expect(changes.length, equals(2));
        expect(changes[0].nick, equals('alice'));
        expect(changes[0].isLoggedIn, isTrue);
        expect(changes[1].nick, equals('bob'));
        expect(changes[1].isLoggedOut, isTrue);

        await subscription.cancel();
      });
    });

    group('isAccountMessage', () {
      test('returns true for ACCOUNT command', () {
        final message = IrcMessage(command: 'ACCOUNT', params: ['test']);
        expect(AccountNotifyHandler.isAccountMessage(message), isTrue);
      });

      test('returns false for other commands', () {
        final message = IrcMessage(command: 'PRIVMSG', params: []);
        expect(AccountNotifyHandler.isAccountMessage(message), isFalse);
      });
    });
  });

  group('AccountChange', () {
    test('equality', () {
      final change1 = AccountChange(
        nick: 'nick',
        user: 'user',
        host: 'host',
        account: 'account',
        timestamp: DateTime(2024),
      );

      final change2 = AccountChange(
        nick: 'nick',
        user: 'user',
        host: 'host',
        account: 'account',
        timestamp: DateTime(2025), // Different timestamp
      );

      final change3 = AccountChange(
        nick: 'nick',
        user: 'user',
        host: 'host',
        account: null,
        timestamp: DateTime(2024),
      );

      // Same except timestamp (not compared)
      expect(change1, equals(change2));

      // Different account
      expect(change1, isNot(equals(change3)));
    });

    test('toString', () {
      final change = AccountChange(
        nick: 'nick',
        account: 'myaccount',
        timestamp: DateTime.now(),
      );

      expect(change.toString(), contains('nick'));
      expect(change.toString(), contains('myaccount'));
    });

    test('isLoggedIn and isLoggedOut', () {
      final loggedIn = AccountChange(
        nick: 'nick',
        account: 'account',
        timestamp: DateTime.now(),
      );

      final loggedOut = AccountChange(
        nick: 'nick',
        account: null,
        timestamp: DateTime.now(),
      );

      expect(loggedIn.isLoggedIn, isTrue);
      expect(loggedIn.isLoggedOut, isFalse);
      expect(loggedOut.isLoggedIn, isFalse);
      expect(loggedOut.isLoggedOut, isTrue);
    });
  });
}
