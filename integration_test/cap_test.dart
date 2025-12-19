import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/irc.dart';
import 'package:conduit/core/constants/irc_numerics.dart';

import 'config/test_config.dart';
import 'helpers/irc_test_client.dart';
import 'helpers/irc_matchers.dart';

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

  group('CAP Negotiation', () {
    test('server responds to CAP LS', () async {
      await client.connect();

      // Send CAP LS 302
      client.send(CapCommand.ls(version: 302));

      // Wait for CAP LS response
      final response = await client.waitForCommand('CAP');

      expect(response, isCommand('CAP'));
      expect(response.params.length, greaterThanOrEqualTo(3));
      expect(response.params[1], 'LS');
    });

    test('server acknowledges capability request', () async {
      await client.connect();

      // Start CAP negotiation
      client.send(CapCommand.ls(version: 302));
      final lsResponse = await client.waitForCommand('CAP');

      // Parse available capabilities
      final caps = CapabilityParser.parseList(lsResponse.params.last);
      final availableCaps = caps.map((c) => c.name).toList();

      // Find a capability we can request (prefer multi-prefix as it's common)
      String? capToRequest;
      for (final preferred in ['multi-prefix', 'server-time', 'away-notify']) {
        if (availableCaps.contains(preferred)) {
          capToRequest = preferred;
          break;
        }
      }

      if (capToRequest == null) {
        // Skip if no common capability available
        markTestSkipped('No common capability available to test');
        return;
      }

      // Request the capability
      client.send(CapCommand.req([capToRequest]));

      // Wait for ACK or NAK
      final ackResponse = await client.waitForMessage(
        (msg) =>
            msg.command == 'CAP' &&
            (msg.params[1] == 'ACK' || msg.params[1] == 'NAK'),
      );

      expect(ackResponse.params[1], anyOf('ACK', 'NAK'));
    });

    test('CAP END completes negotiation', () async {
      await client.connect();

      // Start and end CAP negotiation immediately
      client.send(CapCommand.ls(version: 302));
      await client.waitForCommand('CAP');

      // End negotiation
      client.send(CapCommand.end());

      // Now complete registration
      client.send(NickCommand(config.nick));
      client.send(UserCommand(
        username: config.user,
        realname: 'Conduit CAP Test',
      ));

      // Should receive welcome message
      final welcome = await client.waitForNumeric(IrcNumerics.rplWelcome);
      expect(welcome, isNumeric(IrcNumerics.rplWelcome));
    });

    test('full CAP negotiation flow with CapabilityNegotiator', () async {
      await client.connect();

      final negotiator = CapabilityNegotiator();

      // Start negotiation
      final lsCmd = negotiator.startNegotiation(version: 302);
      client.send(lsCmd);

      // Handle multi-line LS if needed
      IrcMessage lsResponse;
      do {
        lsResponse = await client.waitForMessage(
          (msg) => msg.command == 'CAP' && msg.params[1] == 'LS',
        );
        negotiator.handleMessage(lsResponse);
      } while (negotiator.isMultiLineInProgress);

      // Filter desired capabilities
      final desired = [
        'multi-prefix',
        'server-time',
        'away-notify',
        'cap-notify',
      ];
      final toRequest = negotiator.filterAvailable(desired);

      if (toRequest.isNotEmpty) {
        // Request capabilities
        final reqCmd = negotiator.requestCapabilities(toRequest);
        client.send(reqCmd);

        // Wait for ACK/NAK
        final ackResponse = await client.waitForMessage(
          (msg) =>
              msg.command == 'CAP' &&
              (msg.params[1] == 'ACK' || msg.params[1] == 'NAK'),
        );
        negotiator.handleMessage(ackResponse);
      }

      // End negotiation
      final endCmd = negotiator.endNegotiation();
      client.send(endCmd);

      // Complete registration
      client.send(NickCommand(config.nick));
      client.send(UserCommand(
        username: config.user,
        realname: 'Conduit Negotiator Test',
      ));

      // Verify welcome
      await client.waitForNumeric(IrcNumerics.rplWelcome);

      expect(negotiator.phase, CapNegotiationPhase.completed);
      expect(negotiator.available.isNotEmpty, true);
    });

    test('CAP LIST returns enabled capabilities', () async {
      await client.connect();

      // Negotiate capabilities first
      client.send(CapCommand.ls(version: 302));
      final lsResponse = await client.waitForCommand('CAP');

      // Parse and request a capability
      final caps = CapabilityParser.parseList(lsResponse.params.last);
      final availableCaps = caps.map((c) => c.name).toList();

      String? capToRequest;
      for (final preferred in ['multi-prefix', 'server-time']) {
        if (availableCaps.contains(preferred)) {
          capToRequest = preferred;
          break;
        }
      }

      if (capToRequest != null) {
        client.send(CapCommand.req([capToRequest]));
        await client.waitForMessage(
          (msg) =>
              msg.command == 'CAP' &&
              (msg.params[1] == 'ACK' || msg.params[1] == 'NAK'),
        );
      }

      // End negotiation and register
      client.send(CapCommand.end());
      client.send(NickCommand(config.nick));
      client.send(UserCommand(
        username: config.user,
        realname: 'Conduit LIST Test',
      ));
      await client.waitForNumeric(IrcNumerics.rplWelcome);

      // Clear messages and request CAP LIST
      client.clearMessages();
      client.send(CapCommand.list());

      // Should receive LIST response
      final listResponse = await client.waitForMessage(
        (msg) => msg.command == 'CAP' && msg.params[1] == 'LIST',
      );

      expect(listResponse, isCommand('CAP'));
      expect(listResponse.params[1], 'LIST');
    });
  });

  group('CAP 302 Enhanced', () {
    test('server sends capability values', () async {
      await client.connect();

      client.send(CapCommand.ls(version: 302));
      final response = await client.waitForCommand('CAP');

      final caps = CapabilityParser.parseList(response.params.last);

      // Check if any capability has a value (e.g., sasl=PLAIN,EXTERNAL)
      final capsWithValues = caps.where((c) => c.value != null).toList();

      // This is informational - some servers may not have caps with values
      if (capsWithValues.isNotEmpty) {
        for (final cap in capsWithValues) {
          expect(cap.value, isNotNull);
          expect(cap.value, isNotEmpty);
        }
      }
    });
  });
}
