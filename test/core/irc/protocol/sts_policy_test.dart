import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/protocol/sts_policy.dart';

void main() {
  group('StsPolicy', () {
    group('parsing', () {
      test('parses basic sts value', () {
        final policy = StsPolicy.parse(
          host: 'irc.example.com',
          value: 'port=6697,duration=2592000',
        );

        expect(policy.host, 'irc.example.com');
        expect(policy.port, 6697);
        expect(policy.duration, Duration(seconds: 2592000));
        expect(policy.preload, false);
      });

      test('parses sts with preload flag', () {
        final policy = StsPolicy.parse(
          host: 'irc.example.com',
          value: 'port=6697,duration=2592000,preload',
        );

        expect(policy.preload, true);
      });

      test('parses duration of 0 (disable policy)', () {
        final policy = StsPolicy.parse(
          host: 'irc.example.com',
          value: 'port=6697,duration=0',
        );

        expect(policy.duration, Duration.zero);
        expect(policy.isExpired, true);
      });

      test('handles missing port (uses default 6697)', () {
        final policy = StsPolicy.parse(
          host: 'irc.example.com',
          value: 'duration=2592000',
        );

        expect(policy.port, 6697);
      });

      test('throws on invalid value format', () {
        expect(
          () => StsPolicy.parse(host: 'irc.example.com', value: 'invalid'),
          throwsFormatException,
        );
      });

      test('throws on missing duration', () {
        expect(
          () => StsPolicy.parse(host: 'irc.example.com', value: 'port=6697'),
          throwsFormatException,
        );
      });
    });

    group('expiration', () {
      test('isExpired returns false for valid policy', () {
        final policy = StsPolicy(
          host: 'irc.example.com',
          port: 6697,
          duration: const Duration(days: 30),
          createdAt: DateTime.now(),
        );

        expect(policy.isExpired, false);
      });

      test('isExpired returns true for expired policy', () {
        final policy = StsPolicy(
          host: 'irc.example.com',
          port: 6697,
          duration: const Duration(seconds: 1),
          createdAt: DateTime.now().subtract(const Duration(seconds: 2)),
        );

        expect(policy.isExpired, true);
      });

      test('isExpired returns true for zero duration', () {
        final policy = StsPolicy(
          host: 'irc.example.com',
          port: 6697,
          duration: Duration.zero,
          createdAt: DateTime.now(),
        );

        expect(policy.isExpired, true);
      });

      test('expiresAt returns correct expiration time', () {
        final createdAt = DateTime.now();
        final policy = StsPolicy(
          host: 'irc.example.com',
          port: 6697,
          duration: const Duration(days: 30),
          createdAt: createdAt,
        );

        expect(policy.expiresAt, createdAt.add(const Duration(days: 30)));
      });
    });

    group('serialization', () {
      test('toJson creates valid JSON', () {
        final createdAt = DateTime.utc(2025, 1, 1, 12, 0, 0);
        final policy = StsPolicy(
          host: 'irc.example.com',
          port: 6697,
          duration: const Duration(days: 30),
          preload: true,
          createdAt: createdAt,
        );

        final json = policy.toJson();

        expect(json['host'], 'irc.example.com');
        expect(json['port'], 6697);
        expect(json['durationSeconds'], 30 * 24 * 60 * 60);
        expect(json['preload'], true);
        expect(json['createdAt'], createdAt.toIso8601String());
      });

      test('fromJson restores policy', () {
        final createdAt = DateTime.utc(2025, 1, 1, 12, 0, 0);
        final json = {
          'host': 'irc.example.com',
          'port': 6697,
          'durationSeconds': 2592000,
          'preload': true,
          'createdAt': createdAt.toIso8601String(),
        };

        final policy = StsPolicy.fromJson(json);

        expect(policy.host, 'irc.example.com');
        expect(policy.port, 6697);
        expect(policy.duration, const Duration(seconds: 2592000));
        expect(policy.preload, true);
        expect(policy.createdAt, createdAt);
      });
    });
  });

  group('StsPolicyStore', () {
    late StsPolicyStore store;

    setUp(() {
      store = StsPolicyStore();
    });

    group('add and get', () {
      test('stores policy for host', () {
        final policy = StsPolicy(
          host: 'irc.example.com',
          port: 6697,
          duration: const Duration(days: 30),
          createdAt: DateTime.now(),
        );

        store.add(policy);

        expect(store.get('irc.example.com'), policy);
      });

      test('returns null for unknown host', () {
        expect(store.get('unknown.com'), isNull);
      });

      test('overwrites existing policy', () {
        final policy1 = StsPolicy(
          host: 'irc.example.com',
          port: 6697,
          duration: const Duration(days: 30),
          createdAt: DateTime.now(),
        );
        final policy2 = StsPolicy(
          host: 'irc.example.com',
          port: 6697,
          duration: const Duration(days: 60),
          createdAt: DateTime.now(),
        );

        store.add(policy1);
        store.add(policy2);

        expect(store.get('irc.example.com')?.duration, const Duration(days: 60));
      });
    });

    group('hasPolicy', () {
      test('returns true for stored host', () {
        store.add(StsPolicy(
          host: 'irc.example.com',
          port: 6697,
          duration: const Duration(days: 30),
          createdAt: DateTime.now(),
        ));

        expect(store.hasPolicy('irc.example.com'), true);
      });

      test('returns false for unknown host', () {
        expect(store.hasPolicy('unknown.com'), false);
      });

      test('returns false for expired policy', () {
        store.add(StsPolicy(
          host: 'irc.example.com',
          port: 6697,
          duration: const Duration(seconds: 1),
          createdAt: DateTime.now().subtract(const Duration(seconds: 2)),
        ));

        expect(store.hasPolicy('irc.example.com'), false);
      });
    });

    group('remove', () {
      test('removes policy for host', () {
        store.add(StsPolicy(
          host: 'irc.example.com',
          port: 6697,
          duration: const Duration(days: 30),
          createdAt: DateTime.now(),
        ));

        store.remove('irc.example.com');

        expect(store.hasPolicy('irc.example.com'), false);
      });
    });

    group('clear', () {
      test('removes all policies', () {
        store.add(StsPolicy(
          host: 'irc1.example.com',
          port: 6697,
          duration: const Duration(days: 30),
          createdAt: DateTime.now(),
        ));
        store.add(StsPolicy(
          host: 'irc2.example.com',
          port: 6697,
          duration: const Duration(days: 30),
          createdAt: DateTime.now(),
        ));

        store.clear();

        expect(store.hasPolicy('irc1.example.com'), false);
        expect(store.hasPolicy('irc2.example.com'), false);
      });
    });

    group('all', () {
      test('returns all valid policies', () {
        store.add(StsPolicy(
          host: 'irc1.example.com',
          port: 6697,
          duration: const Duration(days: 30),
          createdAt: DateTime.now(),
        ));
        store.add(StsPolicy(
          host: 'irc2.example.com',
          port: 6697,
          duration: const Duration(seconds: 1),
          createdAt: DateTime.now().subtract(const Duration(seconds: 2)),
        ));

        final all = store.all;

        expect(all.length, 1);
        expect(all.first.host, 'irc1.example.com');
      });
    });

    group('cleanupExpired', () {
      test('removes expired policies', () {
        store.add(StsPolicy(
          host: 'valid.example.com',
          port: 6697,
          duration: const Duration(days: 30),
          createdAt: DateTime.now(),
        ));
        store.add(StsPolicy(
          host: 'expired.example.com',
          port: 6697,
          duration: const Duration(seconds: 1),
          createdAt: DateTime.now().subtract(const Duration(seconds: 2)),
        ));

        final removed = store.cleanupExpired();

        expect(removed, 1);
        expect(store.hasPolicy('valid.example.com'), true);
        expect(store.hasPolicy('expired.example.com'), false);
      });
    });

    group('shouldEnforceTls', () {
      test('returns true for host with valid policy', () {
        store.add(StsPolicy(
          host: 'irc.example.com',
          port: 6697,
          duration: const Duration(days: 30),
          createdAt: DateTime.now(),
        ));

        expect(store.shouldEnforceTls('irc.example.com'), true);
      });

      test('returns false for host without policy', () {
        expect(store.shouldEnforceTls('unknown.com'), false);
      });
    });

    group('getRequiredPort', () {
      test('returns port from policy', () {
        store.add(StsPolicy(
          host: 'irc.example.com',
          port: 6697,
          duration: const Duration(days: 30),
          createdAt: DateTime.now(),
        ));

        expect(store.getRequiredPort('irc.example.com'), 6697);
      });

      test('returns null for host without policy', () {
        expect(store.getRequiredPort('unknown.com'), isNull);
      });
    });

    group('serialization', () {
      test('toJson creates valid JSON list', () {
        store.add(StsPolicy(
          host: 'irc1.example.com',
          port: 6697,
          duration: const Duration(days: 30),
          createdAt: DateTime.now(),
        ));
        store.add(StsPolicy(
          host: 'irc2.example.com',
          port: 6697,
          duration: const Duration(days: 30),
          createdAt: DateTime.now(),
        ));

        final json = store.toJson();

        expect(json, isList);
        expect(json.length, 2);
      });

      test('fromJson restores all policies', () {
        final json = [
          {
            'host': 'irc1.example.com',
            'port': 6697,
            'durationSeconds': 2592000,
            'preload': false,
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            'host': 'irc2.example.com',
            'port': 6697,
            'durationSeconds': 2592000,
            'preload': false,
            'createdAt': DateTime.now().toIso8601String(),
          },
        ];

        final restored = StsPolicyStore.fromJson(json);

        expect(restored.hasPolicy('irc1.example.com'), true);
        expect(restored.hasPolicy('irc2.example.com'), true);
      });
    });
  });
}
