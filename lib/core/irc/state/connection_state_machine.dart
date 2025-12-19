import 'dart:async';
import 'connection_state.dart';

/// Manages IRC connection state transitions.
///
/// Validates state transitions and emits state changes.
class ConnectionStateMachine {
  IrcConnectionState _state = IrcConnectionState.initial();
  final StreamController<IrcConnectionState> _stateController =
      StreamController<IrcConnectionState>.broadcast();

  /// Stream of state changes.
  Stream<IrcConnectionState> get states => _stateController.stream;

  /// Current connection state.
  IrcConnectionState get currentState => _state;

  /// Valid transitions from each phase.
  static const _validTransitions = <ConnectionPhase, Set<ConnectionPhase>>{
    ConnectionPhase.disconnected: {
      ConnectionPhase.connecting,
    },
    ConnectionPhase.connecting: {
      ConnectionPhase.registering,
      ConnectionPhase.disconnected,
      ConnectionPhase.reconnecting,
    },
    ConnectionPhase.registering: {
      ConnectionPhase.connected,
      ConnectionPhase.disconnected,
      ConnectionPhase.reconnecting,
    },
    ConnectionPhase.connected: {
      ConnectionPhase.disconnected,
      ConnectionPhase.reconnecting,
    },
    ConnectionPhase.reconnecting: {
      ConnectionPhase.connecting,
      ConnectionPhase.disconnected,
    },
  };

  /// Whether a transition to the target phase is valid.
  bool canTransitionTo(ConnectionPhase target) {
    final validTargets = _validTransitions[_state.phase];
    return validTargets?.contains(target) ?? false;
  }

  /// Starts the connection process.
  void startConnecting() {
    _transitionTo(
      _state.copyWith(
        phase: ConnectionPhase.connecting,
        clearLastError: true,
      ),
    );
  }

  /// Called when TCP/TLS connection is established.
  ///
  /// Transitions to registering phase.
  void connectionEstablished() {
    _transitionTo(
      _state.copyWith(phase: ConnectionPhase.registering),
    );
  }

  /// Called when IRC registration is complete (001 received).
  ///
  /// Transitions to connected phase and resets reconnect counter.
  void registrationComplete() {
    _transitionTo(
      _state.copyWith(
        phase: ConnectionPhase.connected,
        reconnectAttempt: 0,
        connectedAt: DateTime.now(),
        clearDisconnectedAt: true,
        clearLastError: true,
      ),
    );
  }

  /// Called when connection is lost.
  ///
  /// Transitions to reconnecting phase and increments reconnect counter.
  void connectionLost(Object? error) {
    _transitionTo(
      _state.copyWith(
        phase: ConnectionPhase.reconnecting,
        reconnectAttempt: _state.reconnectAttempt + 1,
        lastError: error,
        disconnectedAt: DateTime.now(),
      ),
    );
  }

  /// Explicitly disconnects (user-initiated).
  ///
  /// Transitions to disconnected without incrementing reconnect counter.
  void disconnect() {
    _transitionTo(
      _state.copyWith(
        phase: ConnectionPhase.disconnected,
        disconnectedAt:
            _state.phase == ConnectionPhase.connected ? DateTime.now() : null,
      ),
    );
  }

  /// Resets the state machine to initial state.
  void reset() {
    _transitionTo(IrcConnectionState.initial());
  }

  /// Disposes resources.
  void dispose() {
    _stateController.close();
  }

  void _transitionTo(IrcConnectionState newState) {
    if (newState.phase != _state.phase || newState != _state) {
      _state = newState;
      _stateController.add(_state);
    }
  }
}
