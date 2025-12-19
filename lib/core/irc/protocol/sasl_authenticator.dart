import 'dart:async';

import '../commands/capability_commands.dart';
import '../parser/irc_message.dart';
import '../parser/capability_parser.dart';

/// SASL authentication states.
enum SaslState {
  /// Not started.
  idle,

  /// AUTHENTICATE [mechanism] sent, waiting for server response.
  mechanismSent,

  /// Server sent +, waiting for credentials.
  waitingForCredentials,

  /// Credentials sent, waiting for result.
  credentialsSent,

  /// Authentication successful (903 received).
  authenticated,

  /// Authentication failed.
  failed,

  /// Authentication aborted by client.
  aborted,
}

/// SASL error types.
enum SaslError {
  /// 902 ERR_NICKLOCKED - Must use assigned nick.
  nickLocked,

  /// 904 ERR_SASLFAIL - Authentication failed.
  authFailed,

  /// 905 ERR_SASLTOOLONG - Message too long.
  tooLong,

  /// 906 ERR_SASLABORTED - Authentication aborted.
  aborted,

  /// 907 ERR_SASLALREADY - Already authenticated.
  alreadyAuthenticated,

  /// Unknown error.
  unknown,
}

/// Result type from handling a SASL-related message.
enum SaslResultType {
  /// Server ready for credentials (AUTHENTICATE +).
  credentialsNeeded,

  /// Logged in (900 RPL_LOGGEDIN).
  loggedIn,

  /// Authentication successful (903 RPL_SASLSUCCESS).
  success,

  /// Authentication error.
  error,

  /// Available mechanisms (908 RPL_SASLMECHS).
  mechanismsAvailable,

  /// Unknown or unhandled message.
  unknown,
}

/// Result of handling a SASL message.
class SaslResult {
  final SaslResultType type;
  final SaslError? error;
  final String? message;
  final List<String>? mechanisms;

  const SaslResult(
    this.type, {
    this.error,
    this.message,
    this.mechanisms,
  });
}

/// Manages SASL authentication flow.
///
/// Supports PLAIN mechanism over TLS.
///
/// Flow:
/// ```
/// Client: AUTHENTICATE PLAIN
/// Server: AUTHENTICATE +
/// Client: AUTHENTICATE <base64(authzid\0authcid\0password)>
/// Server: 900 - Logged in
/// Server: 903 - SASL success
/// ```
///
/// See: https://ircv3.net/specs/extensions/sasl-3.2
class SaslAuthenticator {
  SaslState _state = SaslState.idle;
  String? _account;
  String? _currentMechanism;

  final StreamController<SaslState> _stateController =
      StreamController<SaslState>.broadcast();

  /// Supported SASL mechanisms.
  static const supportedMechanisms = ['PLAIN'];

  /// Checks if a mechanism is supported.
  static bool isMechanismSupported(String mechanism) {
    return supportedMechanisms.contains(mechanism.toUpperCase());
  }

  /// Current authentication state.
  SaslState get state => _state;

  /// Stream of state changes.
  Stream<SaslState> get states => _stateController.stream;

  /// Whether authentication was successful.
  bool get isAuthenticated => _state == SaslState.authenticated;

  /// Account name after successful authentication.
  String? get account => _account;

  /// Current mechanism being used.
  String? get mechanism => _currentMechanism;

  /// Starts SASL authentication.
  ///
  /// Returns AUTHENTICATE command to send.
  AuthenticateCommand startAuthentication({String mechanism = 'PLAIN'}) {
    _currentMechanism = mechanism;
    _setState(SaslState.mechanismSent);
    return AuthenticateCommand.mechanism(mechanism);
  }

  /// Handles an incoming message related to SASL.
  ///
  /// Returns result indicating what happened.
  SaslResult handleMessage(IrcMessage message) {
    // Handle AUTHENTICATE responses
    if (message.command == 'AUTHENTICATE') {
      return _handleAuthenticate(message);
    }

    // Handle numeric responses
    final numeric = message.numericValue;
    if (numeric == null) {
      return const SaslResult(SaslResultType.unknown);
    }

    switch (numeric) {
      case 900:
        return _handleLoggedIn(message);
      case 901:
        return _handleLoggedOut(message);
      case 903:
        return _handleSuccess(message);
      case 902:
        return _handleError(SaslError.nickLocked, message);
      case 904:
        return _handleError(SaslError.authFailed, message);
      case 905:
        return _handleError(SaslError.tooLong, message);
      case 906:
        return _handleError(SaslError.aborted, message);
      case 907:
        return _handleError(SaslError.alreadyAuthenticated, message);
      case 908:
        return _handleMechanisms(message);
      default:
        return const SaslResult(SaslResultType.unknown);
    }
  }

  SaslResult _handleAuthenticate(IrcMessage message) {
    if (message.params.isEmpty) {
      return const SaslResult(SaslResultType.unknown);
    }

    final data = message.params[0];

    if (data == '+') {
      // Server ready for credentials
      _setState(SaslState.waitingForCredentials);
      return const SaslResult(SaslResultType.credentialsNeeded);
    }

    // Server sent challenge data (not used for PLAIN)
    return const SaslResult(SaslResultType.unknown);
  }

  SaslResult _handleLoggedIn(IrcMessage message) {
    // 900 nick nick!user@host account :message
    if (message.params.length >= 3) {
      _account = message.params[2];
    }
    return SaslResult(
      SaslResultType.loggedIn,
      message: message.params.lastOrNull,
    );
  }

  SaslResult _handleLoggedOut(IrcMessage message) {
    _account = null;
    return SaslResult(
      SaslResultType.loggedIn,
      message: message.params.lastOrNull,
    );
  }

  SaslResult _handleSuccess(IrcMessage message) {
    _setState(SaslState.authenticated);
    return SaslResult(
      SaslResultType.success,
      message: message.params.lastOrNull,
    );
  }

  SaslResult _handleError(SaslError error, IrcMessage message) {
    _setState(SaslState.failed);
    return SaslResult(
      SaslResultType.error,
      error: error,
      message: message.params.lastOrNull,
    );
  }

  SaslResult _handleMechanisms(IrcMessage message) {
    // 908 nick mechanisms :message
    List<String> mechanisms = [];
    if (message.params.length >= 2) {
      mechanisms = CapabilityParser.parseSaslMechanisms(message.params[1]);
    }
    return SaslResult(
      SaslResultType.mechanismsAvailable,
      mechanisms: mechanisms,
    );
  }

  /// Sends credentials for PLAIN authentication.
  ///
  /// Returns AUTHENTICATE command to send.
  AuthenticateCommand sendCredentials({
    required String username,
    required String password,
    String? authzid,
  }) {
    _setState(SaslState.credentialsSent);
    return AuthenticateCommand.plain(
      username: username,
      password: password,
      authzid: authzid,
    );
  }

  /// Aborts the authentication attempt.
  ///
  /// Returns AUTHENTICATE * command to send.
  AuthenticateCommand abort() {
    _setState(SaslState.aborted);
    return AuthenticateCommand.abort();
  }

  /// Resets the authenticator to initial state.
  void reset() {
    _state = SaslState.idle;
    _account = null;
    _currentMechanism = null;
  }

  /// Disposes resources.
  void dispose() {
    _stateController.close();
  }

  void _setState(SaslState newState) {
    if (newState != _state) {
      _state = newState;
      _stateController.add(_state);
    }
  }
}
