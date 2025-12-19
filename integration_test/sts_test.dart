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

  group('STS Detection', () {
    test('detects sts capability in CAP LS', () async {
      await client.connect();

      client.send(CapCommand.ls(version: 302));
      final response = await client.waitForCommand('CAP');

      final caps = CapabilityParser.parseList(response.params.last);
      final stsCap = caps.where((c) => c.name == 'sts').firstOrNull;

      if (stsCap == null) {
        markTestSkipped('Server does not advertise STS');
        return;
      }

      expect(stsCap.name, 'sts');
      expect(stsCap.value, isNotNull);

      // Parse STS value
      final policy = StsPolicy.parse(
        host: config.host,
        value: stsCap.value!,
      );

      expect(policy.port, isA<int>());
      expect(policy.duration.inSeconds, isA<int>());
    });

    test('STS policy parsing from real server', () async {
      await client.connect();

      client.send(CapCommand.ls(version: 302));
      final response = await client.waitForCommand('CAP');

      final caps = CapabilityParser.parseList(response.params.last);
      final stsCap = caps.where((c) => c.name == 'sts').firstOrNull;

      if (stsCap == null) {
        markTestSkipped('Server does not advertise STS');
        return;
      }

      final policy = StsPolicy.parse(
        host: config.host,
        value: stsCap.value!,
      );

      // Verify policy is valid
      expect(policy.host, config.host);
      expect(policy.isExpired, false);

      // Store in policy store
      final store = StsPolicyStore();
      store.add(policy);

      expect(store.hasPolicy(config.host), true);
      expect(store.shouldEnforceTls(config.host), true);
      expect(store.getRequiredPort(config.host), policy.port);
    });
  });

  group('STS Policy Store', () {
    test('stores and retrieves STS policy', () async {
      final store = StsPolicyStore();

      // Create a policy manually
      final policy = StsPolicy(
        host: config.host,
        port: 6697,
        duration: const Duration(days: 30),
        createdAt: DateTime.now(),
      );

      store.add(policy);

      expect(store.hasPolicy(config.host), true);
      expect(store.get(config.host), isNotNull);
      expect(store.getRequiredPort(config.host), 6697);
    });

    test('policy expiration handling', () async {
      final store = StsPolicyStore();

      // Add an expired policy
      store.add(StsPolicy(
        host: 'expired.example.com',
        port: 6697,
        duration: const Duration(seconds: 1),
        createdAt: DateTime.now().subtract(const Duration(seconds: 2)),
      ));

      // Add a valid policy
      store.add(StsPolicy(
        host: 'valid.example.com',
        port: 6697,
        duration: const Duration(days: 30),
        createdAt: DateTime.now(),
      ));

      expect(store.hasPolicy('expired.example.com'), false);
      expect(store.hasPolicy('valid.example.com'), true);

      final removed = store.cleanupExpired();
      expect(removed, 1);
    });

    test('policy serialization round-trip', () async {
      final store = StsPolicyStore();

      store.add(StsPolicy(
        host: config.host,
        port: 6697,
        duration: const Duration(days: 30),
        preload: true,
        createdAt: DateTime.now(),
      ));

      // Serialize and restore
      final json = store.toJson();
      final restored = StsPolicyStore.fromJson(json);

      expect(restored.hasPolicy(config.host), true);
      final policy = restored.get(config.host);
      expect(policy?.preload, true);
    });
  });

  group('STS with CAP negotiation', () {
    test('extracts STS from CAP negotiation flow', () async {
      await client.connect();

      final capNegotiator = CapabilityNegotiator();
      final stsStore = StsPolicyStore();

      // Start CAP negotiation
      client.send(capNegotiator.startNegotiation(version: 302));

      // Handle LS response
      final lsResponse = await client.waitForCommand('CAP');
      capNegotiator.handleMessage(lsResponse);

      // Check for STS in available capabilities
      final stsCap = capNegotiator.available.get('sts');

      if (stsCap != null && stsCap.value != null) {
        // Parse and store STS policy
        try {
          final policy = StsPolicy.parse(
            host: config.host,
            value: stsCap.value!,
          );
          stsStore.add(policy);

          expect(stsStore.shouldEnforceTls(config.host), true);
        } catch (e) {
          // Server sent invalid STS value
          fail('Invalid STS value: ${stsCap.value}');
        }
      }

      // Complete connection regardless of STS support
      client.send(capNegotiator.endNegotiation());
      client.send(NickCommand(config.nick));
      client.send(UserCommand(
        username: config.user,
        realname: 'Conduit STS Test',
      ));

      await client.waitForNumeric(IrcNumerics.rplWelcome);
    });
  });

  group('STS zero duration', () {
    test('duration 0 removes policy', () async {
      final store = StsPolicyStore();

      // Add initial policy
      store.add(StsPolicy(
        host: config.host,
        port: 6697,
        duration: const Duration(days: 30),
        createdAt: DateTime.now(),
      ));

      expect(store.hasPolicy(config.host), true);

      // Server sends duration=0 to remove policy
      final removePolicy = StsPolicy.parse(
        host: config.host,
        value: 'port=6697,duration=0',
      );

      // Policy with duration 0 is immediately expired
      expect(removePolicy.isExpired, true);

      // Update store with expired policy
      store.add(removePolicy);

      // Should no longer enforce TLS
      expect(store.hasPolicy(config.host), false);
    });
  });
}
