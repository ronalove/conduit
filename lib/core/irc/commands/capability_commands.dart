import 'dart:convert';

import '../parser/irc_message.dart';
import 'irc_command.dart';

/// CAP command for capability negotiation (IRCv3).
///
/// Subcommands:
/// - LS: List server capabilities
/// - LIST: List currently enabled capabilities
/// - REQ: Request capabilities
/// - END: End capability negotiation
///
/// See: https://ircv3.net/specs/extensions/capability-negotiation
class CapCommand extends IrcCommand {
  final String subcommand;
  final List<String>? capabilities;
  final int? version;

  const CapCommand._({
    required this.subcommand,
    this.capabilities,
    this.version,
  });

  /// Request list of available capabilities.
  /// Use version 302 for enhanced format with values.
  factory CapCommand.ls({int? version}) => CapCommand._(
        subcommand: 'LS',
        version: version,
      );

  /// List currently enabled capabilities.
  factory CapCommand.list() => const CapCommand._(subcommand: 'LIST');

  /// Request specific capabilities.
  /// Prefix with '-' to disable a capability.
  factory CapCommand.req(List<String> capabilities) => CapCommand._(
        subcommand: 'REQ',
        capabilities: capabilities,
      );

  /// End capability negotiation and proceed to registration.
  factory CapCommand.end() => const CapCommand._(subcommand: 'END');

  @override
  IrcMessage toMessage() {
    final params = <String>[subcommand];

    if (version != null) {
      params.add(version.toString());
    }

    if (capabilities != null && capabilities!.isNotEmpty) {
      params.add(capabilities!.join(' '));
    }

    return IrcMessage(command: 'CAP', params: params);
  }
}

/// AUTHENTICATE command for SASL authentication.
///
/// See: https://ircv3.net/specs/extensions/sasl-3.2
class AuthenticateCommand extends IrcCommand {
  final String data;

  const AuthenticateCommand._(this.data);

  /// Start authentication with specified mechanism.
  factory AuthenticateCommand.mechanism(String mechanism) =>
      AuthenticateCommand._(mechanism);

  /// Send authentication data (base64 encoded).
  factory AuthenticateCommand.data(String data) => AuthenticateCommand._(data);

  /// Abort authentication.
  factory AuthenticateCommand.abort() => const AuthenticateCommand._('*');

  /// Send continuation (empty response or acknowledge).
  factory AuthenticateCommand.continuation() =>
      const AuthenticateCommand._('+');

  /// Create PLAIN authentication command.
  ///
  /// PLAIN format: authzid\0authcid\0password
  /// - authzid: Authorization identity (optional, usually empty)
  /// - authcid: Authentication identity (username)
  /// - password: Password
  factory AuthenticateCommand.plain({
    required String username,
    required String password,
    String? authzid,
  }) {
    final plainData = '${authzid ?? ''}\x00$username\x00$password';
    final encoded = base64.encode(utf8.encode(plainData));
    return AuthenticateCommand._(encoded);
  }

  /// Create chunked PLAIN authentication commands for long credentials.
  ///
  /// SASL data must be sent in chunks of 400 bytes max.
  /// If data is exactly 400 bytes, a '+' must be sent after.
  static List<AuthenticateCommand> plainChunked({
    required String username,
    required String password,
    String? authzid,
  }) {
    final plainData = '${authzid ?? ''}\x00$username\x00$password';
    final encoded = base64.encode(utf8.encode(plainData));

    return _chunkData(encoded);
  }

  /// Chunk arbitrary base64 data into AUTHENTICATE commands.
  static List<AuthenticateCommand> _chunkData(String encoded) {
    const chunkSize = 400;
    final chunks = <AuthenticateCommand>[];

    for (var i = 0; i < encoded.length; i += chunkSize) {
      final end =
          (i + chunkSize > encoded.length) ? encoded.length : i + chunkSize;
      chunks.add(AuthenticateCommand._(encoded.substring(i, end)));
    }

    // If the last chunk is exactly 400 bytes, add continuation
    if (encoded.isNotEmpty && encoded.length % chunkSize == 0) {
      chunks.add(const AuthenticateCommand._('+'));
    }

    return chunks;
  }

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'AUTHENTICATE',
        params: [data],
      );
}
