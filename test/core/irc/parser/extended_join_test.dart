import 'package:conduit/core/irc/parser/extended_join.dart';
import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:test/test.dart';

void main() {
  group('ExtendedJoinParser', () {
    group('parse', () {
      test('returns null for non-JOIN messages', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = ExtendedJoinParser.parse(message);
        expect(result, isNull);
      });

      test('parses standard JOIN (no extended info)', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'JOIN',
          params: ['#channel'],
        );

        final result = ExtendedJoinParser.parse(message);

        expect(result, isNotNull);
        expect(result!.nick, equals('nick'));
        expect(result.user, equals('user'));
        expect(result.host, equals('host'));
        expect(result.channel, equals('#channel'));
        expect(result.account, isNull);
        expect(result.realname, isNull);
        expect(result.hasAccount, isFalse);
      });

      test('parses extended JOIN with account and realname', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'JOIN',
          params: ['#channel', 'myaccount', 'Real Name'],
        );

        final result = ExtendedJoinParser.parse(message);

        expect(result, isNotNull);
        expect(result!.nick, equals('nick'));
        expect(result.channel, equals('#channel'));
        expect(result.account, equals('myaccount'));
        expect(result.realname, equals('Real Name'));
        expect(result.hasAccount, isTrue);
      });

      test('parses extended JOIN with * (not logged in)', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'JOIN',
          params: ['#channel', '*', 'Real Name'],
        );

        final result = ExtendedJoinParser.parse(message);

        expect(result, isNotNull);
        expect(result!.nick, equals('nick'));
        expect(result.channel, equals('#channel'));
        expect(result.account, isNull);
        expect(result.realname, equals('Real Name'));
        expect(result.hasAccount, isFalse);
      });

      test('parses extended JOIN with only account', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'JOIN',
          params: ['#channel', 'myaccount'],
        );

        final result = ExtendedJoinParser.parse(message);

        expect(result, isNotNull);
        expect(result!.account, equals('myaccount'));
        expect(result.realname, isNull);
      });

      test('returns null for JOIN without source', () {
        final message = IrcMessage(
          command: 'JOIN',
          params: ['#channel'],
        );

        final result = ExtendedJoinParser.parse(message);
        expect(result, isNull);
      });

      test('returns null for JOIN without params', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'JOIN',
          params: [],
        );

        final result = ExtendedJoinParser.parse(message);
        expect(result, isNull);
      });

      test('handles source with only nick', () {
        final message = IrcMessage(
          source: 'nick',
          command: 'JOIN',
          params: ['#channel', 'account', 'Real Name'],
        );

        final result = ExtendedJoinParser.parse(message);

        expect(result, isNotNull);
        expect(result!.nick, equals('nick'));
        expect(result.user, isNull);
        expect(result.host, isNull);
      });
    });

    group('isJoinMessage', () {
      test('returns true for JOIN command', () {
        final message = IrcMessage(command: 'JOIN', params: ['#channel']);
        expect(ExtendedJoinParser.isJoinMessage(message), isTrue);
      });

      test('returns false for other commands', () {
        final message = IrcMessage(command: 'PRIVMSG', params: []);
        expect(ExtendedJoinParser.isJoinMessage(message), isFalse);
      });
    });

    group('isExtendedJoin', () {
      test('returns true for extended JOIN', () {
        final message = IrcMessage(
          command: 'JOIN',
          params: ['#channel', 'account', 'Real Name'],
        );
        expect(ExtendedJoinParser.isExtendedJoin(message), isTrue);
      });

      test('returns true for extended JOIN with only account', () {
        final message = IrcMessage(
          command: 'JOIN',
          params: ['#channel', 'account'],
        );
        expect(ExtendedJoinParser.isExtendedJoin(message), isTrue);
      });

      test('returns false for standard JOIN', () {
        final message = IrcMessage(
          command: 'JOIN',
          params: ['#channel'],
        );
        expect(ExtendedJoinParser.isExtendedJoin(message), isFalse);
      });

      test('returns false for non-JOIN', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'account'],
        );
        expect(ExtendedJoinParser.isExtendedJoin(message), isFalse);
      });
    });
  });

  group('ExtendedJoin', () {
    test('equality', () {
      const join1 = ExtendedJoin(
        nick: 'nick',
        user: 'user',
        host: 'host',
        channel: '#channel',
        account: 'account',
        realname: 'Real Name',
      );

      const join2 = ExtendedJoin(
        nick: 'nick',
        user: 'user',
        host: 'host',
        channel: '#channel',
        account: 'account',
        realname: 'Real Name',
      );

      const join3 = ExtendedJoin(
        nick: 'nick',
        user: 'user',
        host: 'host',
        channel: '#channel',
        account: 'different',
        realname: 'Real Name',
      );

      expect(join1, equals(join2));
      expect(join1, isNot(equals(join3)));
    });

    test('toString', () {
      const join = ExtendedJoin(
        nick: 'nick',
        channel: '#channel',
        account: 'myaccount',
      );

      expect(join.toString(), contains('nick'));
      expect(join.toString(), contains('#channel'));
      expect(join.toString(), contains('myaccount'));
    });

    test('hasAccount', () {
      const withAccount = ExtendedJoin(
        nick: 'nick',
        channel: '#channel',
        account: 'account',
      );

      const withoutAccount = ExtendedJoin(
        nick: 'nick',
        channel: '#channel',
        account: null,
      );

      expect(withAccount.hasAccount, isTrue);
      expect(withoutAccount.hasAccount, isFalse);
    });
  });
}
