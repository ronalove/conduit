import 'dart:io';

class TestConfig {
  final String host;
  final int port;
  final String nick;
  final String user;
  final String? password;
  final String channel;
  final bool allowInvalidCerts;

  const TestConfig({
    required this.host,
    this.port = 6697,
    required this.nick,
    required this.user,
    this.password,
    this.channel = '#conduit-test',
    this.allowInvalidCerts = false,
  });

  factory TestConfig.fromEnvironment() {
    final host = Platform.environment['IRC_TEST_HOST'];
    final nick = Platform.environment['IRC_TEST_NICK'];
    final user = Platform.environment['IRC_TEST_USER'];

    if (host == null || nick == null || user == null) {
      throw StateError(
        'Missing required environment variables: '
        'IRC_TEST_HOST, IRC_TEST_NICK, IRC_TEST_USER',
      );
    }

    return TestConfig(
      host: host,
      port: int.tryParse(Platform.environment['IRC_TEST_PORT'] ?? '') ?? 6697,
      nick: nick,
      user: user,
      password: Platform.environment['IRC_TEST_PASS'],
      channel: Platform.environment['IRC_TEST_CHANNEL'] ?? '#conduit-test',
      allowInvalidCerts:
          Platform.environment['IRC_TEST_ALLOW_INVALID_CERTS'] == 'true',
    );
  }
}
