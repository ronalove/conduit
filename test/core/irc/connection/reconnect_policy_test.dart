import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/connection/reconnect_policy.dart';

void main() {
  group('ExponentialBackoffPolicy', () {
    group('getNextDelay', () {
      test('returns initial delay for first attempt', () {
        const policy = ExponentialBackoffPolicy(
          initialDelay: Duration(seconds: 1),
        );
        expect(policy.getNextDelay(0), const Duration(seconds: 1));
      });

      test('doubles delay for each attempt', () {
        const policy = ExponentialBackoffPolicy(
          initialDelay: Duration(seconds: 1),
          multiplier: 2.0,
        );
        expect(policy.getNextDelay(0), const Duration(seconds: 1));
        expect(policy.getNextDelay(1), const Duration(seconds: 2));
        expect(policy.getNextDelay(2), const Duration(seconds: 4));
        expect(policy.getNextDelay(3), const Duration(seconds: 8));
      });

      test('respects max delay', () {
        const policy = ExponentialBackoffPolicy(
          initialDelay: Duration(seconds: 1),
          maxDelay: Duration(seconds: 10),
          multiplier: 2.0,
        );
        expect(policy.getNextDelay(0), const Duration(seconds: 1));
        expect(policy.getNextDelay(3), const Duration(seconds: 8));
        expect(policy.getNextDelay(4), const Duration(seconds: 10)); // Capped
        expect(policy.getNextDelay(10), const Duration(seconds: 10)); // Still capped
      });

      test('uses custom multiplier', () {
        const policy = ExponentialBackoffPolicy(
          initialDelay: Duration(seconds: 1),
          multiplier: 1.5,
        );
        expect(policy.getNextDelay(0), const Duration(seconds: 1));
        expect(policy.getNextDelay(1), const Duration(milliseconds: 1500));
        expect(policy.getNextDelay(2), const Duration(milliseconds: 2250));
      });
    });

    group('shouldReconnect', () {
      test('returns true within max attempts', () {
        const policy = ExponentialBackoffPolicy(maxAttempts: 5);
        expect(policy.shouldReconnect(0, null), isTrue);
        expect(policy.shouldReconnect(4, null), isTrue);
      });

      test('returns false at max attempts', () {
        const policy = ExponentialBackoffPolicy(maxAttempts: 5);
        expect(policy.shouldReconnect(5, null), isFalse);
        expect(policy.shouldReconnect(10, null), isFalse);
      });

      test('returns true with error within max attempts', () {
        const policy = ExponentialBackoffPolicy(maxAttempts: 5);
        expect(policy.shouldReconnect(3, Exception('test')), isTrue);
      });

      test('unlimited attempts when maxAttempts is 0', () {
        const policy = ExponentialBackoffPolicy(maxAttempts: 0);
        expect(policy.shouldReconnect(100, null), isTrue);
        expect(policy.shouldReconnect(1000, null), isTrue);
      });
    });

    group('reset', () {
      test('can be called without error', () {
        final policy = ExponentialBackoffPolicy();
        expect(() => policy.reset(), returnsNormally);
      });
    });

    group('default values', () {
      test('has sensible defaults', () {
        const policy = ExponentialBackoffPolicy();
        // Initial delay should be 1 second
        expect(policy.getNextDelay(0), const Duration(seconds: 1));
        // Max delay should be 2 minutes
        expect(
          policy.getNextDelay(100),
          lessThanOrEqualTo(const Duration(minutes: 2)),
        );
        // Should allow at least 10 attempts by default
        expect(policy.shouldReconnect(9, null), isTrue);
      });
    });
  });

  group('NoReconnectPolicy', () {
    test('never allows reconnection', () {
      const policy = NoReconnectPolicy();
      expect(policy.shouldReconnect(0, null), isFalse);
      expect(policy.shouldReconnect(1, null), isFalse);
    });

    test('returns zero delay', () {
      const policy = NoReconnectPolicy();
      expect(policy.getNextDelay(0), Duration.zero);
    });
  });
}
