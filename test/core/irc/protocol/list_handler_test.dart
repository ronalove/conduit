import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/protocol/list_handler.dart';
import 'package:test/test.dart';

void main() {
  group('ListHandler', () {
    late ListHandler handler;

    setUp(() {
      handler = ListHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('handleMessage', () {
      test('returns null for non-list messages', () {
        final message = IrcMessage(
          source: 'server',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('returns null for 321 (list start)', () {
        handler.startListening();

        final message = IrcMessage(
          source: 'server',
          command: '321',
          params: ['mynick', 'Channel', 'Users Name'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('returns null for 322 (accumulating)', () {
        handler.startListening();

        final message = IrcMessage(
          source: 'server',
          command: '322',
          params: ['mynick', '#test', '5', 'Test channel topic'],
        );

        final result = handler.handleMessage(message);
        expect(result, isNull);
      });

      test('returns ChannelListUpdate for 323 (end of list)', () {
        handler.startListening();

        // Add a channel
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '322',
          params: ['mynick', '#test', '5', 'Test topic'],
        ));

        // End of list
        final result = handler.handleMessage(IrcMessage(
          source: 'server',
          command: '323',
          params: ['mynick', 'End of /LIST'],
        ));

        expect(result, isNotNull);
        expect(result!.count, equals(1));
        expect(result.channels[0].name, equals('#test'));
      });
    });

    group('RPL_LIST (322)', () {
      test('parses channel with topic', () async {
        final updates = <ChannelListUpdate>[];
        handler.onListReceived.listen(updates.add);
        handler.startListening();

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '322',
          params: ['mynick', '#flutter', '42', 'Flutter development'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '323',
          params: ['mynick', 'End of /LIST'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates.length, equals(1));
        expect(updates[0].channels.length, equals(1));

        final channel = updates[0].channels[0];
        expect(channel.name, equals('#flutter'));
        expect(channel.userCount, equals(42));
        expect(channel.topic, equals('Flutter development'));
      });

      test('parses channel without topic', () async {
        final updates = <ChannelListUpdate>[];
        handler.onListReceived.listen(updates.add);
        handler.startListening();

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '322',
          params: ['mynick', '#empty', '3'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '323',
          params: ['mynick', 'End of /LIST'],
        ));

        await Future.delayed(Duration.zero);

        final channel = updates[0].channels[0];
        expect(channel.name, equals('#empty'));
        expect(channel.userCount, equals(3));
        expect(channel.topic, isNull);
      });

      test('parses channel with empty topic', () async {
        final updates = <ChannelListUpdate>[];
        handler.onListReceived.listen(updates.add);
        handler.startListening();

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '322',
          params: ['mynick', '#notopic', '10', ''],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '323',
          params: ['mynick', 'End of /LIST'],
        ));

        await Future.delayed(Duration.zero);

        final channel = updates[0].channels[0];
        expect(channel.topic, isNull);
      });

      test('handles invalid user count', () async {
        final updates = <ChannelListUpdate>[];
        handler.onListReceived.listen(updates.add);
        handler.startListening();

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '322',
          params: ['mynick', '#broken', 'NaN', 'Topic'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '323',
          params: ['mynick', 'End of /LIST'],
        ));

        await Future.delayed(Duration.zero);

        final channel = updates[0].channels[0];
        expect(channel.userCount, equals(0));
      });

      test('accumulates multiple channels', () async {
        final updates = <ChannelListUpdate>[];
        handler.onListReceived.listen(updates.add);
        handler.startListening();

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '322',
          params: ['mynick', '#channel1', '10', 'First'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '322',
          params: ['mynick', '#channel2', '20', 'Second'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '322',
          params: ['mynick', '#channel3', '30', 'Third'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '323',
          params: ['mynick', 'End of /LIST'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates.length, equals(1));
        expect(updates[0].count, equals(3));

        final names = updates[0].channels.map((c) => c.name).toList();
        expect(names, equals(['#channel1', '#channel2', '#channel3']));
      });
    });

    group('auto-start listening', () {
      test('starts listening on first 322 without explicit start', () async {
        final updates = <ChannelListUpdate>[];
        handler.onListReceived.listen(updates.add);

        // Don't call startListening()
        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '322',
          params: ['mynick', '#auto', '5', 'Auto started'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '323',
          params: ['mynick', 'End of /LIST'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates.length, equals(1));
        expect(updates[0].channels[0].name, equals('#auto'));
      });
    });

    group('RPL_LISTEND (323)', () {
      test('returns empty list if no channels received', () async {
        final updates = <ChannelListUpdate>[];
        handler.onListReceived.listen(updates.add);
        handler.startListening();

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '323',
          params: ['mynick', 'End of /LIST'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates.length, equals(1));
        expect(updates[0].isEmpty, isTrue);
      });

      test('clears pending after completion', () {
        handler.startListening();

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '322',
          params: ['mynick', '#test', '5', 'Topic'],
        ));

        expect(handler.isListPending, isTrue);
        expect(handler.pendingCount, equals(1));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '323',
          params: ['mynick', 'End of /LIST'],
        ));

        expect(handler.isListPending, isFalse);
        expect(handler.pendingCount, equals(0));
      });
    });

    group('isListMessage', () {
      test('returns true for 321', () {
        final message = IrcMessage(command: '321', params: []);
        expect(ListHandler.isListMessage(message), isTrue);
      });

      test('returns true for 322', () {
        final message = IrcMessage(command: '322', params: []);
        expect(ListHandler.isListMessage(message), isTrue);
      });

      test('returns true for 323', () {
        final message = IrcMessage(command: '323', params: []);
        expect(ListHandler.isListMessage(message), isTrue);
      });

      test('returns false for other messages', () {
        final message = IrcMessage(command: 'PRIVMSG', params: []);
        expect(ListHandler.isListMessage(message), isFalse);
      });
    });

    group('startListening / stopListening', () {
      test('startListening initializes pending list', () {
        expect(handler.isListPending, isFalse);

        handler.startListening();

        expect(handler.isListPending, isTrue);
        expect(handler.pendingCount, equals(0));
      });

      test('stopListening clears pending data', () {
        handler.startListening();

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '322',
          params: ['mynick', '#test', '5', 'Topic'],
        ));

        expect(handler.pendingCount, equals(1));

        handler.stopListening();

        expect(handler.isListPending, isFalse);
        expect(handler.pendingCount, equals(0));
      });
    });

    group('stream', () {
      test('emits updates via stream', () async {
        final updates = <ChannelListUpdate>[];
        handler.onListReceived.listen(updates.add);
        handler.startListening();

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '322',
          params: ['mynick', '#test', '5', 'Topic'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '323',
          params: ['mynick', 'End of /LIST'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates.length, equals(1));
      });

      test('is broadcast stream (multiple listeners)', () async {
        final updates1 = <ChannelListUpdate>[];
        final updates2 = <ChannelListUpdate>[];

        handler.onListReceived.listen(updates1.add);
        handler.onListReceived.listen(updates2.add);
        handler.startListening();

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '322',
          params: ['mynick', '#test', '5', 'Topic'],
        ));

        handler.handleMessage(IrcMessage(
          source: 'server',
          command: '323',
          params: ['mynick', 'End of /LIST'],
        ));

        await Future.delayed(Duration.zero);

        expect(updates1.length, equals(1));
        expect(updates2.length, equals(1));
      });
    });
  });

  group('ListedChannel', () {
    test('toString() returns expected format', () {
      final channel = ListedChannel(
        name: '#test',
        userCount: 42,
        topic: 'Test topic',
      );

      expect(channel.toString(), equals('ListedChannel(#test, 42 users)'));
    });
  });

  group('ChannelListUpdate', () {
    test('count returns correct value', () {
      final update = ChannelListUpdate(channels: [
        ListedChannel(name: '#a', userCount: 1),
        ListedChannel(name: '#b', userCount: 2),
      ]);

      expect(update.count, equals(2));
    });

    test('isEmpty returns true for empty list', () {
      final update = ChannelListUpdate(channels: []);
      expect(update.isEmpty, isTrue);
      expect(update.isNotEmpty, isFalse);
    });

    test('isNotEmpty returns true for non-empty list', () {
      final update = ChannelListUpdate(channels: [
        ListedChannel(name: '#a', userCount: 1),
      ]);
      expect(update.isEmpty, isFalse);
      expect(update.isNotEmpty, isTrue);
    });

    test('toString() returns expected format', () {
      final update = ChannelListUpdate(channels: [
        ListedChannel(name: '#a', userCount: 1),
        ListedChannel(name: '#b', userCount: 2),
      ]);

      expect(update.toString(), equals('ChannelListUpdate(2 channels)'));
    });
  });
}
