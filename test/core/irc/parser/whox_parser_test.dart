import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/parser/whox_parser.dart';
import 'package:test/test.dart';

void main() {
  group('WhoxParser', () {
    group('parse', () {
      test('returns null for non-354 messages', () {
        final message = IrcMessage(
          source: 'server',
          command: '352',
          params: ['mynick', '#channel', 'user', 'host', 'server', 'nick', 'H', '0 realname'],
        );

        final result = WhoxParser.parse(message, 'tcuhnfar');
        expect(result, isNull);
      });

      test('parses standard fields (tcuhnfar)', () {
        final message = IrcMessage(
          source: 'server',
          command: '354',
          params: [
            'mynick',
            '123', // t - query type
            '#channel', // c - channel
            'username', // u - username
            'hostname', // h - hostname
            'nickname', // n - nickname
            'H@', // f - flags
            'account', // a - account
            'Real Name', // r - realname
          ],
        );

        final result = WhoxParser.parse(message, 'tcuhnfar');

        expect(result, isNotNull);
        expect(result!.queryType, equals('123'));
        expect(result.channel, equals('#channel'));
        expect(result.username, equals('username'));
        expect(result.hostname, equals('hostname'));
        expect(result.nickname, equals('nickname'));
        expect(result.flags, equals('H@'));
        expect(result.account, equals('account'));
        expect(result.realname, equals('Real Name'));
      });

      test('parses minimal fields (na)', () {
        final message = IrcMessage(
          source: 'server',
          command: '354',
          params: ['mynick', 'nickname', 'account'],
        );

        final result = WhoxParser.parse(message, 'na');

        expect(result, isNotNull);
        expect(result!.nickname, equals('nickname'));
        expect(result.account, equals('account'));
        expect(result.channel, isNull);
      });

      test('parses numeric fields', () {
        final message = IrcMessage(
          source: 'server',
          command: '354',
          params: ['mynick', '3', '120'],
        );

        final result = WhoxParser.parse(message, 'dl');

        expect(result, isNotNull);
        expect(result!.hopCount, equals(3));
        expect(result.idleTime, equals(120));
      });

      test('handles 0 for no account', () {
        final message = IrcMessage(
          source: 'server',
          command: '354',
          params: ['mynick', 'nick', '0'],
        );

        final result = WhoxParser.parse(message, 'na');

        expect(result, isNotNull);
        expect(result!.account, equals('0'));
        expect(result.hasAccount, isFalse);
      });

      test('handles real account', () {
        final message = IrcMessage(
          source: 'server',
          command: '354',
          params: ['mynick', 'nick', 'myaccount'],
        );

        final result = WhoxParser.parse(message, 'na');

        expect(result, isNotNull);
        expect(result!.account, equals('myaccount'));
        expect(result.hasAccount, isTrue);
      });

      test('returns null for insufficient params', () {
        final message = IrcMessage(
          source: 'server',
          command: '354',
          params: ['mynick'],
        );

        final result = WhoxParser.parse(message, 'na');
        expect(result, isNull);
      });
    });

    group('isWhoxResponse', () {
      test('returns true for 354', () {
        final message = IrcMessage(command: '354', params: ['nick']);
        expect(WhoxParser.isWhoxResponse(message), isTrue);
      });

      test('returns false for other numerics', () {
        final message = IrcMessage(command: '352', params: ['nick']);
        expect(WhoxParser.isWhoxResponse(message), isFalse);
      });
    });

    group('isEndOfWho', () {
      test('returns true for 315', () {
        final message = IrcMessage(command: '315', params: ['nick', 'End of WHO']);
        expect(WhoxParser.isEndOfWho(message), isTrue);
      });

      test('returns false for other numerics', () {
        final message = IrcMessage(command: '354', params: ['nick']);
        expect(WhoxParser.isEndOfWho(message), isFalse);
      });
    });
  });

  group('WhoxResponse', () {
    test('equality', () {
      const response1 = WhoxResponse(
        nickname: 'nick',
        account: 'account',
        channel: '#channel',
      );

      const response2 = WhoxResponse(
        nickname: 'nick',
        account: 'account',
        channel: '#channel',
      );

      const response3 = WhoxResponse(
        nickname: 'nick',
        account: 'different',
        channel: '#channel',
      );

      expect(response1, equals(response2));
      expect(response1, isNot(equals(response3)));
    });

    test('toString', () {
      const response = WhoxResponse(
        nickname: 'nick',
        account: 'account',
        channel: '#channel',
      );

      expect(response.toString(), contains('nick'));
      expect(response.toString(), contains('account'));
      expect(response.toString(), contains('#channel'));
    });

    test('isAway', () {
      const away = WhoxResponse(flags: 'G@');
      const here = WhoxResponse(flags: 'H@');
      const noFlags = WhoxResponse();

      expect(away.isAway, isTrue);
      expect(here.isAway, isFalse);
      expect(noFlags.isAway, isFalse);
    });

    test('isOper', () {
      const oper = WhoxResponse(flags: 'H*@');
      const notOper = WhoxResponse(flags: 'H@');
      const noFlags = WhoxResponse();

      expect(oper.isOper, isTrue);
      expect(notOper.isOper, isFalse);
      expect(noFlags.isOper, isFalse);
    });

    test('hasAccount', () {
      const withAccount = WhoxResponse(account: 'myaccount');
      const noAccount = WhoxResponse(account: '0');
      const nullAccount = WhoxResponse();

      expect(withAccount.hasAccount, isTrue);
      expect(noAccount.hasAccount, isFalse);
      expect(nullAccount.hasAccount, isFalse);
    });
  });

  group('WhoxParser constants', () {
    test('rplWhospcrpl is 354', () {
      expect(WhoxParser.rplWhospcrpl, equals(354));
    });
  });
}
