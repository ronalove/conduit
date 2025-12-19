import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/protocol/read_marker_handler.dart';
import 'package:test/test.dart';

void main() {
  group('ReadMarkerHandler', () {
    late ReadMarkerHandler handler;

    setUp(() {
      handler = ReadMarkerHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('handleMessage', () {
      test('returns null for non-MARKREAD messages', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        expect(handler.handleMessage(message), isNull);
      });

      test('returns null for empty MARKREAD', () {
        final message = IrcMessage(
          command: 'MARKREAD',
          params: [],
        );

        expect(handler.handleMessage(message), isNull);
      });

      test('handles MARKREAD with target only', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'MARKREAD',
          params: ['#channel'],
        );

        final update = handler.handleMessage(message);

        expect(update, isNotNull);
        expect(update!.target, equals('#channel'));
        expect(update.timestamp, isNull);
        expect(update.source, equals('nick!user@host'));
      });

      test('handles MARKREAD with timestamp', () {
        final message = IrcMessage(
          source: 'nick!user@host',
          command: 'MARKREAD',
          params: ['#channel', 'timestamp=2024-01-15T12:30:00Z'],
        );

        final update = handler.handleMessage(message);

        expect(update, isNotNull);
        expect(update!.target, equals('#channel'));
        expect(update.timestamp, isNotNull);
        expect(update.timestamp!.year, equals(2024));
        expect(update.timestamp!.month, equals(1));
        expect(update.timestamp!.day, equals(15));
      });

      test('stores read position', () {
        handler.handleMessage(IrcMessage(
          command: 'MARKREAD',
          params: ['#channel', 'timestamp=2024-01-15T12:30:00Z'],
        ));

        final stored = handler.getReadPosition('#channel');
        expect(stored, isNotNull);
        expect(stored!.year, equals(2024));
      });

      test('stores with case-insensitive target', () {
        handler.handleMessage(IrcMessage(
          command: 'MARKREAD',
          params: ['#Channel', 'timestamp=2024-01-15T12:30:00Z'],
        ));

        expect(handler.getReadPosition('#CHANNEL'), isNotNull);
        expect(handler.getReadPosition('#channel'), isNotNull);
      });

      test('only updates if newer timestamp', () {
        // Set initial position
        handler.handleMessage(IrcMessage(
          command: 'MARKREAD',
          params: ['#channel', 'timestamp=2024-01-15T12:00:00Z'],
        ));

        // Try to set older position
        handler.handleMessage(IrcMessage(
          command: 'MARKREAD',
          params: ['#channel', 'timestamp=2024-01-15T10:00:00Z'],
        ));

        final stored = handler.getReadPosition('#channel');
        expect(stored!.hour, equals(12)); // Still the newer one
      });

      test('emits to stream', () async {
        final future = handler.onUpdate.first;

        handler.handleMessage(IrcMessage(
          source: 'nick!user@host',
          command: 'MARKREAD',
          params: ['#channel', 'timestamp=2024-01-15T12:30:00Z'],
        ));

        final update = await future;
        expect(update.target, equals('#channel'));
      });

      test('detects own updates', () {
        handler.currentNick = 'mynick';

        final update = handler.handleMessage(IrcMessage(
          source: 'mynick!user@host',
          command: 'MARKREAD',
          params: ['#channel', 'timestamp=2024-01-15T12:30:00Z'],
        ));

        expect(update!.isOwnUpdate, isTrue);
      });

      test('detects other user updates', () {
        handler.currentNick = 'mynick';

        final update = handler.handleMessage(IrcMessage(
          source: 'othernick!user@host',
          command: 'MARKREAD',
          params: ['#channel', 'timestamp=2024-01-15T12:30:00Z'],
        ));

        expect(update!.isOwnUpdate, isFalse);
      });

      test('handles case-insensitive nick comparison', () {
        handler.currentNick = 'MyNick';

        final update = handler.handleMessage(IrcMessage(
          source: 'MYNICK!user@host',
          command: 'MARKREAD',
          params: ['#channel'],
        ));

        expect(update!.isOwnUpdate, isTrue);
      });
    });

    group('setReadPosition', () {
      test('sets read position', () {
        final timestamp = DateTime.utc(2024, 1, 15);
        handler.setReadPosition('#channel', timestamp);

        expect(handler.getReadPosition('#channel'), equals(timestamp));
      });

      test('only updates if newer', () {
        handler.setReadPosition('#channel', DateTime.utc(2024, 1, 15));
        handler.setReadPosition('#channel', DateTime.utc(2024, 1, 10)); // Older

        final stored = handler.getReadPosition('#channel');
        expect(stored!.day, equals(15));
      });
    });

    group('isUnread', () {
      test('returns null if no stored position', () {
        final result = handler.isUnread('#channel', DateTime.utc(2024, 1, 15));
        expect(result, isNull);
      });

      test('returns true if message is after read position', () {
        handler.setReadPosition('#channel', DateTime.utc(2024, 1, 15, 12, 0));

        final result = handler.isUnread(
          '#channel',
          DateTime.utc(2024, 1, 15, 13, 0),
        );
        expect(result, isTrue);
      });

      test('returns false if message is before read position', () {
        handler.setReadPosition('#channel', DateTime.utc(2024, 1, 15, 12, 0));

        final result = handler.isUnread(
          '#channel',
          DateTime.utc(2024, 1, 15, 11, 0),
        );
        expect(result, isFalse);
      });

      test('returns false if message equals read position', () {
        final time = DateTime.utc(2024, 1, 15, 12, 0);
        handler.setReadPosition('#channel', time);

        final result = handler.isUnread('#channel', time);
        expect(result, isFalse);
      });
    });

    group('clearReadPosition', () {
      test('clears position for target', () {
        handler.setReadPosition('#channel', DateTime.utc(2024, 1, 15));
        handler.clearReadPosition('#channel');

        expect(handler.getReadPosition('#channel'), isNull);
      });

      test('is case-insensitive', () {
        handler.setReadPosition('#Channel', DateTime.utc(2024, 1, 15));
        handler.clearReadPosition('#CHANNEL');

        expect(handler.getReadPosition('#channel'), isNull);
      });
    });

    group('clearAllReadPositions', () {
      test('clears all positions', () {
        handler.setReadPosition('#channel1', DateTime.utc(2024, 1, 15));
        handler.setReadPosition('#channel2', DateTime.utc(2024, 1, 15));
        handler.clearAllReadPositions();

        expect(handler.readPositions, isEmpty);
      });
    });

    group('readPositions', () {
      test('returns unmodifiable map', () {
        handler.setReadPosition('#channel', DateTime.utc(2024, 1, 15));

        final positions = handler.readPositions;
        expect(() => positions['#test'] = DateTime.now(), throwsUnsupportedError);
      });
    });

    test('capabilityName is correct', () {
      expect(ReadMarkerHandler.capabilityName, equals('draft/read-marker'));
    });
  });

  group('ReadMarkerUpdate', () {
    test('creates with all fields', () {
      final time = DateTime.utc(2024, 1, 15);
      const update = ReadMarkerUpdate(
        target: '#channel',
        timestamp: null,
        source: 'nick!user@host',
        isOwnUpdate: true,
      );

      expect(update.target, equals('#channel'));
      expect(update.source, equals('nick!user@host'));
      expect(update.isOwnUpdate, isTrue);
    });

    test('toString includes target', () {
      const update = ReadMarkerUpdate(target: '#channel');
      expect(update.toString(), contains('#channel'));
    });
  });
}
