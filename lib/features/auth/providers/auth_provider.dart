import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connection/connection.dart';

/// Authentication status.
enum AuthStatus {
  /// Not connected to any server.
  disconnected,

  /// Connecting to server (TCP/TLS).
  connecting,

  /// Authenticating via SASL.
  authenticating,

  /// Connected and authenticated.
  connected,

  /// Error occurred.
  error,
}

/// Authentication state.
class AuthState {
  const AuthState({
    this.status = AuthStatus.disconnected,
    this.username,
    this.error,
  });

  /// Current authentication status.
  final AuthStatus status;

  /// Authenticated username.
  final String? username;

  /// Error message if status is [AuthStatus.error].
  final String? error;

  /// Whether the user is authenticated.
  bool get isAuthenticated => status == AuthStatus.connected;

  /// Whether a connection attempt is in progress.
  bool get isLoading =>
      status == AuthStatus.connecting || status == AuthStatus.authenticating;

  AuthState copyWith({
    AuthStatus? status,
    String? username,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      username: username ?? this.username,
      error: error,
    );
  }
}

/// Authentication provider.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Authentication notifier.
class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription<IrcSessionState>? _sessionSubscription;

  @override
  AuthState build() {
    ref.onDispose(() {
      _sessionSubscription?.cancel();
    });

    // Listen to session state changes
    ref.listen(ircSessionProvider, (prev, next) {
      _handleSessionChange(next);
    });

    return const AuthState();
  }

  void _handleSessionChange(IrcSessionState session) {
    switch (session.phase) {
      case SessionPhase.idle:
        // No change needed
        break;
      case SessionPhase.negotiatingCaps:
        state = state.copyWith(status: AuthStatus.connecting);
      case SessionPhase.authenticating:
        state = state.copyWith(status: AuthStatus.authenticating);
      case SessionPhase.registering:
        state = state.copyWith(status: AuthStatus.connecting);
      case SessionPhase.ready:
        state = state.copyWith(
          status: AuthStatus.connected,
          username: session.nickname,
          error: null,
        );
      case SessionPhase.error:
        state = state.copyWith(
          status: AuthStatus.error,
          error: session.error?.toString(),
        );
    }
  }

  /// Attempt to login to the IRC server.
  Future<void> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    state = state.copyWith(
      status: AuthStatus.connecting,
      username: username,
      error: null,
    );

    try {
      final config = ServerConfig.development(
        saslUsername: username,
        saslPassword: password,
      );

      await ref.read(ircSessionProvider.notifier).startSession(config);

      // TODO: Save credentials if rememberMe is true
      if (rememberMe) {
        // Save to secure storage
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Disconnect from the server.
  Future<void> logout() async {
    await ref.read(ircSessionProvider.notifier).endSession();
    state = const AuthState();
  }

  /// Clear error state.
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Retry connection with saved credentials.
  Future<void> reconnect() async {
    if (state.username != null) {
      state = state.copyWith(
        status: AuthStatus.connecting,
        error: null,
      );
      await ref.read(connectionProvider.notifier).reconnect();
    }
  }
}
