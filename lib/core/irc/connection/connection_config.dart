import 'package:equatable/equatable.dart';

/// Configuration for an IRC connection.
class ConnectionConfig extends Equatable {
  /// Server hostname.
  final String host;

  /// Server port (default: 6697 for TLS).
  final int port;

  /// Connection timeout.
  final Duration timeout;

  /// Whether to allow invalid/self-signed certificates.
  final bool allowInvalidCerts;

  /// Server password (PASS command).
  final String? password;

  const ConnectionConfig({
    required this.host,
    this.port = 6697,
    this.timeout = const Duration(seconds: 30),
    this.allowInvalidCerts = false,
    this.password,
  });

  /// Creates a copy with updated values.
  ConnectionConfig copyWith({
    String? host,
    int? port,
    Duration? timeout,
    bool? allowInvalidCerts,
    String? password,
  }) {
    return ConnectionConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      timeout: timeout ?? this.timeout,
      allowInvalidCerts: allowInvalidCerts ?? this.allowInvalidCerts,
      password: password ?? this.password,
    );
  }

  @override
  List<Object?> get props => [host, port, timeout, allowInvalidCerts, password];
}
