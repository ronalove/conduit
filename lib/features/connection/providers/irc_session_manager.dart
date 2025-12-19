import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/irc/commands/capability_commands.dart';
import '../../../core/irc/commands/registration_commands.dart';
import '../../../core/irc/parser/irc_message.dart';
import '../../../core/irc/parser/irc_parser.dart';
import '../../../core/irc/parser/capability_parser.dart';
import '../../../core/irc/state/connection_state.dart';
import '../models/server_config.dart';
import 'connection_provider.dart';

/// Session state during IRC connection.
enum SessionPhase {
  /// Not started.
  idle,

  /// CAP negotiation in progress.
  negotiatingCaps,

  /// SASL authentication in progress.
  authenticating,

  /// Registration (NICK/USER) in progress.
  registering,

  /// Fully connected and registered.
  ready,

  /// Error occurred.
  error,
}

/// IRC session state.
class IrcSessionState {
  final SessionPhase phase;
  final String? nickname;
  final String? serverName;
  final Set<String> enabledCaps;
  final Object? error;

  const IrcSessionState({
    this.phase = SessionPhase.idle,
    this.nickname,
    this.serverName,
    this.enabledCaps = const {},
    this.error,
  });

  bool get isReady => phase == SessionPhase.ready;
  bool get hasError => error != null;

