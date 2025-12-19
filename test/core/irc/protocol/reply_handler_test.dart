import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/parser/message_tags.dart';
import 'package:conduit/core/irc/protocol/reply_handler.dart';
import 'package:test/test.dart';

void main() {
  group('ReplyHandler', () {
    late ReplyHandler handler;

    setUp(() {
      handler = ReplyHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('handleMessage', () {
      test('returns null for non-PRIVMSG/NOTICE messages', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'JOIN',
          params: ['#channel'],
          tags: {IrcTags.replyTo: 'parent123', IrcTags.msgid: 'msg456'},
        );

        expect(handler.handleMessage(message), isNull);
      });

      test('returns null for messages without reply tag', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
          tags: {IrcTags.msgid: 'msg123'},
        );

        expect(handler.handleMessage(message), isNull);
      });

      test('returns null for messages without msgid', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
          tags: {IrcTags.replyTo: 'parent123'},
        );

        expect(handler.handleMessage(message), isNull);
      });

      test('returns null for messages without params', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: [],
          tags: {IrcTags.replyTo: 'parent123', IrcTags.msgid: 'msg456'},
        );

        expect(handler.handleMessage(message), isNull);
      });

      test('parses valid reply PRIVMSG', () {
        final message = IrcMessage(
          source: 'alice!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'This is a reply'],
          tags: {IrcTags.replyTo: 'parent123', IrcTags.msgid: 'reply456'},
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.msgId, equals('reply456'));
        expect(result.parentMsgId, equals('parent123'));
        expect(result.target, equals('#channel'));
        expect(result.senderNick, equals('alice'));
        expect(result.text, equals('This is a reply'));
      });

      test('parses valid reply NOTICE', () {
        final message = IrcMessage(
          source: 'alice!user@host',
          command: 'NOTICE',
          params: ['#channel', 'Notice reply'],
          tags: {IrcTags.replyTo: 'parent789', IrcTags.msgid: 'notice321'},
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.msgId, equals('notice321'));
        expect(result.parentMsgId, equals('parent789'));
      });

      test('handles message without source', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Reply'],
          tags: {IrcTags.replyTo: 'parent', IrcTags.msgid: 'reply'},
        );

        final result = handler.handleMessage(message);

        expect(result, isNotNull);
        expect(result!.senderNick, isNull);
      });
    });

    group('replies stream', () {
      test('emits reply info', () async {
        final future = handler.replies.first;

        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Reply'],
          tags: {IrcTags.replyTo: 'parent', IrcTags.msgid: 'reply'},
        ));

        final info = await future;
        expect(info.msgId, equals('reply'));
        expect(info.parentMsgId, equals('parent'));
      });
    });

    group('isReply', () {
      test('returns true for messages with reply tag', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Text'],
          tags: {IrcTags.replyTo: 'parent123'},
        );

        expect(handler.isReply(message), isTrue);
      });

      test('returns false for messages without reply tag', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Text'],
        );

        expect(handler.isReply(message), isFalse);
      });
    });

    group('getParentMsgId', () {
      test('returns parent msgId for replies', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Text'],
          tags: {IrcTags.replyTo: 'parent123'},
        );

        expect(handler.getParentMsgId(message), equals('parent123'));
      });

      test('returns null for non-replies', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Text'],
        );

        expect(handler.getParentMsgId(message), isNull);
      });
    });

    group('getReplies', () {
      test('returns empty list for messages without replies', () {
        expect(handler.getReplies('unknown'), isEmpty);
      });

      test('returns all direct replies to a message', () {
        // Add replies to parent
        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Reply 1'],
          tags: {IrcTags.replyTo: 'parent', IrcTags.msgid: 'reply1'},
        ));

        handler.handleMessage(IrcMessage(
          source: 'bob!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Reply 2'],
          tags: {IrcTags.replyTo: 'parent', IrcTags.msgid: 'reply2'},
        ));

        final replies = handler.getReplies('parent');

        expect(replies.length, equals(2));
        expect(replies.map((r) => r.msgId).toSet(), equals({'reply1', 'reply2'}));
      });
    });

    group('getReplyInfo', () {
      test('returns null for unknown message', () {
        expect(handler.getReplyInfo('unknown'), isNull);
      });

      test('returns reply info for known reply', () {
        handler.handleMessage(IrcMessage(
          source: 'alice!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Reply'],
          tags: {IrcTags.replyTo: 'parent', IrcTags.msgid: 'reply'},
        ));

        final info = handler.getReplyInfo('reply');

        expect(info, isNotNull);
        expect(info!.parentMsgId, equals('parent'));
      });
    });

    group('hasReplies', () {
      test('returns false for messages without replies', () {
        expect(handler.hasReplies('parent'), isFalse);
      });

      test('returns true for messages with replies', () {
        handler.handleMessage(IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Reply'],
          tags: {IrcTags.replyTo: 'parent', IrcTags.msgid: 'reply'},
        ));

        expect(handler.hasReplies('parent'), isTrue);
      });
    });

    group('getReplyCount', () {
      test('returns 0 for messages without replies', () {
        expect(handler.getReplyCount('parent'), equals(0));
      });

      test('returns correct count', () {
        handler.handleMessage(IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Reply 1'],
          tags: {IrcTags.replyTo: 'parent', IrcTags.msgid: 'reply1'},
        ));

        handler.handleMessage(IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Reply 2'],
          tags: {IrcTags.replyTo: 'parent', IrcTags.msgid: 'reply2'},
        ));

        handler.handleMessage(IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Reply 3'],
          tags: {IrcTags.replyTo: 'parent', IrcTags.msgid: 'reply3'},
        ));

        expect(handler.getReplyCount('parent'), equals(3));
      });
    });

    group('getReplyChain', () {
      test('returns single element for non-reply', () {
        final chain = handler.getReplyChain('root');
        expect(chain, equals(['root']));
      });

      test('builds chain from reply to root', () {
        // Create a chain: root -> reply1 -> reply2 -> reply3
        handler.handleMessage(IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'R1'],
          tags: {IrcTags.replyTo: 'root', IrcTags.msgid: 'reply1'},
        ));

        handler.handleMessage(IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'R2'],
          tags: {IrcTags.replyTo: 'reply1', IrcTags.msgid: 'reply2'},
        ));

        handler.handleMessage(IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'R3'],
          tags: {IrcTags.replyTo: 'reply2', IrcTags.msgid: 'reply3'},
        ));

        final chain = handler.getReplyChain('reply3');
        expect(chain, equals(['root', 'reply1', 'reply2', 'reply3']));
      });
    });

    group('getReplyDepth', () {
      test('returns 0 for non-reply', () {
        expect(handler.getReplyDepth('root'), equals(0));
      });

      test('returns correct depth', () {
        handler.handleMessage(IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'R1'],
          tags: {IrcTags.replyTo: 'root', IrcTags.msgid: 'reply1'},
        ));

        handler.handleMessage(IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'R2'],
          tags: {IrcTags.replyTo: 'reply1', IrcTags.msgid: 'reply2'},
        ));

        expect(handler.getReplyDepth('reply1'), equals(1));
        expect(handler.getReplyDepth('reply2'), equals(2));
      });
    });

    group('clear', () {
      test('removes all cached replies', () {
        handler.handleMessage(IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Reply'],
          tags: {IrcTags.replyTo: 'parent', IrcTags.msgid: 'reply'},
        ));

        expect(handler.hasReplies('parent'), isTrue);

        handler.clear();

        expect(handler.hasReplies('parent'), isFalse);
        expect(handler.getReplyInfo('reply'), isNull);
      });
    });

    group('clearTarget', () {
      test('removes replies for specific target', () {
        handler.handleMessage(IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel1', 'Reply'],
          tags: {IrcTags.replyTo: 'parent1', IrcTags.msgid: 'reply1'},
        ));

        handler.handleMessage(IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel2', 'Reply'],
          tags: {IrcTags.replyTo: 'parent2', IrcTags.msgid: 'reply2'},
        ));

        handler.clearTarget('#channel1');

        expect(handler.getReplyInfo('reply1'), isNull);
        expect(handler.getReplyInfo('reply2'), isNotNull);
      });
    });

    group('cache eviction', () {
      test('evicts oldest entries when cache is full', () {
        final smallHandler = ReplyHandler(maxCacheSize: 3);

        // Add 4 replies to a handler with max size 3
        for (var i = 1; i <= 4; i++) {
          smallHandler.handleMessage(IrcMessage(
            command: 'PRIVMSG',
            params: ['#channel', 'Reply $i'],
            tags: {IrcTags.replyTo: 'parent$i', IrcTags.msgid: 'reply$i'},
          ));
        }

        // First reply should be evicted
        expect(smallHandler.getReplyInfo('reply1'), isNull);

        // Others should exist
        expect(smallHandler.getReplyInfo('reply2'), isNotNull);
        expect(smallHandler.getReplyInfo('reply3'), isNotNull);
        expect(smallHandler.getReplyInfo('reply4'), isNotNull);

        smallHandler.dispose();
      });
    });
  });

  group('ReplyInfo', () {
    test('toString returns readable string', () {
      final info = ReplyInfo(
        msgId: 'reply123',
        parentMsgId: 'parent456',
        target: '#channel',
        receivedAt: DateTime.now(),
      );

      final str = info.toString();
      expect(str, contains('reply123'));
      expect(str, contains('parent456'));
      expect(str, contains('#channel'));
    });
  });
}
