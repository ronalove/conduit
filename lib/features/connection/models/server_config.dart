import 'package:equatable/equatable.dart';

/// Configuration for connecting to an IRC server.
class ServerConfig extends Equatable {
  /// Server hostname or IP address.
  final String host;

  /// Server port.
  final int port;

  /// Whether to use TLS.
  final bool useTls;

  /// Whether to allow invalid/self-signed certificates.
  final bool allowInvalidCerts;

  /// Connection timeout.
  final Duration timeout;

  /// SASL username (account name).
  final String? saslUsername;

  /// SASL password.
  final String? saslPassword;

  /// Server password (PASS command, separate from SASL).
  final String? serverPassword;

  const ServerConfig({
    required this.host,
    this.port = 6697,
    this.useTls = true,
    this.allowInvalidCerts = false,
    this.timeout = const Duration(seconds: 30),
    this.saslUsername,
    this.saslPassword,
    this.serverPassword,
  });

  /// Development server configuration.
  /// Connects to local Ergo server at 10.0.0.4:6697.
  /// Note: Ergo uses self-signed certificates by default.
  factory ServerConfig.development({
    String? saslUsername,
    String? saslPassword,
  }) {
    return ServerConfig(
      host: '10.0.0.4',
      port: 6697,
      useTls: true,
      allowInvalidCerts: true, // Ergo self-signed cert
      saslUsername: saslUsername,
      saslPassword: saslPassword,
    );
  }

  /// Whether SASL authentication is configured.
  bool get hasSaslCredentials =>
      saslUsername != null &&
      saslUsername!.isNotEmpty &&
      saslPassword != null &&
      saslPassword!.isNotEmpty;

  ServerConfig copyWith({
    String? host,
    int? port,
    bool? useTls,
    bool? allowInvalidCerts,
    Duration? timeout,
    String? saslUsername,
    String? saslPassword,
    String? serverPassword,
  }) {
    return ServerConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      useTls: useTls ?? this.useTls,
      allowInvalidCerts: allowInvalidCerts ?? this.allowInvalidCerts,
      timeout: timeout ?? this.timeout,
      saslUsername: saslUsername ?? this.saslUsername,
      saslPassword: saslPassword ?? this.saslPassword,
      serverPassword: serverPassword ?? this.serverPassword,
    );
  }

  @override
  List<Object?> get props => [
        host,
        port,
        useTls,
        allowInvalidCerts,
        timeout,
        saslUsername,
        saslPassword,
        serverPassword,
      ];
}
