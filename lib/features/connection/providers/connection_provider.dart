import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/irc/connection/connection_config.dart';
import '../../../core/irc/connection/reconnect_policy.dart';
import '../../../core/irc/connection/socket_manager.dart';
import '../../../core/irc/connection/socket_manager_impl.dart';
import '../../../core/irc/state/connection_state.dart';
import '../../../core/irc/state/connection_state_machine.dart';
import '../models/server_config.dart';

/// Connection state exposed to UI.
class ConnectionState {
  final ConnectionPhase phase;
  final int reconnectAttempt;
  final Object? lastError;
  final DateTime? connectedAt;
  final ServerConfig? serverConfig;

  const ConnectionState({
    this.phase = ConnectionPhase.disconnected,
    this.reconnectAttempt = 0,
    this.lastError,
    this.connectedAt,
    this.serverConfig,
  });

  bool get isConnected => phase == ConnectionPhase.connected;
  bool get isConnecting =>
      phase == ConnectionPhase.connecting ||
      phase == ConnectionPhase.registering;
  bool get isDisconnected => phase == ConnectionPhase.disconnected;
  bool get isReconnecting => phase == ConnectionPhase.reconnecting;
  bool get hasError => lastError != null;

  ConnectionState copyWith({
    ConnectionPhase? phase,
    int? reconnectAttempt,
    Object? lastError,
    bool clearError = false,
    DateTime? connectedAt,
    bool clearConnectedAt = false,
    ServerConfig? serverConfig,
  }) {
    return ConnectionState(
      phase: phase ?? this.phase,
      reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
      lastError: clearError ? null : (lastError ?? this.lastError),
      connectedAt:
          clearConnectedAt ? null : (connectedAt ?? this.connectedAt),
      serverConfig: serverConfig ?? this.serverConfig,
    );
  }
}

/// Provider for the connection state.
final connectionProvider =
    NotifierProvider<ConnectionNotifier, ConnectionState>(
  ConnectionNotifier.new,
);

/// Provider for the raw IRC line stream.
final ircLinesProvider = StreamProvider<String>((ref) {
  final notifier = ref.watch(connectionProvider.notifier);
  return notifier.lines;
});

/// Provider for IRC logs (last 500 lines).
final ircLogsProvider = NotifierProvider<IrcLogsNotifier, List<String>>(
  IrcLogsNotifier.new,
);

/// Notifier for IRC logs.
class IrcLogsNotifier extends Notifier<List<String>> {
  static const _maxLines = 500;
  StreamSubscription<String>? _subscription;

  @override
  List<String> build() {
    final connectionNotifier = ref.read(connectionProvider.notifier);
    _subscription = connectionNotifier.lines.listen(_addLog);

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }

  void _addLog(String line) {
    final newLogs = [...state, line];
    if (newLogs.length > _maxLines) {
      newLogs.removeAt(0);
    }
    state = newLogs;
  }
}

/// Connection notifier managing the IRC socket connection.
class ConnectionNotifier extends Notifier<ConnectionState> {
  SocketManager? _socketManager;
  final ConnectionStateMachine _stateMachine = ConnectionStateMachine();
  final ReconnectPolicy _reconnectPolicy = const ExponentialBackoffPolicy();

  StreamSubscription<ConnectionEvent>? _eventSubscription;
  StreamSubscription<IrcConnectionState>? _stateSubscription;
  Timer? _reconnectTimer;

  final StreamController<String> _linesController =
      StreamController<String>.broadcast();

  StreamSubscription<String>? _linesSubscription;

  /// Stream of IRC lines received from the server.
  Stream<String> get lines => _linesController.stream;

  @override
  ConnectionState build() {
    ref.onDispose(_dispose);
    return const ConnectionState();
  }

