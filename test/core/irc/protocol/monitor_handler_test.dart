import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/protocol/monitor_handler.dart';
import 'package:test/test.dart';

void main() {
  group('MonitorHandler', () {
    late MonitorHandler handler;

    setUp(() {
      handler = MonitorHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('handleMessage', () {
      test('returns null for non-monitor messages', () {
        final message = IrcMessage(
          source: 'server',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      group('RPL_MONONLINE (730)', () {
        test('parses online users', () {
          final message = IrcMessage(
            source: 'server',
            command: '730',
            params: ['mynick', 'alice!user@host,bob!user@host'],
          );

          final result = handler.handleMessage(message);

          expect(result, isA<MonitorOnline>());
          final online = result as MonitorOnline;
          expect(online.users.length, equals(2));
          expect(online.users[0].nick, equals('alice'));
          expect(online.users[0].isOnline, isTrue);
          expect(online.users[0].mask, equals('alice!user@host'));
          expect(online.users[1].nick, equals('bob'));
        });

        test('emits to online stream', () async {
          final future = handler.online.first;

          handler.handleMessage(IrcMessage(
            source: 'server',
            command: '730',
            params: ['mynick', 'alice!user@host'],
          ));

          final users = await future;
          expect(users.length, equals(1));
          expect(users[0].nick, equals('alice'));
          expect(users[0].isOnline, isTrue);
        });
      });

      group('RPL_MONOFFLINE (731)', () {
        test('parses offline users', () {
          final message = IrcMessage(
            source: 'server',
            command: '731',
            params: ['mynick', 'alice,bob,charlie'],
          );

          final result = handler.handleMessage(message);

          expect(result, isA<MonitorOffline>());
          final offline = result as MonitorOffline;
          expect(offline.users.length, equals(3));
          expect(offline.users[0].nick, equals('alice'));
          expect(offline.users[0].isOnline, isFalse);
          expect(offline.users[0].mask, isNull);
        });

        test('emits to offline stream', () async {
          final future = handler.offline.first;

          handler.handleMessage(IrcMessage(
            source: 'server',
            command: '731',
            params: ['mynick', 'alice'],
          ));

          final users = await future;
          expect(users.length, equals(1));
          expect(users[0].nick, equals('alice'));
          expect(users[0].isOnline, isFalse);
        });
      });

      group('RPL_MONLIST (732)', () {
        test('parses monitored list entry', () {
          final message = IrcMessage(
            source: 'server',
            command: '732',
            params: ['mynick', 'alice,bob'],
          );

          final result = handler.handleMessage(message);

          expect(result, isA<MonitorList>());
          final list = result as MonitorList;
          expect(list.nicks, equals(['alice', 'bob']));
        });
      });

      group('RPL_ENDOFMONLIST (733)', () {
        test('emits accumulated list', () async {
          final future = handler.monitorList.first;

          // Send multiple list entries
          handler.handleMessage(IrcMessage(
            source: 'server',
            command: '732',
            params: ['mynick', 'alice,bob'],
          ));

          handler.handleMessage(IrcMessage(
            source: 'server',
            command: '732',
            params: ['mynick', 'charlie'],
          ));

          // End of list
          final result = handler.handleMessage(IrcMessage(
            source: 'server',
            command: '733',
            params: ['mynick', 'End of MONITOR list'],
          ));

          expect(result, isA<MonitorListEnd>());

          final list = await future;
          expect(list, equals(['alice', 'bob', 'charlie']));
        });
      });

      group('ERR_MONLISTFULL (734)', () {
        test('parses list full error', () {
          final message = IrcMessage(
            source: 'server',
            command: '734',
            params: ['mynick', '100', 'alice,bob', 'Monitor list is full'],
          );

          final result = handler.handleMessage(message);

          expect(result, isA<MonitorListFull>());
          final error = result as MonitorListFull;
          expect(error.limit, equals(100));
          expect(error.targets, equals(['alice', 'bob']));
        });

        test('emits to error stream', () async {
          final future = handler.listFullErrors.first;

          handler.handleMessage(IrcMessage(
            source: 'server',
            command: '734',
            params: ['mynick', '50', 'alice', 'Monitor list is full'],
          ));

          final error = await future;
          expect(error.limit, equals(50));
          expect(error.targets, equals(['alice']));
        });
      });
    });

    group('isMonitorNumeric', () {
      test('returns true for monitor numerics', () {
        for (final code in [730, 731, 732, 733, 734]) {
          final message = IrcMessage(command: '$code', params: []);
          expect(MonitorHandler.isMonitorNumeric(message), isTrue,
              reason: 'Should be true for $code');
        }
      });

      test('returns false for other numerics', () {
        final message = IrcMessage(command: '001', params: []);
        expect(MonitorHandler.isMonitorNumeric(message), isFalse);
      });

      test('returns false for non-numeric commands', () {
        final message = IrcMessage(command: 'PRIVMSG', params: []);
        expect(MonitorHandler.isMonitorNumeric(message), isFalse);
      });
    });
  });

  group('MonitorStatus', () {
    test('equality', () {
      const status1 = MonitorStatus(
        nick: 'nick',
        isOnline: true,
        mask: 'nick!user@host',
      );

      const status2 = MonitorStatus(
        nick: 'nick',
        isOnline: true,
        mask: 'nick!user@host',
      );

      const status3 = MonitorStatus(
        nick: 'nick',
        isOnline: false,
      );

      expect(status1, equals(status2));
      expect(status1, isNot(equals(status3)));
    });

    test('toString', () {
      const status = MonitorStatus(nick: 'nick', isOnline: true);
      expect(status.toString(), contains('nick'));
      expect(status.toString(), contains('isOnline: true'));
    });
  });

  group('MonitorNumerics', () {
    test('defines correct numeric codes', () {
      expect(MonitorNumerics.mononline, equals(730));
      expect(MonitorNumerics.monoffline, equals(731));
      expect(MonitorNumerics.monlist, equals(732));
      expect(MonitorNumerics.endofmonlist, equals(733));
      expect(MonitorNumerics.monlistfull, equals(734));
    });
  });
}
