import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/irc.dart';
import 'package:conduit/core/constants/irc_numerics.dart';

import 'config/test_config.dart';
import 'helpers/irc_test_client.dart';

void main() {
  late TestConfig config;
  late IrcTestClient client;

  setUpAll(() {
    config = TestConfig.fromEnvironment();
  });

  setUp(() {
    client = IrcTestClient(config);
  });

  tearDown(() async {
    await client.disconnect();
    client.dispose();
  });

  group('SASL Authentication', () {
    test('server advertises sasl capability', () async {
      await client.connect();

      client.send(CapCommand.ls(version: 302));
      final response = await client.waitForCommand('CAP');

      final caps = CapabilityParser.parseList(response.params.last);
      final saslCap = caps.where((c) => c.name == 'sasl').firstOrNull;

      if (saslCap == null) {
        markTestSkipped('Server does not support SASL');
        return;
      }

      expect(saslCap.name, 'sasl');
      // SASL capability may have mechanisms as value
      if (saslCap.value != null) {
        final mechanisms = CapabilityParser.parseSaslMechanisms(saslCap.value!);
        expect(mechanisms, isNotEmpty);
      }
    });

    test('full SASL PLAIN authentication flow', () async {
      // Skip if no credentials configured
      final saslUser = config.password != null ? config.nick : null;
      final saslPass = config.password;

      if (saslUser == null || saslPass == null) {
        markTestSkipped('SASL credentials not configured');
        return;
      }

      await client.connect();

      // Start CAP negotiation
      client.send(CapCommand.ls(version: 302));
      final lsResponse = await client.waitForCommand('CAP');

      final caps = CapabilityParser.parseList(lsResponse.params.last);
      if (!caps.any((c) => c.name == 'sasl')) {
        markTestSkipped('Server does not support SASL');
        return;
      }

      // Request SASL
      client.send(CapCommand.req(['sasl']));
      final ackResponse = await client.waitForMessage(
        (msg) =>
            msg.command == 'CAP' &&
            (msg.params[1] == 'ACK' || msg.params[1] == 'NAK'),
      );

      if (ackResponse.params[1] == 'NAK') {
        markTestSkipped('Server rejected SASL capability');
        return;
      }

      // Start SASL PLAIN
      final authenticator = SaslAuthenticator();
      client.send(authenticator.startAuthentication(mechanism: 'PLAIN'));

      // Wait for AUTHENTICATE +
      final authPrompt = await client.waitForCommand('AUTHENTICATE');
      expect(authPrompt.params[0], '+');
      authenticator.handleMessage(authPrompt);

      // Send credentials
      client.send(authenticator.sendCredentials(
        username: saslUser,
        password: saslPass,
      ));

      // Wait for result (900/903 or error)
      final result = await client.waitForMessage(
        (msg) {
          final num = msg.numericValue;
          return num != null &&
              (num == 900 ||
                  num == 903 ||
                  num == 902 ||
                  num == 904 ||
                  num == 905 ||
                  num == 906 ||
                  num == 907);
        },
      );

      authenticator.handleMessage(result);

      // If we got 900, wait for 903
      if (result.numericValue == 900) {
        final success = await client.waitForNumeric(903);
        authenticator.handleMessage(success);
        expect(authenticator.isAuthenticated, true);
      }

      // End CAP negotiation
      client.send(CapCommand.end());

      // Complete registration
      client.send(NickCommand(config.nick));
      client.send(UserCommand(
        username: config.user,
        realname: 'Conduit SASL Test',
      ));

      await client.waitForNumeric(IrcNumerics.rplWelcome);
    });

    test('SASL abort sends AUTHENTICATE *', () async {
      await client.connect();

      // Start CAP negotiation
      client.send(CapCommand.ls(version: 302));
      final lsResponse = await client.waitForCommand('CAP');

      final caps = CapabilityParser.parseList(lsResponse.params.last);
      if (!caps.any((c) => c.name == 'sasl')) {
        markTestSkipped('Server does not support SASL');
        return;
      }

      // Request SASL
      client.send(CapCommand.req(['sasl']));
      final ackResponse = await client.waitForMessage(
        (msg) =>
            msg.command == 'CAP' &&
            (msg.params[1] == 'ACK' || msg.params[1] == 'NAK'),
      );

      if (ackResponse.params[1] == 'NAK') {
        markTestSkipped('Server rejected SASL capability');
        return;
      }

      // Start SASL PLAIN
      final authenticator = SaslAuthenticator();
      client.send(authenticator.startAuthentication(mechanism: 'PLAIN'));

      // Wait for AUTHENTICATE +
      await client.waitForCommand('AUTHENTICATE');

      // Abort authentication
      client.send(authenticator.abort());

      // Server may send 906 ERR_SASLABORTED
      // But we don't need to wait for it

      // End CAP negotiation
      client.send(CapCommand.end());

      // Complete registration without SASL
      client.send(NickCommand(config.nick));
      client.send(UserCommand(
        username: config.user,
        realname: 'Conduit SASL Abort Test',
      ));

      await client.waitForNumeric(IrcNumerics.rplWelcome);
      expect(authenticator.state, SaslState.aborted);
    });

    test('handles unsupported mechanism gracefully', () async {
      await client.connect();

      // Start CAP negotiation
      client.send(CapCommand.ls(version: 302));
      final lsResponse = await client.waitForCommand('CAP');

      final caps = CapabilityParser.parseList(lsResponse.params.last);
      if (!caps.any((c) => c.name == 'sasl')) {
        markTestSkipped('Server does not support SASL');
        return;
      }

      // Request SASL
      client.send(CapCommand.req(['sasl']));
      final ackResponse = await client.waitForMessage(
        (msg) =>
            msg.command == 'CAP' &&
            (msg.params[1] == 'ACK' || msg.params[1] == 'NAK'),
      );

      if (ackResponse.params[1] == 'NAK') {
        markTestSkipped('Server rejected SASL capability');
        return;
      }

      // Try unsupported mechanism
      client.sendRaw('AUTHENTICATE SCRAM-SHA-256');

      // Server should respond with error or list mechanisms
      final response = await client.waitForMessage(
        (msg) {
          final num = msg.numericValue;
          // 908 RPL_SASLMECHS or 904 ERR_SASLFAIL
          return num == 908 || num == 904 || msg.command == 'AUTHENTICATE';
        },
      );

      // Either 908 with mechanisms or 904 failure is acceptable
      expect(
        response.numericValue == 908 ||
            response.numericValue == 904 ||
            response.command == 'AUTHENTICATE',
        true,
      );

      // Abort and continue
      client.sendRaw('AUTHENTICATE *');
      client.send(CapCommand.end());
      client.send(NickCommand(config.nick));
      client.send(UserCommand(
        username: config.user,
        realname: 'Conduit Mechanism Test',
      ));

      await client.waitForNumeric(IrcNumerics.rplWelcome);
    });
  });

  group('SaslAuthenticator unit integration', () {
    test('SaslAuthenticator with CapabilityNegotiator flow', () async {
      await client.connect();

      final capNegotiator = CapabilityNegotiator();
      final saslAuth = SaslAuthenticator();

      // Start CAP negotiation
      client.send(capNegotiator.startNegotiation(version: 302));

      // Handle LS response
      final lsResponse = await client.waitForCommand('CAP');
      capNegotiator.handleMessage(lsResponse);

      // Check if SASL is available
      if (!capNegotiator.available.has('sasl')) {
        markTestSkipped('Server does not support SASL');
        return;
      }

      // Request capabilities including SASL
      final toRequest = capNegotiator.filterAvailable(['sasl', 'multi-prefix']);
      client.send(capNegotiator.requestCapabilities(toRequest));

      // Handle ACK/NAK
      final ackResponse = await client.waitForMessage(
        (msg) =>
            msg.command == 'CAP' &&
            (msg.params[1] == 'ACK' || msg.params[1] == 'NAK'),
      );
      capNegotiator.handleMessage(ackResponse);

      if (!capNegotiator.isCapabilityEnabled('sasl')) {
        // End negotiation without SASL
        client.send(capNegotiator.endNegotiation());
        client.send(NickCommand(config.nick));
        client.send(UserCommand(
          username: config.user,
          realname: 'Conduit Integration Test',
        ));
        await client.waitForNumeric(IrcNumerics.rplWelcome);
        return;
      }

      // SASL is enabled, but we need credentials
      if (config.password == null) {
        // Abort SASL, end negotiation
        client.send(saslAuth.abort());
        client.send(capNegotiator.endNegotiation());
        client.send(NickCommand(config.nick));
        client.send(UserCommand(
          username: config.user,
          realname: 'Conduit Integration Test',
        ));
        await client.waitForNumeric(IrcNumerics.rplWelcome);
        return;
      }

      // Start SASL
      client.send(saslAuth.startAuthentication());
      final authPrompt = await client.waitForCommand('AUTHENTICATE');
      saslAuth.handleMessage(authPrompt);

      // Send credentials
      client.send(saslAuth.sendCredentials(
        username: config.nick,
        password: config.password!,
      ));

      // Wait for result
      final result = await client.waitForMessage((msg) {
        final num = msg.numericValue;
        return num != null && (num >= 900 && num <= 908);
      });
      saslAuth.handleMessage(result);

      if (result.numericValue == 900) {
        final success = await client.waitForNumeric(903);
        saslAuth.handleMessage(success);
      }

      // End CAP negotiation
      client.send(capNegotiator.endNegotiation());

      // Complete registration
      client.send(NickCommand(config.nick));
      client.send(UserCommand(
        username: config.user,
        realname: 'Conduit Full Flow Test',
      ));

      await client.waitForNumeric(IrcNumerics.rplWelcome);

      expect(capNegotiator.phase, CapNegotiationPhase.completed);
    });
  });
}
