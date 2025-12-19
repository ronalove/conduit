import 'package:equatable/equatable.dart';

/// Represents an IRCv3 capability.
class Capability extends Equatable {
  final String name;
  final String? value;
  final bool isDisabled;
  final bool isSticky;
  final bool isAck;

  const Capability({
    required this.name,
    this.value,
    this.isDisabled = false,
    this.isSticky = false,
    this.isAck = false,
  });

  @override
  List<Object?> get props => [name];

  @override
  String toString() {
    final buffer = StringBuffer('Capability($name');
    if (value != null) buffer.write('=$value');
    if (isDisabled) buffer.write(', disabled');
    if (isSticky) buffer.write(', sticky');
    if (isAck) buffer.write(', ack');
    buffer.write(')');
    return buffer.toString();
  }
}

/// A mutable set of capabilities.
class CapabilitySet {
  final Map<String, Capability> _capabilities = {};

  void add(Capability cap) {
    _capabilities[cap.name] = cap;
  }

  void addAll(Iterable<Capability> caps) {
    for (final cap in caps) {
      add(cap);
    }
  }

  void remove(String name) {
    _capabilities.remove(name);
  }

  bool has(String name) => _capabilities.containsKey(name);

  Capability? get(String name) => _capabilities[name];

  Iterable<String> get names => _capabilities.keys;

  Iterable<Capability> get all => _capabilities.values;

  void clear() {
    _capabilities.clear();
  }

  int get length => _capabilities.length;

  bool get isEmpty => _capabilities.isEmpty;

  bool get isNotEmpty => _capabilities.isNotEmpty;
}

/// Parser for IRCv3 capabilities.
///
/// Handles CAP 302 format with values and modifiers.
/// See: https://ircv3.net/specs/extensions/capability-negotiation
abstract class CapabilityParser {
  /// Parses a single capability string.
  ///
  /// Format: `[modifier]name[=value]`
  /// Modifiers:
  /// - `-` : Capability is being disabled
  /// - `=` : Capability is sticky (302)
  /// - `~` : Capability requires ACK (302)
  static Capability parseCapability(String raw) {
    var remaining = raw;
    var isDisabled = false;
    var isSticky = false;
    var isAck = false;

    // Parse modifier
    if (remaining.startsWith('-')) {
      isDisabled = true;
      remaining = remaining.substring(1);
    } else if (remaining.startsWith('=')) {
      isSticky = true;
      remaining = remaining.substring(1);
    } else if (remaining.startsWith('~')) {
      isAck = true;
      remaining = remaining.substring(1);
    }

    // Parse name and value
    final equalsIndex = remaining.indexOf('=');
    String name;
    String? value;

    if (equalsIndex != -1) {
      name = remaining.substring(0, equalsIndex);
      value = remaining.substring(equalsIndex + 1);
    } else {
      name = remaining;
    }

    return Capability(
      name: name,
      value: value,
      isDisabled: isDisabled,
      isSticky: isSticky,
      isAck: isAck,
    );
  }

  /// Parses a space-separated list of capabilities.
  ///
  /// Used for CAP LS, CAP LIST, CAP REQ, CAP ACK responses.
  static List<Capability> parseList(String raw) {
    if (raw.trim().isEmpty) return [];

    return raw
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .map(parseCapability)
        .toList();
  }

  /// Parses STS (Strict Transport Security) value.
  ///
  /// Format: `key=value,key=value,flag`
  /// Example: `port=6697,duration=2592000,preload`
  static Map<String, String?> parseStsValue(String value) {
    if (value.isEmpty) return {};

    final result = <String, String?>{};
    final parts = value.split(',');

    for (final part in parts) {
      final equalsIndex = part.indexOf('=');
      if (equalsIndex != -1) {
        result[part.substring(0, equalsIndex)] = part.substring(equalsIndex + 1);
      } else {
        result[part] = null;
      }
    }

    return result;
  }

  /// Parses SASL mechanisms from capability value.
  ///
  /// Format: `PLAIN,EXTERNAL,SCRAM-SHA-256`
  static List<String> parseSaslMechanisms(String value) {
    if (value.isEmpty) return [];
    return value.split(',');
  }
}
