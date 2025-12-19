import 'package:equatable/equatable.dart';

import '../parser/capability_parser.dart';

/// IRCv3 Strict Transport Security (STS) policy.
///
/// Servers advertise STS through the `sts` capability:
/// ```
/// sts=port=6697,duration=2592000[,preload]
/// ```
///
/// Parameters:
/// - `port`: TLS port to connect to
/// - `duration`: Policy validity in seconds (0 = remove policy)
/// - `preload`: Optional flag indicating preload eligibility
///
/// See: https://ircv3.net/specs/extensions/sts
class StsPolicy extends Equatable {
  final String host;
  final int port;
  final Duration duration;
  final bool preload;
  final DateTime createdAt;

  const StsPolicy({
    required this.host,
    required this.port,
    required this.duration,
    this.preload = false,
    required this.createdAt,
  });

  /// Parses an STS capability value.
  ///
  /// Example: `port=6697,duration=2592000,preload`
  factory StsPolicy.parse({
    required String host,
    required String value,
  }) {
    final params = CapabilityParser.parseStsValue(value);

    // Duration is required
    final durationStr = params['duration'];
    if (durationStr == null) {
      throw FormatException('STS policy missing required "duration" parameter');
    }

    final durationSeconds = int.tryParse(durationStr);
    if (durationSeconds == null) {
      throw FormatException('Invalid STS duration: $durationStr');
    }

    // Port defaults to 6697
    final portStr = params['port'];
    final port = portStr != null ? int.tryParse(portStr) ?? 6697 : 6697;

    // Preload is optional flag
    final preload = params.containsKey('preload');

    return StsPolicy(
      host: host,
      port: port,
      duration: Duration(seconds: durationSeconds),
      preload: preload,
      createdAt: DateTime.now(),
    );
  }

  /// Whether this policy has expired.
  bool get isExpired {
    if (duration == Duration.zero) return true;
    return DateTime.now().isAfter(expiresAt);
  }

  /// When this policy expires.
  DateTime get expiresAt => createdAt.add(duration);

  /// Converts to JSON for persistence.
  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'durationSeconds': duration.inSeconds,
        'preload': preload,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Creates from JSON.
  factory StsPolicy.fromJson(Map<String, dynamic> json) => StsPolicy(
        host: json['host'] as String,
        port: json['port'] as int,
        duration: Duration(seconds: json['durationSeconds'] as int),
        preload: json['preload'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  List<Object?> get props => [host, port, duration, preload, createdAt];

  @override
  String toString() =>
      'StsPolicy($host, port=$port, duration=${duration.inSeconds}s, preload=$preload)';
}

/// Store for STS policies.
///
/// Manages policy storage, expiration, and enforcement.
class StsPolicyStore {
  final Map<String, StsPolicy> _policies = {};

  StsPolicyStore();

  /// Creates from JSON list.
  factory StsPolicyStore.fromJson(List<dynamic> json) {
    final store = StsPolicyStore();
    for (final item in json) {
      try {
        final policy = StsPolicy.fromJson(item as Map<String, dynamic>);
        store.add(policy);
      } catch (_) {
        // Skip invalid entries
      }
    }
    return store;
  }

  /// Adds or updates a policy.
  void add(StsPolicy policy) {
    _policies[policy.host.toLowerCase()] = policy;
  }

  /// Gets policy for host, or null if none or expired.
  StsPolicy? get(String host) {
    final policy = _policies[host.toLowerCase()];
    if (policy == null || policy.isExpired) {
      return null;
    }
    return policy;
  }

  /// Whether there's a valid (non-expired) policy for host.
  bool hasPolicy(String host) => get(host) != null;

  /// Removes policy for host.
  void remove(String host) {
    _policies.remove(host.toLowerCase());
  }

  /// Clears all policies.
  void clear() {
    _policies.clear();
  }

  /// Gets all non-expired policies.
  List<StsPolicy> get all =>
      _policies.values.where((p) => !p.isExpired).toList();

  /// Removes expired policies.
  ///
  /// Returns number of policies removed.
  int cleanupExpired() {
    final expired =
        _policies.entries.where((e) => e.value.isExpired).map((e) => e.key).toList();
    for (final host in expired) {
      _policies.remove(host);
    }
    return expired.length;
  }

  /// Whether TLS should be enforced for host.
  bool shouldEnforceTls(String host) => hasPolicy(host);

  /// Gets the required TLS port for host, or null if no policy.
  int? getRequiredPort(String host) => get(host)?.port;

  /// Converts all valid policies to JSON.
  List<Map<String, dynamic>> toJson() =>
      all.map((p) => p.toJson()).toList();
}
