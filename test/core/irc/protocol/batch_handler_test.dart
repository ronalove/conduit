import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/protocol/batch_handler.dart';
import 'package:test/test.dart';

void main() {
  group('BatchHandler', () {
    late BatchHandler handler;

    setUp(() {
      handler = BatchHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('handleMessage', () {
      test('returns false for non-batch messages', () {
        final message = IrcMessage(
          source: 'server',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = handler.handleMessage(message);
        expect(result, isFalse);
      });

      test('returns false for messages not in a batch', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = handler.handleMessage(message);
        expect(result, isFalse);
      });

      group('batch start', () {
        test('handles batch start command', () {
          final message = IrcMessage(
            source: 'server',
            command: 'BATCH',
            params: ['+ref123', 'chathistory', '#channel'],
          );

          final result = handler.handleMessage(message);
          expect(result, isTrue);
          expect(handler.activeBatchCount, equals(1));
          expect(handler.isBatchActive('ref123'), isTrue);
        });

        test('parses batch type and params', () {
          handler.handleMessage(IrcMessage(
            command: 'BATCH',
            params: ['+abc', 'netjoin', 'server.example.com'],
          ));

          final batch = handler.getActiveBatch('abc');
          expect(batch, isNotNull);
          expect(batch!.type, equals('netjoin'));
          expect(batch.params, equals(['server.example.com']));
        });

        test('returns false for invalid batch start', () {
          final result = handler.handleMessage(IrcMessage(
            command: 'BATCH',
            params: ['+ref'], // Missing type
          ));

          expect(result, isFalse);
          expect(handler.activeBatchCount, equals(0));
        });
      });

      group('batch end', () {
        test('handles batch end command', () async {
          // Start batch
          handler.handleMessage(IrcMessage(
            command: 'BATCH',
            params: ['+ref123', 'chathistory'],
          ));

          expect(handler.activeBatchCount, equals(1));

          // End batch
          final future = handler.onBatchCompleted.first;

          final result = handler.handleMessage(IrcMessage(
            command: 'BATCH',
            params: ['-ref123'],
          ));

          expect(result, isTrue);
          expect(handler.activeBatchCount, equals(0));

          final completed = await future;
          expect(completed.reference, equals('ref123'));
          expect(completed.type, equals('chathistory'));
        });

        test('returns false for unknown batch end', () {
          final result = handler.handleMessage(IrcMessage(
            command: 'BATCH',
            params: ['-unknown'],
          ));

          expect(result, isFalse);
        });
      });

      group('batched messages', () {
        test('accumulates messages in batch', () async {
          // Start batch
          handler.handleMessage(IrcMessage(
            command: 'BATCH',
            params: ['+ref', 'chathistory', '#channel'],
          ));

          // Send batched messages
          handler.handleMessage(IrcMessage(
            tags: {'batch': 'ref'},
            source: 'nick!user@host',
            command: 'PRIVMSG',
            params: ['#channel', 'Message 1'],
          ));

          handler.handleMessage(IrcMessage(
            tags: {'batch': 'ref'},
            source: 'nick!user@host',
            command: 'PRIVMSG',
            params: ['#channel', 'Message 2'],
          ));

          // Check messages accumulated
          final batch = handler.getActiveBatch('ref');
          expect(batch!.messages.length, equals(2));

          // End batch
          final future = handler.onBatchCompleted.first;
          handler.handleMessage(IrcMessage(
            command: 'BATCH',
            params: ['-ref'],
          ));

          final completed = await future;
          expect(completed.messages.length, equals(2));
          expect(completed.messages[0].params.last, equals('Message 1'));
          expect(completed.messages[1].params.last, equals('Message 2'));
        });

        test('consumes batched messages', () {
          handler.handleMessage(IrcMessage(
            command: 'BATCH',
            params: ['+ref', 'chathistory'],
          ));

          final result = handler.handleMessage(IrcMessage(
            tags: {'batch': 'ref'},
            command: 'PRIVMSG',
            params: ['#channel', 'Test'],
          ));

          expect(result, isTrue);
        });

        test('does not consume messages with unknown batch ref', () {
          final result = handler.handleMessage(IrcMessage(
            tags: {'batch': 'unknown'},
            command: 'PRIVMSG',
            params: ['#channel', 'Test'],
          ));

          expect(result, isFalse);
        });
      });
    });

    group('nested batches', () {
      test('handles nested batch', () async {
        // Start outer batch
        handler.handleMessage(IrcMessage(
          command: 'BATCH',
          params: ['+outer', 'chathistory'],
        ));

        // Start inner batch (with parent reference)
        handler.handleMessage(IrcMessage(
          tags: {'batch': 'outer'},
          command: 'BATCH',
          params: ['+inner', 'draft/multiline', '#channel'],
        ));

        expect(handler.activeBatchCount, equals(2));

        // Add message to inner batch
        handler.handleMessage(IrcMessage(
          tags: {'batch': 'inner'},
          command: 'PRIVMSG',
          params: ['#channel', 'Line 1'],
        ));

        // End inner batch
        handler.handleMessage(IrcMessage(
          tags: {'batch': 'outer'},
          command: 'BATCH',
          params: ['-inner'],
        ));

        expect(handler.activeBatchCount, equals(1));

        // Inner batch should be added to outer
        final outerBatch = handler.getActiveBatch('outer');
        expect(outerBatch!.nestedBatches.length, equals(1));
        expect(outerBatch.nestedBatches[0].type, equals('draft/multiline'));
        expect(outerBatch.nestedBatches[0].messages.length, equals(1));

        // End outer batch
        final future = handler.onBatchCompleted.first;
        handler.handleMessage(IrcMessage(
          command: 'BATCH',
          params: ['-outer'],
        ));

        final completed = await future;
        expect(completed.nestedBatches.length, equals(1));
        expect(completed.nestedBatches[0].reference, equals('inner'));
      });

      test('tracks parent reference in nested batch', () {
        handler.handleMessage(IrcMessage(
          command: 'BATCH',
          params: ['+outer', 'chathistory'],
        ));

        handler.handleMessage(IrcMessage(
          tags: {'batch': 'outer'},
          command: 'BATCH',
          params: ['+inner', 'multiline'],
        ));

        final innerBatch = handler.getActiveBatch('inner');
        expect(innerBatch!.parentRef, equals('outer'));
      });
    });

    group('multiple concurrent batches', () {
      test('handles multiple batches simultaneously', () async {
        handler.handleMessage(IrcMessage(
          command: 'BATCH',
          params: ['+batch1', 'chathistory', '#channel1'],
        ));

        handler.handleMessage(IrcMessage(
          command: 'BATCH',
          params: ['+batch2', 'chathistory', '#channel2'],
        ));

        expect(handler.activeBatchCount, equals(2));

        // Add messages to different batches
        handler.handleMessage(IrcMessage(
          tags: {'batch': 'batch1'},
          command: 'PRIVMSG',
          params: ['#channel1', 'Msg in batch1'],
        ));

        handler.handleMessage(IrcMessage(
          tags: {'batch': 'batch2'},
          command: 'PRIVMSG',
          params: ['#channel2', 'Msg in batch2'],
        ));

        expect(handler.getActiveBatch('batch1')!.messages.length, equals(1));
        expect(handler.getActiveBatch('batch2')!.messages.length, equals(1));
      });
    });

    group('cancelBatch', () {
      test('cancels active batch', () {
        handler.handleMessage(IrcMessage(
          command: 'BATCH',
          params: ['+ref', 'chathistory'],
        ));

        handler.cancelBatch('ref');

        expect(handler.activeBatchCount, equals(0));
        expect(handler.isBatchActive('ref'), isFalse);
      });

      test('does nothing for unknown batch', () {
        handler.cancelBatch('unknown');
        expect(handler.activeBatchCount, equals(0));
      });
    });

    group('cancelAllBatches', () {
      test('cancels all active batches', () {
        handler.handleMessage(IrcMessage(
          command: 'BATCH',
          params: ['+ref1', 'chathistory'],
        ));

        handler.handleMessage(IrcMessage(
          command: 'BATCH',
          params: ['+ref2', 'netjoin'],
        ));

        expect(handler.activeBatchCount, equals(2));

        handler.cancelAllBatches();

        expect(handler.activeBatchCount, equals(0));
        expect(handler.hasActiveBatches, isFalse);
      });
    });

    group('getBatchType', () {
      test('returns type for active batch', () {
        handler.handleMessage(IrcMessage(
          command: 'BATCH',
          params: ['+ref', 'chathistory'],
        ));

        expect(handler.getBatchType('ref'), equals('chathistory'));
      });

      test('returns null for unknown batch', () {
        expect(handler.getBatchType('unknown'), isNull);
      });
    });

    group('activeBatchReferences', () {
      test('returns all active references', () {
        handler.handleMessage(IrcMessage(
          command: 'BATCH',
          params: ['+ref1', 'chathistory'],
        ));

        handler.handleMessage(IrcMessage(
          command: 'BATCH',
          params: ['+ref2', 'netjoin'],
        ));

        final refs = handler.activeBatchReferences;
        expect(refs, containsAll(['ref1', 'ref2']));
        expect(refs.length, equals(2));
      });
    });

    group('CompletedBatch', () {
      test('preserves source and tags from start message', () async {
        handler.handleMessage(IrcMessage(
          tags: {'label': 'abc', 'time': '2024-01-01T00:00:00Z'},
          source: 'server.example.com',
          command: 'BATCH',
          params: ['+ref', 'chathistory'],
        ));

        final future = handler.onBatchCompleted.first;
        handler.handleMessage(IrcMessage(
          command: 'BATCH',
          params: ['-ref'],
        ));

        final completed = await future;
        expect(completed.source, equals('server.example.com'));
        expect(completed.tags['label'], equals('abc'));
        expect(completed.tags['time'], equals('2024-01-01T00:00:00Z'));
      });

      test('calculates totalMessageCount with nested batches', () async {
        // Start outer
        handler.handleMessage(IrcMessage(
          command: 'BATCH',
          params: ['+outer', 'chathistory'],
        ));

        // Add message to outer
        handler.handleMessage(IrcMessage(
          tags: {'batch': 'outer'},
          command: 'PRIVMSG',
          params: ['#ch', 'msg1'],
        ));

        // Start inner
        handler.handleMessage(IrcMessage(
          tags: {'batch': 'outer'},
          command: 'BATCH',
          params: ['+inner', 'multiline'],
        ));

        // Add messages to inner
        handler.handleMessage(IrcMessage(
          tags: {'batch': 'inner'},
          command: 'PRIVMSG',
          params: ['#ch', 'line1'],
        ));

        handler.handleMessage(IrcMessage(
          tags: {'batch': 'inner'},
          command: 'PRIVMSG',
          params: ['#ch', 'line2'],
        ));

        // End inner
        handler.handleMessage(IrcMessage(
          command: 'BATCH',
          params: ['-inner'],
        ));

        // End outer
        final future = handler.onBatchCompleted.first;
        handler.handleMessage(IrcMessage(
          command: 'BATCH',
          params: ['-outer'],
        ));

        final completed = await future;
        expect(completed.messages.length, equals(1));
        expect(completed.nestedBatches.length, equals(1));
        expect(completed.nestedBatches[0].messages.length, equals(2));
        expect(completed.totalMessageCount, equals(3));
      });

      test('isEmpty and isNotEmpty', () {
        const empty = CompletedBatch(
          reference: 'ref',
          type: 'test',
        );
        expect(empty.isEmpty, isTrue);
        expect(empty.isNotEmpty, isFalse);

        const withMessages = CompletedBatch(
          reference: 'ref',
          type: 'test',
          messages: [
            IrcMessage(command: 'PRIVMSG', params: ['#ch', 'hi']),
          ],
        );
        expect(withMessages.isEmpty, isFalse);
        expect(withMessages.isNotEmpty, isTrue);
      });
    });
  });

  group('ActiveBatch', () {
    test('initializes with startedAt', () {
      final before = DateTime.now();
      final batch = ActiveBatch(reference: 'ref', type: 'test');
      final after = DateTime.now();

      expect(batch.startedAt.isAfter(before) || batch.startedAt == before, isTrue);
      expect(batch.startedAt.isBefore(after) || batch.startedAt == after, isTrue);
    });

    test('accepts custom startedAt', () {
      final time = DateTime(2024, 1, 1);
      final batch = ActiveBatch(
        reference: 'ref',
        type: 'test',
        startedAt: time,
      );

      expect(batch.startedAt, equals(time));
    });
  });
}
