import 'dart:math';

/// Policy for reconnection attempts.
abstract class ReconnectPolicy {
  /// Returns the delay before the next reconnection attempt.
  Duration getNextDelay(int attempt);

  /// Whether to attempt reconnection.
  bool shouldReconnect(int attempt, Object? error);

  /// Resets the policy state.
  void reset();
}

/// Exponential backoff reconnection policy.
///
/// Delays increase exponentially with each attempt, up to a maximum.
class ExponentialBackoffPolicy implements ReconnectPolicy {
  final Duration initialDelay;
  final Duration maxDelay;
  final int maxAttempts;
  final double multiplier;

  const ExponentialBackoffPolicy({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 2),
    this.maxAttempts = 10,
    this.multiplier = 2.0,
  });

  @override
  Duration getNextDelay(int attempt) {
    final delayMs = initialDelay.inMicroseconds * pow(multiplier, attempt);
    final cappedMs = min(delayMs.toInt(), maxDelay.inMicroseconds);
    return Duration(microseconds: cappedMs);
  }

  @override
  bool shouldReconnect(int attempt, Object? error) {
    // maxAttempts of 0 means unlimited
    if (maxAttempts == 0) return true;
    return attempt < maxAttempts;
  }

  @override
  void reset() {
    // Stateless policy, nothing to reset
  }
}

/// Policy that never reconnects.
class NoReconnectPolicy implements ReconnectPolicy {
  const NoReconnectPolicy();

  @override
  Duration getNextDelay(int attempt) => Duration.zero;

  @override
  bool shouldReconnect(int attempt, Object? error) => false;

  @override
  void reset() {}
}
