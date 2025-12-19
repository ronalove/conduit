import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/protocol/capability_negotiator.dart';
import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/commands/capability_commands.dart';

void main() {
  group('CapabilityNegotiator', () {
    late CapabilityNegotiator negotiator;

    setUp(() {
      negotiator = CapabilityNegotiator();
    });

    group('initial state', () {
      test('starts in idle phase', () {
        expect(negotiator.phase, CapNegotiationPhase.idle);
      });

      test('has no available capabilities', () {
        expect(negotiator.available.isEmpty, true);
      });

      test('has no enabled capabilities', () {
        expect(negotiator.enabled.isEmpty, true);
      });
    });

    group('startNegotiation', () {
      test('returns CAP LS 302 command', () {
        final cmd = negotiator.startNegotiation();

        expect(cmd, isA<CapCommand>());
        final msg = cmd.toMessage();
        expect(msg.command, 'CAP');
        expect(msg.params, ['LS', '302']);
      });

      test('transitions to negotiating phase', () {
        negotiator.startNegotiation();
        expect(negotiator.phase, CapNegotiationPhase.negotiating);
      });

      test('allows custom version', () {
        final cmd = negotiator.startNegotiation(version: 301);
        final msg = cmd.toMessage();
        expect(msg.params, ['LS', '301']);
      });

      test('allows no version', () {
        final cmd = negotiator.startNegotiation(version: null);
        final msg = cmd.toMessage();
        expect(msg.params, ['LS']);
      });
    });

    group('handleMessage', () {
      group('CAP LS response', () {
        test('parses single-line LS response', () {
          negotiator.startNegotiation();
          final msg = IrcMessage(
            source: 'server',
            command: 'CAP',
            params: ['*', 'LS', 'sasl multi-prefix away-notify'],
          );

          final result = negotiator.handleMessage(msg);

          expect(result.type, CapResultType.lsComplete);
          expect(negotiator.available.has('sasl'), true);
          expect(negotiator.available.has('multi-prefix'), true);
          expect(negotiator.available.has('away-notify'), true);
        });

        test('parses LS response with values', () {
          negotiator.startNegotiation();
          final msg = IrcMessage(
            source: 'server',
            command: 'CAP',
            params: ['*', 'LS', 'sasl=PLAIN,EXTERNAL sts=port=6697'],
          );

          negotiator.handleMessage(msg);

          expect(negotiator.available.get('sasl')?.value, 'PLAIN,EXTERNAL');
          expect(negotiator.available.get('sts')?.value, 'port=6697');
        });

        test('handles multi-line LS response with asterisk', () {
          negotiator.startNegotiation();

          // First line with asterisk (continuation)
          final msg1 = IrcMessage(
            source: 'server',
            command: 'CAP',
            params: ['*', 'LS', '*', 'sasl multi-prefix'],
          );
          var result = negotiator.handleMessage(msg1);
          expect(result.type, CapResultType.lsContinuing);

          // Second line (final)
          final msg2 = IrcMessage(
            source: 'server',
            command: 'CAP',
            params: ['*', 'LS', 'away-notify account-notify'],
          );
          result = negotiator.handleMessage(msg2);
          expect(result.type, CapResultType.lsComplete);

          expect(negotiator.available.has('sasl'), true);
          expect(negotiator.available.has('multi-prefix'), true);
          expect(negotiator.available.has('away-notify'), true);
          expect(negotiator.available.has('account-notify'), true);
        });
      });

      group('CAP ACK response', () {
        test('marks capabilities as enabled', () {
          negotiator.startNegotiation();
          // Simulate LS response
          negotiator.handleMessage(IrcMessage(
            command: 'CAP',
            params: ['*', 'LS', 'sasl multi-prefix'],
          ));
          // Simulate REQ
          negotiator.requestCapabilities(['sasl', 'multi-prefix']);

          final msg = IrcMessage(
            command: 'CAP',
            params: ['nick', 'ACK', 'sasl multi-prefix'],
          );
          final result = negotiator.handleMessage(msg);

          expect(result.type, CapResultType.ack);
          expect(negotiator.enabled.has('sasl'), true);
          expect(negotiator.enabled.has('multi-prefix'), true);
        });

        test('handles partial ACK', () {
          negotiator.startNegotiation();
          negotiator.handleMessage(IrcMessage(
            command: 'CAP',
            params: ['*', 'LS', 'sasl multi-prefix'],
          ));
          negotiator.requestCapabilities(['sasl', 'multi-prefix', 'unknown']);

          final msg = IrcMessage(
            command: 'CAP',
            params: ['nick', 'ACK', 'sasl multi-prefix'],
          );
          negotiator.handleMessage(msg);

          expect(negotiator.enabled.has('sasl'), true);
          expect(negotiator.enabled.has('multi-prefix'), true);
          expect(negotiator.enabled.has('unknown'), false);
        });
      });

      group('CAP NAK response', () {
        test('reports rejected capabilities', () {
          negotiator.startNegotiation();
          negotiator.handleMessage(IrcMessage(
            command: 'CAP',
            params: ['*', 'LS', 'sasl'],
          ));
          negotiator.requestCapabilities(['sasl', 'unknown']);

          final msg = IrcMessage(
            command: 'CAP',
            params: ['nick', 'NAK', 'unknown'],
          );
          final result = negotiator.handleMessage(msg);

          expect(result.type, CapResultType.nak);
          expect(result.capabilities, contains('unknown'));
        });
      });

      group('CAP NEW (cap-notify)', () {
        test('adds new capabilities to available set', () {
          negotiator.startNegotiation();
          negotiator.handleMessage(IrcMessage(
            command: 'CAP',
            params: ['*', 'LS', 'sasl cap-notify'],
          ));
          negotiator.requestCapabilities(['cap-notify']);
          negotiator.handleMessage(IrcMessage(
            command: 'CAP',
            params: ['nick', 'ACK', 'cap-notify'],
          ));
          negotiator.endNegotiation();

          // Server sends NEW
          final msg = IrcMessage(
            command: 'CAP',
            params: ['nick', 'NEW', 'away-notify account-notify'],
          );
          final result = negotiator.handleMessage(msg);

          expect(result.type, CapResultType.newCaps);
          expect(negotiator.available.has('away-notify'), true);
          expect(negotiator.available.has('account-notify'), true);
        });
      });

      group('CAP DEL (cap-notify)', () {
        test('removes capabilities from available and enabled sets', () {
          negotiator.startNegotiation();
          negotiator.handleMessage(IrcMessage(
            command: 'CAP',
            params: ['*', 'LS', 'sasl multi-prefix cap-notify'],
          ));
          negotiator.requestCapabilities(['sasl', 'multi-prefix', 'cap-notify']);
          negotiator.handleMessage(IrcMessage(
            command: 'CAP',
            params: ['nick', 'ACK', 'sasl multi-prefix cap-notify'],
          ));
          negotiator.endNegotiation();

          // Server sends DEL
          final msg = IrcMessage(
            command: 'CAP',
            params: ['nick', 'DEL', 'multi-prefix'],
          );
          final result = negotiator.handleMessage(msg);

          expect(result.type, CapResultType.delCaps);
          expect(negotiator.available.has('multi-prefix'), false);
          expect(negotiator.enabled.has('multi-prefix'), false);
          // sasl should still be there
          expect(negotiator.enabled.has('sasl'), true);
        });
      });

      group('CAP LIST response', () {
        test('returns currently enabled capabilities', () {
          negotiator.startNegotiation();
          negotiator.handleMessage(IrcMessage(
            command: 'CAP',
            params: ['*', 'LS', 'sasl multi-prefix'],
          ));
          negotiator.requestCapabilities(['sasl', 'multi-prefix']);
          negotiator.handleMessage(IrcMessage(
            command: 'CAP',
            params: ['nick', 'ACK', 'sasl multi-prefix'],
          ));
          negotiator.endNegotiation();

          final msg = IrcMessage(
            command: 'CAP',
            params: ['nick', 'LIST', 'sasl multi-prefix'],
          );
          final result = negotiator.handleMessage(msg);

          expect(result.type, CapResultType.list);
          expect(result.capabilities, containsAll(['sasl', 'multi-prefix']));
        });
      });
    });

    group('requestCapabilities', () {
      test('returns CAP REQ command', () {
        negotiator.startNegotiation();
        negotiator.handleMessage(IrcMessage(
          command: 'CAP',
          params: ['*', 'LS', 'sasl multi-prefix'],
        ));

        final cmd = negotiator.requestCapabilities(['sasl', 'multi-prefix']);

        expect(cmd, isA<CapCommand>());
        final msg = cmd.toMessage();
        expect(msg.command, 'CAP');
        expect(msg.params[0], 'REQ');
        expect(msg.params[1], contains('sasl'));
        expect(msg.params[1], contains('multi-prefix'));
      });

      test('tracks requested capabilities', () {
        negotiator.startNegotiation();
        negotiator.handleMessage(IrcMessage(
          command: 'CAP',
          params: ['*', 'LS', 'sasl multi-prefix'],
        ));
        negotiator.requestCapabilities(['sasl']);

        expect(negotiator.requested.has('sasl'), true);
      });
    });

    group('endNegotiation', () {
      test('returns CAP END command', () {
        negotiator.startNegotiation();
        negotiator.handleMessage(IrcMessage(
          command: 'CAP',
          params: ['*', 'LS', 'sasl'],
        ));

        final cmd = negotiator.endNegotiation();

        expect(cmd, isA<CapCommand>());
        final msg = cmd.toMessage();
        expect(msg.command, 'CAP');
        expect(msg.params, ['END']);
      });

      test('transitions to completed phase', () {
        negotiator.startNegotiation();
        negotiator.handleMessage(IrcMessage(
          command: 'CAP',
          params: ['*', 'LS', 'sasl'],
        ));
        negotiator.endNegotiation();

        expect(negotiator.phase, CapNegotiationPhase.completed);
      });
    });

    group('desired capabilities', () {
      test('filters available capabilities against desired list', () {
        negotiator.startNegotiation();
        negotiator.handleMessage(IrcMessage(
          command: 'CAP',
          params: ['*', 'LS', 'sasl multi-prefix away-notify unknown-cap'],
        ));

        final desired = ['sasl', 'multi-prefix', 'server-time'];
        final toRequest = negotiator.filterAvailable(desired);

        expect(toRequest, containsAll(['sasl', 'multi-prefix']));
        expect(toRequest, isNot(contains('server-time')));
        expect(toRequest, isNot(contains('away-notify')));
      });
    });

    group('reset', () {
      test('clears all state', () {
        negotiator.startNegotiation();
        negotiator.handleMessage(IrcMessage(
          command: 'CAP',
          params: ['*', 'LS', 'sasl'],
        ));
        negotiator.requestCapabilities(['sasl']);
        negotiator.handleMessage(IrcMessage(
          command: 'CAP',
          params: ['nick', 'ACK', 'sasl'],
        ));

        negotiator.reset();

        expect(negotiator.phase, CapNegotiationPhase.idle);
        expect(negotiator.available.isEmpty, true);
        expect(negotiator.requested.isEmpty, true);
        expect(negotiator.enabled.isEmpty, true);
      });
    });

    group('state stream', () {
      test('emits state changes', () async {
        final states = <CapNegotiationPhase>[];
        negotiator.phases.listen((phase) => states.add(phase));

        negotiator.startNegotiation();
        negotiator.handleMessage(IrcMessage(
          command: 'CAP',
          params: ['*', 'LS', 'sasl'],
        ));
        negotiator.endNegotiation();

        await Future.delayed(Duration.zero);

        expect(states, [
          CapNegotiationPhase.negotiating,
          CapNegotiationPhase.completed,
        ]);
      });
    });

    group('isCapabilityEnabled', () {
      test('returns true for enabled capability', () {
        negotiator.startNegotiation();
        negotiator.handleMessage(IrcMessage(
          command: 'CAP',
          params: ['*', 'LS', 'sasl'],
        ));
        negotiator.requestCapabilities(['sasl']);
        negotiator.handleMessage(IrcMessage(
          command: 'CAP',
          params: ['nick', 'ACK', 'sasl'],
        ));

        expect(negotiator.isCapabilityEnabled('sasl'), true);
        expect(negotiator.isCapabilityEnabled('multi-prefix'), false);
      });
    });

    group('version negotiation', () {
      test('detects CAP 302 support', () {
        negotiator.startNegotiation(version: 302);
        // CAP 302 is indicated by capability values in LS response
        negotiator.handleMessage(IrcMessage(
          command: 'CAP',
          params: ['*', 'LS', 'sasl=PLAIN multi-prefix'],
        ));

        expect(negotiator.supportsCapVersion302, true);
      });
    });
  });
}
