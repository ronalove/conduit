import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/connection/connection_config.dart';
import 'package:conduit/core/irc/connection/socket_manager.dart';
import 'package:conduit/core/irc/connection/socket_manager_impl.dart';

void main() {
  group('ConnectionConfig', () {
    test('has sensible defaults', () {
      const config = ConnectionConfig(host: 'irc.example.com');
      expect(config.host, 'irc.example.com');
      expect(config.port, 6697);
      expect(config.timeout, const Duration(seconds: 30));
      expect(config.allowInvalidCerts, isFalse);
      expect(config.password, isNull);
    });

    test('copyWith creates modified copy', () {
      const config = ConnectionConfig(host: 'irc.example.com');
      final modified = config.copyWith(port: 6667, allowInvalidCerts: true);

      expect(modified.host, 'irc.example.com');
      expect(modified.port, 6667);
      expect(modified.allowInvalidCerts, isTrue);
    });

    test('equality works correctly', () {
      const config1 = ConnectionConfig(host: 'irc.example.com');
      const config2 = ConnectionConfig(host: 'irc.example.com');
      const config3 = ConnectionConfig(host: 'other.example.com');

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });
  });

  group('ConnectionEvent', () {
    test('ConnectionEstablished holds host and port', () {
      const event = ConnectionEstablished(host: 'irc.example.com', port: 6697);
      expect(event.host, 'irc.example.com');
      expect(event.port, 6697);
    });

    test('ConnectionLost can hold error', () {
      final error = Exception('test error');
      final event = ConnectionLost(error: error);
      expect(event.error, error);
    });

    test('ConnectionError holds error', () {
      final error = Exception('test error');
      final event = ConnectionError(error: error);
      expect(event.error, error);
    });
  });

  group('ConnectionStatus', () {
    test('has all expected values', () {
      expect(ConnectionStatus.values, containsAll([
        ConnectionStatus.disconnected,
        ConnectionStatus.connecting,
        ConnectionStatus.connected,
        ConnectionStatus.error,
      ]));
    });
  });

  group('SecureSocketManager', () {
    late SecureSocketManager manager;

    setUp(() {
      manager = SecureSocketManager();
    });

    tearDown(() {
      manager.dispose();
    });

    test('initial status is disconnected', () {
      expect(manager.status, ConnectionStatus.disconnected);
    });

    test('send throws when not connected', () {
      expect(
        () => manager.send('PING :test'),
        throwsA(isA<StateError>()),
      );
    });

    test('lines stream is broadcast', () {
      // Should be able to listen multiple times
      manager.lines.listen((_) {});
      manager.lines.listen((_) {});
      // No error expected
    });

    test('events stream is broadcast', () {
      // Should be able to listen multiple times
      manager.events.listen((_) {});
      manager.events.listen((_) {});
      // No error expected
    });

    test('disconnect when not connected does not error', () async {
      await manager.disconnect();
      expect(manager.status, ConnectionStatus.disconnected);
    });

    // Note: Integration tests with actual network connections
    // should be in a separate integration_test directory
  });
}