  /// Connect to the IRC server.
  Future<void> connect(ServerConfig config) async {
    if (state.phase == ConnectionPhase.connecting ||
        state.phase == ConnectionPhase.connected) {
      return;
    }

    _cancelReconnect();
    _reconnectPolicy.reset();

    state = state.copyWith(
      phase: ConnectionPhase.connecting,
      serverConfig: config,
      clearError: true,
    );
    _stateMachine.startConnecting();

    await _doConnect(config);
  }

  /// Disconnect from the server.
  Future<void> disconnect() async {
    _cancelReconnect();

    if (_socketManager != null) {
      await _socketManager!.disconnect();
      _socketManager!.dispose();
      _socketManager = null;
    }

    _stateMachine.disconnect();
    state = state.copyWith(
      phase: ConnectionPhase.disconnected,
      clearError: true,
    );
  }

  /// Send a raw IRC line to the server.
  void send(String line) {
    if (_socketManager == null) {
      throw StateError('Not connected');
    }
    // Allow sending during registering phase (for CAP/SASL/NICK/USER)
    if (!state.isConnected && state.phase != ConnectionPhase.registering) {
      throw StateError('Not connected');
    }
    _socketManager!.send(line);
  }

  /// Called when registration is complete (001 received).
  void registrationComplete() {
    _stateMachine.registrationComplete();
    state = state.copyWith(
      phase: ConnectionPhase.connected,
      reconnectAttempt: 0,
      connectedAt: DateTime.now(),
      clearError: true,
    );
  }

  /// Trigger a reconnection attempt.
  Future<void> reconnect() async {
    if (state.serverConfig == null) return;

    final attempt = state.reconnectAttempt;
    if (!_reconnectPolicy.shouldReconnect(attempt, state.lastError)) {
      state = state.copyWith(phase: ConnectionPhase.disconnected);
      return;
    }

    state = state.copyWith(
      phase: ConnectionPhase.reconnecting,
      reconnectAttempt: attempt + 1,
    );

    final delay = _reconnectPolicy.getNextDelay(attempt);
    _reconnectTimer = Timer(delay, () async {
      if (state.serverConfig != null) {
        state = state.copyWith(phase: ConnectionPhase.connecting);
        await _doConnect(state.serverConfig!);
      }
    });
  }

  Future<void> _doConnect(ServerConfig config) async {
    try {
      _socketManager?.dispose();
      _socketManager = SecureSocketManager();

      _setupSubscriptions();

      final connectionConfig = ConnectionConfig(
        host: config.host,
        port: config.port,
        timeout: config.timeout,
        allowInvalidCerts: config.allowInvalidCerts,
        password: config.serverPassword,
      );

      await _socketManager!.connect(connectionConfig);

      _stateMachine.connectionEstablished();
      state = state.copyWith(phase: ConnectionPhase.registering);
    } catch (e) {
      _stateMachine.connectionLost(e);
      state = state.copyWith(
        phase: ConnectionPhase.disconnected,
        lastError: e,
      );

      if (config == state.serverConfig) {
        await reconnect();
      }
    }
  }

  void _setupSubscriptions() {
    _eventSubscription?.cancel();
    _linesSubscription?.cancel();

    _eventSubscription = _socketManager!.events.listen(_handleConnectionEvent);
    _linesSubscription = _socketManager!.lines.listen(
      (line) => _linesController.add(line),
    );
  }

  void _handleConnectionEvent(ConnectionEvent event) {
    switch (event) {
      case ConnectionEstablished():
        break;
      case ConnectionLost(:final error):
        _stateMachine.connectionLost(error);
        state = state.copyWith(
          phase: ConnectionPhase.disconnected,
          lastError: error,
        );
        reconnect();
      case ConnectionError(:final error):
        state = state.copyWith(lastError: error);
    }
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _dispose() {
    _cancelReconnect();
    _eventSubscription?.cancel();
    _stateSubscription?.cancel();
    _linesSubscription?.cancel();
    _linesController.close();
    _socketManager?.dispose();
    _stateMachine.dispose();
  }
}
