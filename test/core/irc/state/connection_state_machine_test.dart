import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/state/connection_state.dart';
import 'package:conduit/core/irc/state/connection_state_machine.dart';

void main() {
  group('ConnectionPhase', () {
    test('has all expected values', () {
      expect(ConnectionPhase.values, containsAll([
        ConnectionPhase.disconnected,
        ConnectionPhase.connecting,
        ConnectionPhase.registering,
        ConnectionPhase.connected,
        ConnectionPhase.reconnecting,
      ]));
    });
  });

  group('IrcConnectionState', () {
    test('initial state is disconnected', () {
      final state = IrcConnectionState.initial();
      expect(state.phase, ConnectionPhase.disconnected);
      expect(state.reconnectAttempt, 0);
      expect(state.lastError, isNull);
      expect(state.connectedAt, isNull);
    });

    test('copyWith creates modified copy', () {
      final state = IrcConnectionState.initial();
      final modified = state.copyWith(
        phase: ConnectionPhase.connected,
        connectedAt: DateTime.now(),
      );

      expect(modified.phase, ConnectionPhase.connected);
      expect(modified.connectedAt, isNotNull);
      expect(modified.reconnectAttempt, 0);
    });
  });

  group('ConnectionStateMachine', () {
    late ConnectionStateMachine machine;
    late List<ConnectionPhase> stateHistory;

    setUp(() {
      machine = ConnectionStateMachine();
      stateHistory = [];
      machine.states.listen((state) => stateHistory.add(state.phase));
    });

    tearDown(() {
      machine.dispose();
    });

    test('starts in disconnected state', () {
      expect(machine.currentState.phase, ConnectionPhase.disconnected);
    });

    test('transitions to connecting', () {
      machine.startConnecting();
      expect(machine.currentState.phase, ConnectionPhase.connecting);
    });

    test('transitions connecting -> registering', () {
      machine.startConnecting();
      machine.connectionEstablished();
      expect(machine.currentState.phase, ConnectionPhase.registering);
    });

    test('transitions registering -> connected on registration complete', () {
      machine.startConnecting();
      machine.connectionEstablished();
      machine.registrationComplete();

      expect(machine.currentState.phase, ConnectionPhase.connected);
      expect(machine.currentState.connectedAt, isNotNull);
    });

    test('transitions to reconnecting on connection lost', () {
      machine.startConnecting();
      machine.connectionEstablished();
      machine.registrationComplete();

      final error = Exception('Network error');
      machine.connectionLost(error);

      expect(machine.currentState.phase, ConnectionPhase.reconnecting);
      expect(machine.currentState.lastError, error);
      expect(machine.currentState.reconnectAttempt, 1);
    });

    test('increments reconnect attempt on each failure', () {
      machine.startConnecting();
      machine.connectionEstablished();
      machine.registrationComplete();
      machine.connectionLost(null);
      expect(machine.currentState.reconnectAttempt, 1);

      machine.startConnecting();
      machine.connectionLost(null);
      expect(machine.currentState.reconnectAttempt, 2);

      machine.startConnecting();
      machine.connectionLost(null);
      expect(machine.currentState.reconnectAttempt, 3);
    });

    test('reset clears state', () {
      machine.startConnecting();
      machine.connectionEstablished();
      machine.registrationComplete();
      machine.connectionLost(Exception('error'));
      machine.startConnecting();
      machine.connectionLost(null);

      machine.reset();

      expect(machine.currentState.phase, ConnectionPhase.disconnected);
      expect(machine.currentState.reconnectAttempt, 0);
      expect(machine.currentState.lastError, isNull);
      expect(machine.currentState.connectedAt, isNull);
    });

    test('emits state changes to stream', () async {
      machine.startConnecting();
      machine.connectionEstablished();
      machine.registrationComplete();

      await Future.delayed(Duration.zero);

      expect(stateHistory, [
        ConnectionPhase.connecting,
        ConnectionPhase.registering,
        ConnectionPhase.connected,
      ]);
    });

    test('canTransitionTo validates transitions', () {
      // From disconnected
      expect(machine.canTransitionTo(ConnectionPhase.connecting), isTrue);
      expect(machine.canTransitionTo(ConnectionPhase.connected), isFalse);
      expect(machine.canTransitionTo(ConnectionPhase.registering), isFalse);

      machine.startConnecting();

      // From connecting
      expect(machine.canTransitionTo(ConnectionPhase.registering), isTrue);
      expect(machine.canTransitionTo(ConnectionPhase.disconnected), isTrue);
      expect(machine.canTransitionTo(ConnectionPhase.connected), isFalse);
    });

    test('disconnect transitions to disconnected from any state', () {
      machine.startConnecting();
      machine.connectionEstablished();
      machine.disconnect();

      expect(machine.currentState.phase, ConnectionPhase.disconnected);
    });

    test('resets reconnect attempt on successful connection', () {
      // First connection and disconnect
      machine.startConnecting();
      machine.connectionEstablished();
      machine.registrationComplete();
      machine.connectionLost(null);
      expect(machine.currentState.reconnectAttempt, 1);

      machine.startConnecting();
      machine.connectionLost(null);
      expect(machine.currentState.reconnectAttempt, 2);

      // Successful reconnection resets counter
      machine.startConnecting();
      machine.connectionEstablished();
      machine.registrationComplete();

      expect(machine.currentState.phase, ConnectionPhase.connected);
      expect(machine.currentState.reconnectAttempt, 0);
    });

    test('tracks disconnectedAt timestamp', () {
      machine.startConnecting();
      machine.connectionEstablished();
      machine.registrationComplete();

      final beforeDisconnect = DateTime.now();
      machine.connectionLost(null);

      expect(machine.currentState.disconnectedAt, isNotNull);
      expect(
        machine.currentState.disconnectedAt!.isAfter(
          beforeDisconnect.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });
  });
}
