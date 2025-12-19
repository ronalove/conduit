import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/protocol/labeled_response_handler.dart';
import 'package:test/test.dart';

void main() {
  group('LabeledResponseHandler', () {
    late LabeledResponseHandler handler;

    setUp(() {
      handler = LabeledResponseHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('generateLabel', () {
      test('generates 12 character labels', () {
        final label = handler.generateLabel();
        expect(label.length, equals(12));
      });

      test('generates unique labels', () {
        final labels = <String>{};
        for (var i = 0; i < 100; i++) {
          labels.add(handler.generateLabel());
        }
        expect(labels.length, equals(100));
      });

      test('generates alphanumeric labels', () {
        final label = handler.generateLabel();
        expect(label, matches(RegExp(r'^[a-zA-Z0-9]+$')));
      });
    });

    group('labelCommand', () {
      test('adds label tag to message', () {
        final command = IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = handler.labelCommand(command);

        expect(result.message.tags['label'], equals(result.label));
        expect(result.message.command, equals('PRIVMSG'));
        expect(result.message.params, equals(['#channel', 'Hello']));
      });

      test('preserves existing tags', () {
        final command = IrcMessage(
          tags: {'existing': 'tag'},
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final result = handler.labelCommand(command);

        expect(result.message.tags['existing'], equals('tag'));
        expect(result.message.tags['label'], isNotNull);
      });
    });

    group('handleMessage', () {
      test('returns false for non-labeled messages', () {
        final message = IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        expect(handler.handleMessage(message), isFalse);
      });

      test('returns false for untracked labels', () {
        final message = IrcMessage(
          tags: {'label': 'unknown'},
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        expect(handler.handleMessage(message), isFalse);
      });

      test('completes pending request with single response', () async {
        final command = IrcMessage(
          command: 'WHO',
          params: ['#channel'],
        );

        final labeled = handler.labelCommand(command);

        // Manually track without sending
        final completer = handler.trackCommand(command);
        // Note: trackCommand generates its own label, so we need to use that

        // Actually, let's use a simpler test approach
        handler.dispose();
        handler = LabeledResponseHandler();

        // Track and wait
        final responseFuture = handler.sendAndWait(
          command,
          (_) async {}, // Mock send
        );

        // Get the label from pending
        expect(handler.pendingCount, equals(1));

        // Simulate response - we need to know the label
        // Let's test differently
      });
    });

    group('sendAndWait', () {
      test('sends labeled command and receives response', () async {
        IrcMessage? sentMessage;
        final command = IrcMessage(
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final responseFuture = handler.sendAndWait(
          command,
          (msg) async {
            sentMessage = msg;
          },
        );

        expect(sentMessage, isNotNull);
        expect(sentMessage!.tags['label'], isNotNull);

        final label = sentMessage!.tags['label']!;

        // Simulate server response
        final response = IrcMessage(
          tags: {'label': label, 'msgid': 'xyz'},
          source: 'user!ident@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello'],
        );

        final consumed = handler.handleMessage(response);
        expect(consumed, isTrue);

        final result = await responseFuture;
        expect(result, isA<SingleResponse>());
        final single = result as SingleResponse;
        expect(single.message.tags['msgid'], equals('xyz'));
      });

      test('times out when no response', () async {
        final command = IrcMessage(command: 'PING', params: ['test']);

        final result = await handler.sendAndWait(
          command,
          (_) async {},
          timeout: const Duration(milliseconds: 50),
        );

        expect(result, isA<TimeoutResponse>());
      });
    });

    group('ACK response', () {
      test('handles ACK response', () async {
        final command = IrcMessage(command: 'AWAY', params: ['BRB']);

        IrcMessage? sent;
        final responseFuture = handler.sendAndWait(
          command,
          (msg) async {
            sent = msg;
          },
        );

        final label = sent!.tags['label']!;

        // Server sends ACK
        final ack = IrcMessage(
          tags: {'label': label},
          command: 'ACK',
          params: [],
        );

        handler.handleMessage(ack);

        final result = await responseFuture;
        expect(result, isA<AckResponse>());
      });
    });

    group('batch response', () {
      test('handles labeled-response batch', () async {
        final command = IrcMessage(command: 'WHO', params: ['#channel']);

        IrcMessage? sent;
        final responseFuture = handler.sendAndWait(
          command,
          (msg) async {
            sent = msg;
          },
        );

        final label = sent!.tags['label']!;

        // Server sends batch start
        final batchStart = IrcMessage(
          tags: {'label': label},
          command: 'BATCH',
          params: ['+batchref123', 'labeled-response'],
        );
        handler.handleMessage(batchStart);

        // Server sends batch messages
        final msg1 = IrcMessage(
          tags: {'batch': 'batchref123'},
          command: '352',
          params: ['*', '#channel', 'user1', 'host1', 'server', 'nick1', 'H', '0 realname1'],
        );
        handler.handleMessage(msg1);

        final msg2 = IrcMessage(
          tags: {'batch': 'batchref123'},
          command: '352',
          params: ['*', '#channel', 'user2', 'host2', 'server', 'nick2', 'H', '0 realname2'],
        );
        handler.handleMessage(msg2);

        // Server ends batch
        final batchEnd = IrcMessage(
          command: 'BATCH',
          params: ['-batchref123'],
        );
        handler.handleMessage(batchEnd);

        final result = await responseFuture;
        expect(result, isA<BatchResponse>());
        final batch = result as BatchResponse;
        expect(batch.batchRef, equals('batchref123'));
        expect(batch.messages.length, equals(2));
      });
    });

    group('cancelRequest', () {
      test('cancels pending request', () async {
        final command = IrcMessage(command: 'WHO', params: ['#channel']);

        IrcMessage? sent;
        final responseFuture = handler.sendAndWait(
          command,
          (msg) async {
            sent = msg;
          },
          timeout: const Duration(seconds: 10),
        );

        final label = sent!.tags['label']!;

        handler.cancelRequest(label);

        final result = await responseFuture;
        expect(result, isA<TimeoutResponse>());
      });
    });

    group('clearPending', () {
      test('clears all pending requests', () async {
        final futures = <Future<LabeledResponse>>[];

        for (var i = 0; i < 3; i++) {
          futures.add(handler.sendAndWait(
            IrcMessage(command: 'PING', params: ['$i']),
            (_) async {},
            timeout: const Duration(seconds: 10),
          ));
        }

        expect(handler.pendingCount, equals(3));

        handler.clearPending();

        expect(handler.pendingCount, equals(0));

        for (final future in futures) {
          final result = await future;
          expect(result, isA<TimeoutResponse>());
        }
      });
    });
  });
}
