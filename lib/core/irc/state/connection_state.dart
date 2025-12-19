import 'package:equatable/equatable.dart';

/// Connection phases for the IRC client.
enum ConnectionPhase {
  /// Not connected to any server.
  disconnected,

  /// TCP/TLS connection in progress.
  connecting,

  /// Connected, registration (CAP/SASL/NICK/USER) in progress.
  registering,

  /// Fully connected and registered.
  connected,

  /// Auto-reconnect in progress after connection loss.
  reconnecting,
}

/// Immutable state of an IRC connection.
class IrcConnectionState extends Equatable {
  /// Current connection phase.
  final ConnectionPhase phase;

  /// Number of reconnection attempts since last successful connection.
  final int reconnectAttempt;

  /// Last error that caused disconnection, if any.
  final Object? lastError;

  /// Timestamp when connection was established.
  final DateTime? connectedAt;

  /// Timestamp when connection was lost.
  final DateTime? disconnectedAt;

  const IrcConnectionState({
    required this.phase,
    this.reconnectAttempt = 0,
    this.lastError,
    this.connectedAt,
    this.disconnectedAt,
  });

  /// Creates the initial disconnected state.
  factory IrcConnectionState.initial() {
    return const IrcConnectionState(phase: ConnectionPhase.disconnected);
  }

  /// Creates a copy with updated values.
  IrcConnectionState copyWith({
    ConnectionPhase? phase,
    int? reconnectAttempt,
    Object? lastError,
    bool clearLastError = false,
    DateTime? connectedAt,
    bool clearConnectedAt = false,
    DateTime? disconnectedAt,
    bool clearDisconnectedAt = false,
  }) {
    return IrcConnectionState(
      phase: phase ?? this.phase,
      reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      connectedAt:
          clearConnectedAt ? null : (connectedAt ?? this.connectedAt),
      disconnectedAt:
          clearDisconnectedAt ? null : (disconnectedAt ?? this.disconnectedAt),
    );
  }

  @override
  List<Object?> get props =>
      [phase, reconnectAttempt, lastError, connectedAt, disconnectedAt];
}
