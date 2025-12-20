import 'package:conduit/core/irc/protocol/topic_handler.dart';
import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:test/test.dart';

void main() {
  group('TopicHandler', () {
    late TopicHandler handler;

    setUp(() {
      handler = TopicHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('handleMessage', () {
      test('returns null for non-topic messages', () {
        final message = IrcMessage(
          source: 'server',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });
    });

    group('RPL_NOTOPIC (331)', () {
      test('emits null topic', () async {
        final updates = <TopicUpdate>[];
        handler.onTopicReceived.listen(updates.add);

        final result = handler.handleMessage(IrcMessage(
          source: 'server',
          command: '331',
          params: ['mynick', '#test', 'No topic is set.'],
        ));

        await Future.delayed(Duration.zero);

        expect(result, isNotNull);
        expect(result!.channel, equals('#test'));
        expect(result.topic, isNull);
        expect(result.hasTopic, isFalse);

        expect(updates.length, equals(1));
      });
    });

    group('RPL_TOPIC (332)', () {
      test('stores topic and waits for 333', () {
        final result = handler.handleMessage(IrcMessage(
          source: 'server',
          command: '332',
          params: ['mynick', '#test', 'Welcome to #test!'],
        ));

        // Should return null (waiting for 333)
        expect(result, isNull);
        expect(handler.pendingChannels, contains('#test'));
      });
    });

    group('RPL_TOPICWHOTIME (333)', () {
      test('completes topic with setter and time', () async {
        final updates = <TopicUpdate>[];
        handler.onTopicReceived.listen(updates.add);

        // First 332
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '332',
          params: ['mynick', '#test', 'Welcome to #test!'],
        ));

        // Then 333
        final timestamp = DateTime(2024, 1, 15, 12, 0).millisecondsSinceEpoch ~/ 1000;
        final result = handler.handleMessage(IrcMessage(
          source: 'server',
          command: '333',
          params: ['mynick', '#test', 'admin', timestamp.toString()],
        ));

        await Future.delayed(Duration.zero);

        expect(result, isNotNull);
        expect(result!.channel, equals('#test'));
        expect(result.topic, isNotNull);
        expect(result.topic!.text, equals('Welcome to #test!'));
        expect(result.topic!.setBy, equals('admin'));
        expect(result.topic!.setAt, isNotNull);

        expect(updates.length, equals(1));
        expect(handler.pendingChannels, isEmpty);
      });

      test('returns null without pending topic', () {
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final result = handler.handleMessage(IrcMessage(
          source: 'server',
          command: '333',
          params: ['mynick', '#test', 'admin', timestamp.toString()],
        ));

        expect(result, isNull);
      });
    });

    group('TOPIC command', () {
      test('handles new topic', () async {
        final updates = <TopicUpdate>[];
        handler.onTopicReceived.listen(updates.add);

        final result = handler.handleMessage(IrcMessage(
          source: 'admin!user@host',
          command: 'TOPIC',
          params: ['#test', 'New topic set by admin'],
        ));

        await Future.delayed(Duration.zero);

        expect(result, isNotNull);
        expect(result!.channel, equals('#test'));
        expect(result.topic, isNotNull);
        expect(result.topic!.text, equals('New topic set by admin'));
        expect(result.topic!.setBy, equals('admin'));
        expect(result.topic!.setAt, isNotNull);

        expect(updates.length, equals(1));
      });

      test('handles topic clear (empty)', () async {
        final updates = <TopicUpdate>[];
        handler.onTopicReceived.listen(updates.add);

        final result = handler.handleMessage(IrcMessage(
          source: 'admin!user@host',
          command: 'TOPIC',
          params: ['#test', ''],
        ));

        await Future.delayed(Duration.zero);

        expect(result, isNotNull);
        expect(result!.channel, equals('#test'));
        expect(result.topic, isNull);
        expect(result.hasTopic, isFalse);
      });

      test('handles topic clear (no trailing param)', () async {
        final updates = <TopicUpdate>[];
        handler.onTopicReceived.listen(updates.add);

        final result = handler.handleMessage(IrcMessage(
          source: 'admin!user@host',
          command: 'TOPIC',
          params: ['#test'],
        ));

        await Future.delayed(Duration.zero);

        expect(result, isNotNull);
        expect(result!.topic, isNull);
      });
    });

    group('flushPendingTopic', () {
      test('emits pending topic without 333', () async {
        final updates = <TopicUpdate>[];
        handler.onTopicReceived.listen(updates.add);

        // Send 332 only
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '332',
          params: ['mynick', '#test', 'Welcome!'],
        ));

        expect(handler.pendingChannels, contains('#test'));

        // Flush it
        final result = handler.flushPendingTopic('#test');

        await Future.delayed(Duration.zero);

        expect(result, isNotNull);
        expect(result!.topic!.text, equals('Welcome!'));
        expect(result.topic!.setBy, isNull);
        expect(result.topic!.setAt, isNull);

        expect(handler.pendingChannels, isEmpty);
        expect(updates.length, equals(1));
      });

      test('returns null for non-pending channel', () {
        final result = handler.flushPendingTopic('#nonexistent');
        expect(result, isNull);
      });

      test('is case insensitive', () {
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '332',
          params: ['mynick', '#TEST', 'Welcome!'],
        ));

        final result = handler.flushPendingTopic('#test');
        expect(result, isNotNull);
      });
    });

    group('channel handling', () {
      test('normalizes channel names to lowercase', () async {
        final updates = <TopicUpdate>[];
        handler.onTopicReceived.listen(updates.add);

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '331',
          params: ['mynick', '#TEST', 'No topic is set.'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates[0].channel, equals('#test'));
      });
    });

    group('isTopicMessage', () {
      test('returns true for 331', () {
        final message = IrcMessage(command: '331', params: []);
        expect(TopicHandler.isTopicMessage(message), isTrue);
      });

      test('returns true for 332', () {
        final message = IrcMessage(command: '332', params: []);
        expect(TopicHandler.isTopicMessage(message), isTrue);
      });

      test('returns true for 333', () {
        final message = IrcMessage(command: '333', params: []);
        expect(TopicHandler.isTopicMessage(message), isTrue);
      });

      test('returns true for TOPIC', () {
        final message = IrcMessage(command: 'TOPIC', params: []);
        expect(TopicHandler.isTopicMessage(message), isTrue);
      });

      test('returns false for other messages', () {
        final message = IrcMessage(command: 'PRIVMSG', params: []);
        expect(TopicHandler.isTopicMessage(message), isFalse);
      });
    });

    group('cancelPending', () {
      test('cancels pending topic for a channel', () {
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '332',
          params: ['mynick', '#test', 'Topic'],
        ));

        expect(handler.pendingChannels, contains('#test'));

        handler.cancelPending('#test');

        expect(handler.pendingChannels, isEmpty);
      });
    });

    group('cancelAllPending', () {
      test('cancels all pending topics', () {
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '332',
          params: ['mynick', '#test1', 'Topic 1'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '332',
          params: ['mynick', '#test2', 'Topic 2'],
        ));

        expect(handler.pendingChannels.length, equals(2));

        handler.cancelAllPending();

        expect(handler.pendingChannels, isEmpty);
      });
    });

    group('stream', () {
      test('is broadcast stream (multiple listeners)', () async {
        final updates1 = <TopicUpdate>[];
        final updates2 = <TopicUpdate>[];

        handler.onTopicReceived.listen(updates1.add);
        handler.onTopicReceived.listen(updates2.add);

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '331',
          params: ['mynick', '#test', 'No topic is set.'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates1.length, equals(1));
        expect(updates2.length, equals(1));
      });
    });
  });
}
