import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/parser/irc_message_extensions.dart';
import 'package:conduit/core/irc/parser/message_tags.dart';
import 'package:test/test.dart';

void main() {
  group('IrcMessageTagsExtension', () {
    group('serverTime', () {
      test('extracts server timestamp', () {
        final message = IrcMessage(
          tags: {'time': '2024-01-15T10:30:00.000Z'},
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        expect(message.serverTime, isNotNull);
        expect(message.serverTime!.year, equals(2024));
        expect(message.serverTime!.month, equals(1));
        expect(message.serverTime!.day, equals(15));
      });

      test('returns null when no time tag', () {
        final message = IrcMessage(command: 'PRIVMSG', params: ['#channel', 'Hello']);
        expect(message.serverTime, isNull);
      });
    });

    group('msgId', () {
      test('extracts message ID', () {
        final message = IrcMessage(
          tags: {'msgid': 'abc123'},
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        expect(message.msgId, equals('abc123'));
      });

      test('returns null when no msgid tag', () {
        final message = IrcMessage(command: 'PRIVMSG', params: ['#channel', 'Hello']);
        expect(message.msgId, isNull);
      });
    });

    group('senderAccount', () {
      test('extracts account name', () {
        final message = IrcMessage(
          tags: {'account': 'user123'},
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        expect(message.senderAccount, equals('user123'));
      });

      test('returns empty string for logged out sender', () {
        final message = IrcMessage(
          tags: {'account': ''},
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        expect(message.senderAccount, equals(''));
      });
    });

    group('batchRef', () {
      test('extracts batch reference', () {
        final message = IrcMessage(
          tags: {'batch': 'batchid123'},
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        expect(message.batchRef, equals('batchid123'));
      });
    });

    group('responseLabel', () {
      test('extracts label', () {
        final message = IrcMessage(
          tags: {'label': 'req001'},
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        expect(message.responseLabel, equals('req001'));
      });
    });

    group('boolean properties', () {
      test('hasServerTime returns correct value', () {
        final withTime = IrcMessage(
          tags: {'time': '2024-01-15T10:30:00.000Z'},
          command: 'PING',
        );
        final withoutTime = IrcMessage(command: 'PING');

        expect(withTime.hasServerTime, isTrue);
        expect(withoutTime.hasServerTime, isFalse);
      });

      test('hasMsgId returns correct value', () {
        final withMsgId = IrcMessage(tags: {'msgid': 'abc'}, command: 'PING');
        final withoutMsgId = IrcMessage(command: 'PING');

        expect(withMsgId.hasMsgId, isTrue);
        expect(withoutMsgId.hasMsgId, isFalse);
      });

      test('isPartOfBatch returns correct value', () {
        final inBatch = IrcMessage(tags: {'batch': 'ref'}, command: 'PING');
        final notInBatch = IrcMessage(command: 'PING');

        expect(inBatch.isPartOfBatch, isTrue);
        expect(notInBatch.isPartOfBatch, isFalse);
      });

      test('isLabeledResponse returns correct value', () {
        final labeled = IrcMessage(tags: {'label': 'req'}, command: 'PING');
        final unlabeled = IrcMessage(command: 'PING');

        expect(labeled.isLabeledResponse, isTrue);
        expect(unlabeled.isLabeledResponse, isFalse);
      });
    });

    group('reply handling', () {
      test('replyTargetMsgId extracts target', () {
        final reply = IrcMessage(
          tags: {'+draft/reply': 'target123'},
          command: 'PRIVMSG',
          params: ['#channel', 'This is a reply'],
        );

        expect(reply.replyTargetMsgId, equals('target123'));
      });

      test('isReply returns correct value', () {
        final reply = IrcMessage(
          tags: {'+draft/reply': 'target123'},
          command: 'PRIVMSG',
        );
        final notReply = IrcMessage(command: 'PRIVMSG');

        expect(reply.isReply, isTrue);
        expect(notReply.isReply, isFalse);
      });
    });

    group('withTags', () {
      test('creates copy with additional tags', () {
        final original = IrcMessage(
          tags: {'msgid': 'abc'},
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final modified = original.withTags({'time': '2024-01-15T10:30:00.000Z'});

        expect(modified.tags['msgid'], equals('abc'));
        expect(modified.tags['time'], equals('2024-01-15T10:30:00.000Z'));
        expect(modified.source, equals('nick!user@host'));
        expect(modified.command, equals('PRIVMSG'));
        expect(modified.params, equals(['#channel', 'Hello']));

        // Original unchanged
        expect(original.tags.containsKey('time'), isFalse);
      });

      test('overwrites existing tags', () {
        final original = IrcMessage(
          tags: {'msgid': 'old'},
          command: 'PRIVMSG',
        );

        final modified = original.withTags({'msgid': 'new'});

        expect(modified.tags['msgid'], equals('new'));
      });
    });

    group('withLabel', () {
      test('adds label tag', () {
        final message = IrcMessage(command: 'PRIVMSG', params: ['#channel', 'Hello']);
        final labeled = message.withLabel('req001');

        expect(labeled.tags[IrcTags.label], equals('req001'));
        expect(labeled.command, equals('PRIVMSG'));
      });
    });

    group('asReplyTo', () {
      test('adds reply-to tag', () {
        final message = IrcMessage(command: 'PRIVMSG', params: ['#channel', 'Reply text']);
        final reply = message.asReplyTo('target123');

        expect(reply.tags[IrcTags.replyTo], equals('target123'));
        expect(reply.command, equals('PRIVMSG'));
      });
    });
  });
}
