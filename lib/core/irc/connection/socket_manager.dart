import 'dart:async';
import 'connection_config.dart';

/// Connection event types.
sealed class ConnectionEvent {
  const ConnectionEvent();
}

/// Connection successfully established.
class ConnectionEstablished extends ConnectionEvent {
  final String host;
  final int port;
  const ConnectionEstablished({required this.host, required this.port});
}

/// Connection was lost.
class ConnectionLost extends ConnectionEvent {
  final Object? error;
  final StackTrace? stackTrace;
  const ConnectionLost({this.error, this.stackTrace});
}

/// Connection error occurred.
class ConnectionError extends ConnectionEvent {
  final Object error;
  final StackTrace? stackTrace;
  const ConnectionError({required this.error, this.stackTrace});
}

/// Connection status.
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Abstract interface for IRC socket connections.
///
/// Handles TCP/TLS connections, line buffering, and reconnection.
abstract class SocketManager {
  /// Stream of complete IRC lines received from the server.
  Stream<String> get lines;

  /// Stream of connection events.
  Stream<ConnectionEvent> get events;

  /// Current connection status.
  ConnectionStatus get status;

  /// Connects to the server.
  Future<void> connect(ConnectionConfig config);

  /// Disconnects from the server.
  Future<void> disconnect();

  /// Sends a raw IRC line (CRLF will be appended if not present).
  void send(String line);

  /// Disposes resources.
  void dispose();
}
