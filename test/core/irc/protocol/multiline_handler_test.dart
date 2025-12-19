import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/protocol/batch_handler.dart';
import 'package:conduit/core/irc/protocol/multiline_handler.dart';
import 'package:test/test.dart';

void main() {
  group('MultilineHandler', () {
    late MultilineHandler handler;

    setUp(() {
      handler = MultilineHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('processBatch', () {
      test('returns null for non-multiline batch', () {
        const batch = CompletedBatch(
          reference: 'ref',
          type: 'chathistory',
        );

        final result = handler.processBatch(batch);
        expect(result, isNull);
      });

      test('processes multiline batch', () {
        final batch = CompletedBatch(
          reference: 'ref123',
          type: 'draft/multiline',
          params: ['#channel'],
          messages: [
            IrcMessage(
              tags: {'time': '2024-01-01T00:00:00Z', 'msgid': 'msg1'},
              source: 'nick!user@host',
              command: 'PRIVMSG',
              params: ['#channel', 'Line 1'],
            ),
            IrcMessage(
              tags: {'time': '2024-01-01T00:00:00Z'},
              source: 'nick!user@host',
              command: 'PRIVMSG',
              params: ['#channel', 'Line 2'],
            ),
            IrcMessage(
              tags: {'time': '2024-01-01T00:00:00Z'},
              source: 'nick!user@host',
              command: 'PRIVMSG',
              params: ['#channel', 'Line 3'],
            ),
          ],
        );

        final result = handler.processBatch(batch);

        expect(result, isNotNull);
        expect(result!.target, equals('#channel'));
        expect(result.lineCount, equals(3));
        expect(result.lines, equals(['Line 1', 'Line 2', 'Line 3']));
        expect(result.text, equals('Line 1\nLine 2\nLine 3'));
        expect(result.source, equals('nick!user@host'));
        expect(result.msgId, equals('msg1'));
        expect(result.batchRef, equals('ref123'));
        expect(result.isMultiline, isTrue);
      });

      test('returns null for empty batch', () {
        final batch = CompletedBatch(
          reference: 'ref',
          type: 'draft/multiline',
          params: ['#channel'],
          messages: [],
        );

        final result = handler.processBatch(batch);
        expect(result, isNull);
      });

      test('emits to stream', () async {
        final future = handler.onMessage.first;

        handler.processBatch(CompletedBatch(
          reference: 'ref',
          type: 'draft/multiline',
          params: ['#channel'],
          messages: [
            IrcMessage(
              source: 'nick!user@host',
              command: 'PRIVMSG',
              params: ['#channel', 'Test'],
            ),
          ],
        ));

        final message = await future;
        expect(message.lines, equals(['Test']));
      });

      test('extracts account from first message', () {
        final batch = CompletedBatch(
          reference: 'ref',
          type: 'draft/multiline',
          params: ['#channel'],
          messages: [
            IrcMessage(
              tags: {'account': 'myaccount'},
              source: 'nick!user@host',
              command: 'PRIVMSG',
              params: ['#channel', 'Line'],
            ),
          ],
        );

        final result = handler.processBatch(batch);
        expect(result!.account, equals('myaccount'));
      });
    });

    group('buildFromText', () {
      test('creates batch messages from text', () {
        final messages = handler.buildFromText('#channel', 'Line 1\nLine 2\nLine 3');

        expect(messages.length, equals(5)); // start + 3 lines + end

        // Check batch start
        expect(messages[0].command, equals('BATCH'));
        expect(messages[0].params[0], startsWith('+'));
        expect(messages[0].params[1], equals('draft/multiline'));
        expect(messages[0].params[2], equals('#channel'));

        // Check lines
        expect(messages[1].command, equals('PRIVMSG'));
        expect(messages[1].params[0], equals('#channel'));
        expect(messages[1].params[1], equals('Line 1'));
        expect(messages[1].tags['batch'], isNotNull);

        expect(messages[2].params[1], equals('Line 2'));
        expect(messages[3].params[1], equals('Line 3'));

        // Check batch end
        expect(messages[4].command, equals('BATCH'));
        expect(messages[4].params[0], startsWith('-'));
      });

      test('returns empty for empty text', () {
        final messages = handler.buildFromText('#channel', '');
        expect(messages, isEmpty);
      });

      test('handles single line', () {
        final messages = handler.buildFromText('#channel', 'Single line');

        expect(messages.length, equals(3)); // start + 1 line + end
        expect(messages[1].params[1], equals('Single line'));
      });
    });

    group('createBuilder', () {
      test('creates builder for target', () {
        final builder = handler.createBuilder('#channel');
        expect(builder.target, equals('#channel'));
        expect(builder.hasLines, isFalse);
      });
    });

    group('isMultilineBatch', () {
      test('returns true for multiline batch', () {
        const batch = CompletedBatch(
          reference: 'ref',
          type: 'draft/multiline',
        );

        expect(MultilineHandler.isMultilineBatch(batch), isTrue);
      });

      test('returns false for other batch types', () {
        const batch = CompletedBatch(
          reference: 'ref',
          type: 'chathistory',
        );

        expect(MultilineHandler.isMultilineBatch(batch), isFalse);
      });
    });

    test('capabilityName is correct', () {
      expect(MultilineHandler.capabilityName, equals('draft/multiline'));
    });
  });

  group('MultilineMessageBuilder', () {
    test('addLine adds single line', () {
      final builder = MultilineMessageBuilder('#channel');
      builder.addLine('First');
      builder.addLine('Second');

      expect(builder.lineCount, equals(2));
      expect(builder.hasLines, isTrue);
    });

    test('addLines adds multiple lines', () {
      final builder = MultilineMessageBuilder('#channel');
      builder.addLines(['One', 'Two', 'Three']);

      expect(builder.lineCount, equals(3));
    });

    test('setText replaces existing lines', () {
      final builder = MultilineMessageBuilder('#channel');
      builder.addLine('Old line');
      builder.setText('New\nLines');

      expect(builder.lineCount, equals(2));
    });

    test('build creates correct messages', () {
      final builder = MultilineMessageBuilder('#test');
      builder.addLine('Hello');
      builder.addLine('World');

      final messages = builder.build();

      expect(messages.length, equals(4)); // start + 2 lines + end

      // All line messages should have the same batch ref
      final batchRef = messages[0].params[0].substring(1);
      expect(messages[1].tags['batch'], equals(batchRef));
      expect(messages[2].tags['batch'], equals(batchRef));
      expect(messages[3].params[0], equals('-$batchRef'));
    });

    test('build returns empty for no lines', () {
      final builder = MultilineMessageBuilder('#channel');
      expect(builder.build(), isEmpty);
    });
  });

  group('MultilineMessage', () {
    test('isMultiline with multiple lines', () {
      const message = MultilineMessage(
        target: '#channel',
        lines: ['Line 1', 'Line 2'],
        text: 'Line 1\nLine 2',
        batchRef: 'ref',
      );

      expect(message.isMultiline, isTrue);
      expect(message.lineCount, equals(2));
    });

    test('isMultiline with single line', () {
      const message = MultilineMessage(
        target: '#channel',
        lines: ['Single'],
        text: 'Single',
        batchRef: 'ref',
      );

      expect(message.isMultiline, isFalse);
      expect(message.lineCount, equals(1));
    });
  });
}
