import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/protocol/names_handler.dart';
import 'package:conduit/features/users/models/channel_user.dart';
import 'package:test/test.dart';

void main() {
  group('NamesHandler', () {
    late NamesHandler handler;

    setUp(() {
      handler = NamesHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('handleMessage', () {
      test('returns null for non-names messages', () {
        final message = IrcMessage(
          source: 'server',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('returns null for 353 (accumulating)', () {
        final message = IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test', '@op +voice regular'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('returns NamesUpdate for 366 (end of names)', () {
        // Send 353 first
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test', '@op +voice regular'],
        ));

        // Then 366
        final result = handler.handleMessage(IrcMessage(
          source: 'server',
          command: '366',
          params: ['mynick', '#test', 'End of /NAMES list.'],
        ));

        expect(result, isNotNull);
        expect(result!.channel, equals('#test'));
        expect(result.users.length, equals(3));
      });
    });

    group('RPL_NAMREPLY (353)', () {
      test('parses single user', () async {
        final updates = <NamesUpdate>[];
        handler.onNamesReceived.listen(updates.add);

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test', 'user1'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '366',
          params: ['mynick', '#test', 'End of /NAMES list.'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates.length, equals(1));
        expect(updates[0].users.length, equals(1));
        expect(updates[0].users[0].nickname, equals('user1'));
        expect(updates[0].users[0].mode, equals(UserMode.regular));
      });

      test('parses operator prefix @', () async {
        final updates = <NamesUpdate>[];
        handler.onNamesReceived.listen(updates.add);

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test', '@operator'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '366',
          params: ['mynick', '#test', 'End of /NAMES list.'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates[0].users[0].nickname, equals('operator'));
        expect(updates[0].users[0].mode, equals(UserMode.operator));
      });

      test('parses halfop prefix %', () async {
        final updates = <NamesUpdate>[];
        handler.onNamesReceived.listen(updates.add);

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test', '%halfop'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '366',
          params: ['mynick', '#test', 'End of /NAMES list.'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates[0].users[0].nickname, equals('halfop'));
        expect(updates[0].users[0].mode, equals(UserMode.halfOp));
      });

      test('parses voice prefix +', () async {
        final updates = <NamesUpdate>[];
        handler.onNamesReceived.listen(updates.add);

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test', '+voiced'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '366',
          params: ['mynick', '#test', 'End of /NAMES list.'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates[0].users[0].nickname, equals('voiced'));
        expect(updates[0].users[0].mode, equals(UserMode.voice));
      });

      test('parses multi-prefix @+', () async {
        final updates = <NamesUpdate>[];
        handler.onNamesReceived.listen(updates.add);

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test', '@+opvoice'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '366',
          params: ['mynick', '#test', 'End of /NAMES list.'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates[0].users[0].nickname, equals('opvoice'));
        // Should get highest mode (operator)
        expect(updates[0].users[0].mode, equals(UserMode.operator));
      });

      test('parses multiple users', () async {
        final updates = <NamesUpdate>[];
        handler.onNamesReceived.listen(updates.add);

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test', '@op +voice regular'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '366',
          params: ['mynick', '#test', 'End of /NAMES list.'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates[0].users.length, equals(3));

        final byNick = {for (final u in updates[0].users) u.nickname: u};
        expect(byNick['op']!.mode, equals(UserMode.operator));
        expect(byNick['voice']!.mode, equals(UserMode.voice));
        expect(byNick['regular']!.mode, equals(UserMode.regular));
      });

      test('accumulates multiple 353 responses', () async {
        final updates = <NamesUpdate>[];
        handler.onNamesReceived.listen(updates.add);

        // First 353
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test', '@op1 @op2'],
        ));

        // Second 353
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test', '+voice1 +voice2'],
        ));

        // Third 353
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test', 'regular1 regular2'],
        ));

        // End of names
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '366',
          params: ['mynick', '#test', 'End of /NAMES list.'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates.length, equals(1));
        expect(updates[0].users.length, equals(6));
      });
    });

    group('channel handling', () {
      test('handles channel names case-insensitively', () async {
        final updates = <NamesUpdate>[];
        handler.onNamesReceived.listen(updates.add);

        // Send with uppercase channel
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#TEST', '@user'],
        ));

        // End with lowercase channel
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '366',
          params: ['mynick', '#test', 'End of /NAMES list.'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates.length, equals(1));
        expect(updates[0].users.length, equals(1));
      });

      test('tracks multiple channels independently', () async {
        final updates = <NamesUpdate>[];
        handler.onNamesReceived.listen(updates.add);

        // Channel 1 start
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#channel1', '@op1'],
        ));

        // Channel 2 start
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#channel2', '@op2 @op3'],
        ));

        // Channel 1 end
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '366',
          params: ['mynick', '#channel1', 'End of /NAMES list.'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates.length, equals(1));
        expect(updates[0].channel, equals('#channel1'));
        expect(updates[0].users.length, equals(1));

        // Channel 2 still pending
        expect(handler.pendingChannels, contains('#channel2'));
      });
    });

    group('RPL_ENDOFNAMES (366)', () {
      test('returns empty list for unknown channel', () async {
        final updates = <NamesUpdate>[];
        handler.onNamesReceived.listen(updates.add);

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '366',
          params: ['mynick', '#unknown', 'End of /NAMES list.'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates.length, equals(1));
        expect(updates[0].channel, equals('#unknown'));
        expect(updates[0].users, isEmpty);
      });

      test('clears pending after completion', () {
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test', '@user'],
        ));

        expect(handler.pendingChannels, contains('#test'));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '366',
          params: ['mynick', '#test', 'End of /NAMES list.'],
        ));

        expect(handler.pendingChannels, isEmpty);
      });
    });

    group('isNamesMessage', () {
      test('returns true for 353', () {
        final message = IrcMessage(command: '353', params: []);
        expect(NamesHandler.isNamesMessage(message), isTrue);
      });

      test('returns true for 366', () {
        final message = IrcMessage(command: '366', params: []);
        expect(NamesHandler.isNamesMessage(message), isTrue);
      });

      test('returns false for other messages', () {
        final message = IrcMessage(command: 'PRIVMSG', params: []);
        expect(NamesHandler.isNamesMessage(message), isFalse);
      });
    });

    group('cancelPending', () {
      test('cancels pending names for a channel', () {
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test', '@user'],
        ));

        expect(handler.pendingChannels, contains('#test'));

        handler.cancelPending('#test');

        expect(handler.pendingChannels, isEmpty);
      });
    });

    group('cancelAllPending', () {
      test('cancels all pending names', () {
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test1', '@user1'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test2', '@user2'],
        ));

        expect(handler.pendingChannels.length, equals(2));

        handler.cancelAllPending();

        expect(handler.pendingChannels, isEmpty);
      });
    });

    group('stream', () {
      test('emits updates via stream', () async {
        final updates = <NamesUpdate>[];
        handler.onNamesReceived.listen(updates.add);

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test', '@user'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '366',
          params: ['mynick', '#test', 'End of /NAMES list.'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates.length, equals(1));
        expect(updates[0].channel, equals('#test'));
      });

      test('is broadcast stream (multiple listeners)', () async {
        final updates1 = <NamesUpdate>[];
        final updates2 = <NamesUpdate>[];

        handler.onNamesReceived.listen(updates1.add);
        handler.onNamesReceived.listen(updates2.add);

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '353',
          params: ['mynick', '=', '#test', '@user'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '366',
          params: ['mynick', '#test', 'End of /NAMES list.'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates1.length, equals(1));
        expect(updates2.length, equals(1));
      });
    });
  });
}