  IrcSessionState copyWith({
    SessionPhase? phase,
    String? nickname,
    String? serverName,
    Set<String>? enabledCaps,
    Object? error,
    bool clearError = false,
  }) {
    return IrcSessionState(
      phase: phase ?? this.phase,
      nickname: nickname ?? this.nickname,
      serverName: serverName ?? this.serverName,
      enabledCaps: enabledCaps ?? this.enabledCaps,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Provider for IRC session management.
final ircSessionProvider =
    NotifierProvider<IrcSessionNotifier, IrcSessionState>(
  IrcSessionNotifier.new,
);

/// Manages the IRC session lifecycle.
class IrcSessionNotifier extends Notifier<IrcSessionState> {
  StreamSubscription<String>? _linesSubscription;

  /// Capabilities we want to request.
  static const _desiredCaps = [
    'sasl',
    'cap-notify',
    'server-time',
    'message-tags',
    'echo-message',
    'labeled-response',
    'away-notify',
    'account-notify',
    'extended-join',
    'multi-prefix',
    'batch',
    'draft/chathistory',
    'draft/read-marker',
  ];

  ServerConfig? _config;
  Set<String> _availableCaps = {};
  bool _saslInProgress = false;

  @override
  IrcSessionState build() {
    ref.onDispose(() {
      _linesSubscription?.cancel();
    });

    return const IrcSessionState();
  }

  void _subscribeToLines() {
    _linesSubscription?.cancel();
    final connectionNotifier = ref.read(connectionProvider.notifier);
    _linesSubscription = connectionNotifier.lines.listen(_handleLine);
  }

  /// Start a new session with the given configuration.
  Future<void> startSession(ServerConfig config) async {
    _config = config;
    _availableCaps = {};
    _saslInProgress = false;

    state = const IrcSessionState(phase: SessionPhase.idle);

    final connection = ref.read(connectionProvider.notifier);
    await connection.connect(config);

    // Subscribe to IRC lines
    _subscribeToLines();

    // Wait for connection to be in registering phase
    await _waitForRegistering();

    // Start CAP negotiation
    state = state.copyWith(phase: SessionPhase.negotiatingCaps);
    _send(CapCommand.ls(version: 302).toRaw());
  }

  Future<void> _waitForRegistering() async {
    final completer = Completer<void>();
    Timer? pollTimer;

    void checkState() {
      final connState = ref.read(connectionProvider);
      if (connState.phase == ConnectionPhase.registering) {
        pollTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      } else if (connState.phase == ConnectionPhase.disconnected &&
          connState.hasError) {
        pollTimer?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(connState.lastError!);
        }
      }
    }

    // Check current state immediately
    checkState();
    if (completer.isCompleted) return completer.future;

    // Poll for state changes
    pollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      checkState();
    });

    // Overall timeout
    Timer(const Duration(seconds: 30), () {
      pollTimer?.cancel();
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('Connection timeout'));
      }
    });

    return completer.future;
  }

  /// End the session.
  Future<void> endSession() async {
    _linesSubscription?.cancel();
    await ref.read(connectionProvider.notifier).disconnect();
    state = const IrcSessionState();
  }

  void _handleLine(String line) {
    final message = IrcParser.parse(line);

    switch (message.command) {
      case 'CAP':
        _handleCap(message);
      case 'AUTHENTICATE':
        _handleAuthenticate(message);
      case '001': // RPL_WELCOME
        _handleWelcome(message);
      case '903': // RPL_SASLSUCCESS
        _handleSaslSuccess();
      case '902': // ERR_NICKLOCKED
      case '904': // ERR_SASLFAIL
      case '905': // ERR_SASLTOOLONG
      case '906': // ERR_SASLABORTED
      case '907': // ERR_SASLALREADY
      case '908': // RPL_SASLMECHS
        _handleSaslError(message);
      case 'PING':
        _handlePing(message);
      case 'ERROR':
        _handleError(message);
    }
  }

  void _handleCap(IrcMessage message) {
    if (message.params.length < 2) return;

    final subcommand = message.params[1];

    switch (subcommand) {
      case 'LS':
        _handleCapLs(message);
      case 'ACK':
        _handleCapAck(message);
      case 'NAK':
        _handleCapNak(message);
    }
  }

  void _handleCapLs(IrcMessage message) {
    final capsParam = message.params.length > 2 ? message.params.last : '';
    final caps = CapabilityParser.parseList(capsParam);

    for (final cap in caps) {
      _availableCaps.add(cap.name);
    }

    // Check if this is a multiline response
    final isMultiline =
        message.params.length > 2 && message.params[2] == '*';
    if (isMultiline) return;

    // Request desired caps that are available
    final toRequest =
        _desiredCaps.where((c) => _availableCaps.contains(c)).toList();

    if (toRequest.isNotEmpty) {
      _send(CapCommand.req(toRequest).toRaw());
    } else {
      _finishCapNegotiation();
    }
  }

  void _handleCapAck(IrcMessage message) {
    final capsParam = message.params.length > 2 ? message.params.last : '';
    final acked = capsParam.split(' ').where((s) => s.isNotEmpty).toSet();

    state = state.copyWith(enabledCaps: {...state.enabledCaps, ...acked});

    // If SASL is enabled and we have credentials, authenticate
    if (acked.contains('sasl') && _config?.hasSaslCredentials == true) {
      _startSasl();
    } else {
      _finishCapNegotiation();
    }
  }

  void _handleCapNak(IrcMessage message) {
    // Some caps were rejected, continue anyway
    _finishCapNegotiation();
  }

  void _startSasl() {
    state = state.copyWith(phase: SessionPhase.authenticating);
    _saslInProgress = true;
    _send(AuthenticateCommand.mechanism('PLAIN').toRaw());
  }

  void _handleAuthenticate(IrcMessage message) {
    if (!_saslInProgress) return;

    // Server is ready for credentials
    if (message.params.isNotEmpty && message.params[0] == '+') {
      final cmd = AuthenticateCommand.plain(
        username: _config!.saslUsername!,
        password: _config!.saslPassword!,
      );
      _send(cmd.toRaw());
    }
  }

  void _handleSaslSuccess() {
    _saslInProgress = false;
    _finishCapNegotiation();
  }

  void _handleSaslError(IrcMessage message) {
    _saslInProgress = false;
    final errorMsg = message.params.length > 1 ? message.params.last : 'SASL failed';
    state = state.copyWith(
      phase: SessionPhase.error,
      error: 'SASL authentication failed: $errorMsg',
    );
  }

  void _finishCapNegotiation() {
    _send(CapCommand.end().toRaw());

    // Send NICK and USER
    state = state.copyWith(phase: SessionPhase.registering);
    final nickname = _config!.saslUsername ?? 'ConduitUser';
    _send(NickCommand(nickname).toRaw());
    _send(UserCommand(
      username: nickname,
      realname: 'Conduit IRC Client',
    ).toRaw());
  }

  void _handleWelcome(IrcMessage message) {
    // 001 :Welcome to the network, nickname!
    final nickname = message.params.isNotEmpty ? message.params[0] : null;
    final serverName = message.parsedSource?.nick;

    state = state.copyWith(
      phase: SessionPhase.ready,
      nickname: nickname,
      serverName: serverName,
      clearError: true,
    );

    // Mark connection as complete
    ref.read(connectionProvider.notifier).registrationComplete();
  }

  void _handlePing(IrcMessage message) {
    final token = message.params.isNotEmpty ? message.params[0] : '';
    _send('PONG :$token');
  }

  void _handleError(IrcMessage message) {
    final errorMsg = message.params.isNotEmpty ? message.params.last : 'Server error';
    state = state.copyWith(
      phase: SessionPhase.error,
      error: errorMsg,
    );
  }

  void _send(String line) {
    try {
      ref.read(connectionProvider.notifier).send(line);
    } catch (e) {
      state = state.copyWith(
        phase: SessionPhase.error,
        error: e,
      );
    }
  }
}
