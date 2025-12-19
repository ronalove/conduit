import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/protocol/invite_notify_handler.dart';
import 'package:test/test.dart';

void main() {
  group('InviteNotifyHandler', () {
    late InviteNotifyHandler handler;

    setUp(() {
      handler = InviteNotifyHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('handleMessage', () {
      test('returns null for non-INVITE messages', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('parses INVITE with full source', () {
        final message = IrcMessage(
          source: 'inviter!user@host',
          command: 'INVITE',
          params: ['invitee', '#channel'],
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.inviterNick, equals('inviter'));
        expect(result.inviterUser, equals('user'));
        expect(result.inviterHost, equals('host'));
        expect(result.invitee, equals('invitee'));
        expect(result.channel, equals('#channel'));
      });

      test('returns null for INVITE without source', () {
        final message = IrcMessage(
          command: 'INVITE',
          params: ['invitee', '#channel'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('returns null for INVITE with insufficient params', () {
        final message = IrcMessage(
          source: 'inviter!user@host',
          command: 'INVITE',
          params: ['invitee'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('returns null for INVITE with empty params', () {
        final message = IrcMessage(
          source: 'inviter!user@host',
          command: 'INVITE',
          params: [],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('handles source with only nick', () {
        final message = IrcMessage(
          source: 'inviter',
          command: 'INVITE',
          params: ['invitee', '#channel'],
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.inviterNick, equals('inviter'));
        expect(result.inviterUser, isNull);
        expect(result.inviterHost, isNull);
      });
    });

    group('invitations stream', () {
      test('emits notification when handling INVITE message', () async {
        final future = handler.invitations.first;

        final message = IrcMessage(
          source: 'inviter!user@host',
          command: 'INVITE',
          params: ['invitee', '#channel'],
        );

        handler.handleMessage(message);

        final notification = await future;
        expect(notification.inviterNick, equals('inviter'));
        expect(notification.invitee, equals('invitee'));
        expect(notification.channel, equals('#channel'));
      });

      test('emits multiple invite notifications', () async {
        final notifications = <InviteNotification>[];
        final subscription = handler.invitations.listen(notifications.add);

        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'INVITE',
          params: ['bob', '#channel1'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'charlie!user@host',
          command: 'INVITE',
          params: ['david', '#channel2'],
        ));

        // Allow stream to process
        await Future.delayed(Duration.zero);

        expect(notifications.length, equals(2));
        expect(notifications[0].inviterNick, equals('alice'));
        expect(notifications[0].invitee, equals('bob'));
        expect(notifications[1].inviterNick, equals('charlie'));
        expect(notifications[1].invitee, equals('david'));

        await subscription.cancel();
      });
    });

    group('isInviteMessage', () {
      test('returns true for INVITE command', () {
        final message =
            IrcMessage(command: 'INVITE', params: ['nick', '#channel']);
        expect(InviteNotifyHandler.isInviteMessage(message), isTrue);
      });

      test('returns false for other commands', () {
        final message = IrcMessage(command: 'PRIVMSG', params: []);
        expect(InviteNotifyHandler.isInviteMessage(message), isFalse);
      });
    });
  });

  group('InviteNotification', () {
    test('equality', () {
      final notification1 = InviteNotification(
        inviterNick: 'inviter',
        inviterUser: 'user',
        inviterHost: 'host',
        invitee: 'invitee',
        channel: '#channel',
        timestamp: DateTime(2024),
      );

      final notification2 = InviteNotification(
        inviterNick: 'inviter',
        inviterUser: 'user',
        inviterHost: 'host',
        invitee: 'invitee',
        channel: '#channel',
        timestamp: DateTime(2025), // Different timestamp
      );

      final notification3 = InviteNotification(
        inviterNick: 'inviter',
        inviterUser: 'user',
        inviterHost: 'host',
        invitee: 'different',
        channel: '#channel',
        timestamp: DateTime(2024),
      );

      // Same except timestamp (not compared)
      expect(notification1, equals(notification2));

      // Different invitee
      expect(notification1, isNot(equals(notification3)));
    });

    test('toString', () {
      final notification = InviteNotification(
        inviterNick: 'inviter',
        invitee: 'invitee',
        channel: '#channel',
        timestamp: DateTime.now(),
      );

      expect(notification.toString(), contains('inviter'));
      expect(notification.toString(), contains('invitee'));
      expect(notification.toString(), contains('#channel'));
    });
  });
}
