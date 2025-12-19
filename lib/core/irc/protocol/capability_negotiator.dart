import 'dart:async';

import '../commands/capability_commands.dart';
import '../parser/capability_parser.dart';
import '../parser/irc_message.dart';

/// Phase of capability negotiation.
enum CapNegotiationPhase {
  /// Not started yet.
  idle,

  /// Negotiation in progress.
  negotiating,

  /// Negotiation completed (CAP END sent).
  completed,
}

/// Result type from handling a CAP message.
enum CapResultType {
  /// CAP LS response (continuing, more lines expected).
  lsContinuing,

  /// CAP LS response complete.
  lsComplete,

  /// CAP ACK - capabilities acknowledged.
  ack,

  /// CAP NAK - capabilities rejected.
  nak,

  /// CAP NEW - new capabilities available (cap-notify).
  newCaps,

  /// CAP DEL - capabilities removed (cap-notify).
  delCaps,

  /// CAP LIST response.
  list,

  /// Unknown or unhandled CAP subcommand.
  unknown,
}

/// Result of handling a CAP message.
class CapResult {
  final CapResultType type;
  final List<String> capabilities;

  const CapResult(this.type, [this.capabilities = const []]);
}

/// Manages IRCv3 capability negotiation.
///
/// Handles the CAP LS / REQ / ACK / NAK / END flow,
/// as well as cap-notify (CAP NEW / DEL).
///
/// See: https://ircv3.net/specs/extensions/capability-negotiation
class CapabilityNegotiator {
  CapNegotiationPhase _phase = CapNegotiationPhase.idle;

  final CapabilitySet _available = CapabilitySet();
  final CapabilitySet _requested = CapabilitySet();
  final CapabilitySet _enabled = CapabilitySet();

  bool _multiLineInProgress = false;
  bool _supportsVersion302 = false;

  final StreamController<CapNegotiationPhase> _phaseController =
      StreamController<CapNegotiationPhase>.broadcast();

  /// Current negotiation phase.
  CapNegotiationPhase get phase => _phase;

  /// Stream of phase changes.
  Stream<CapNegotiationPhase> get phases => _phaseController.stream;

  /// Whether a multi-line CAP LS response is in progress.
  bool get isMultiLineInProgress => _multiLineInProgress;

  /// Capabilities advertised by the server.
  CapabilitySet get available => _available;

  /// Capabilities we have requested.
  CapabilitySet get requested => _requested;

  /// Capabilities currently enabled.
  CapabilitySet get enabled => _enabled;

  /// Whether the server supports CAP 302 (values in LS).
  bool get supportsCapVersion302 => _supportsVersion302;

  /// Starts capability negotiation.
  ///
  /// Returns CAP LS command to send.
  /// Use version 302 for enhanced format with values.
  CapCommand startNegotiation({int? version = 302}) {
    _setPhase(CapNegotiationPhase.negotiating);
    return CapCommand.ls(version: version);
  }

  /// Handles an incoming CAP message from the server.
  CapResult handleMessage(IrcMessage message) {
    if (message.command != 'CAP') {
      return const CapResult(CapResultType.unknown);
    }

    // CAP format: CAP <target> <subcommand> [*] :<capabilities>
    // params[0] = target (usually * or nick)
    // params[1] = subcommand (LS, ACK, NAK, NEW, DEL, LIST)
    // params[2] = * (continuation) or capabilities
    // params[3] = capabilities (if params[2] was *)

    if (message.params.length < 2) {
      return const CapResult(CapResultType.unknown);
    }

    final subcommand = message.params[1].toUpperCase();

    switch (subcommand) {
      case 'LS':
        return _handleLs(message);
      case 'ACK':
        return _handleAck(message);
      case 'NAK':
        return _handleNak(message);
      case 'NEW':
        return _handleNew(message);
      case 'DEL':
        return _handleDel(message);
      case 'LIST':
        return _handleList(message);
      default:
        return const CapResult(CapResultType.unknown);
    }
  }

  CapResult _handleLs(IrcMessage message) {
    // Check for multi-line continuation
    // CAP * LS * :caps...   (more coming)
    // CAP * LS :caps...     (final line)
    bool isContinuation = false;
    String capList;

    if (message.params.length >= 4 && message.params[2] == '*') {
      // Multi-line, more coming
      isContinuation = true;
      _multiLineInProgress = true;
      capList = message.params[3];
    } else if (message.params.length >= 3) {
      // Single line or final line of multi-line
      capList = message.params[2];
      _multiLineInProgress = false;
    } else {
      return const CapResult(CapResultType.unknown);
    }

    final caps = CapabilityParser.parseList(capList);
    _available.addAll(caps);

    // Detect CAP 302 by presence of capability values
    if (caps.any((c) => c.value != null)) {
      _supportsVersion302 = true;
    }

    if (isContinuation) {
      return const CapResult(CapResultType.lsContinuing);
    }

    return CapResult(
      CapResultType.lsComplete,
      _available.names.toList(),
    );
  }

  CapResult _handleAck(IrcMessage message) {
    if (message.params.length < 3) {
      return const CapResult(CapResultType.unknown);
    }

    final capList = message.params[2];
    final caps = CapabilityParser.parseList(capList);

    for (final cap in caps) {
      if (cap.isDisabled) {
        // Capability was disabled
        _enabled.remove(cap.name);
      } else {
        // Capability was enabled
        _enabled.add(cap);
      }
    }

    return CapResult(CapResultType.ack, caps.map((c) => c.name).toList());
  }

  CapResult _handleNak(IrcMessage message) {
    if (message.params.length < 3) {
      return const CapResult(CapResultType.unknown);
    }

    final capList = message.params[2];
    final caps = CapabilityParser.parseList(capList);

    // Remove from requested (they were rejected)
    for (final cap in caps) {
      _requested.remove(cap.name);
    }

    return CapResult(CapResultType.nak, caps.map((c) => c.name).toList());
  }

  CapResult _handleNew(IrcMessage message) {
    if (message.params.length < 3) {
      return const CapResult(CapResultType.unknown);
    }

    final capList = message.params[2];
    final caps = CapabilityParser.parseList(capList);
    _available.addAll(caps);

    return CapResult(CapResultType.newCaps, caps.map((c) => c.name).toList());
  }

  CapResult _handleDel(IrcMessage message) {
    if (message.params.length < 3) {
      return const CapResult(CapResultType.unknown);
    }

    final capList = message.params[2];
    final caps = CapabilityParser.parseList(capList);

    for (final cap in caps) {
      _available.remove(cap.name);
      _enabled.remove(cap.name);
    }

    return CapResult(CapResultType.delCaps, caps.map((c) => c.name).toList());
  }

  CapResult _handleList(IrcMessage message) {
    if (message.params.length < 3) {
      return const CapResult(CapResultType.unknown);
    }

    final capList = message.params[2];
    final caps = CapabilityParser.parseList(capList);

    return CapResult(CapResultType.list, caps.map((c) => c.name).toList());
  }

  /// Requests the specified capabilities.
  ///
  /// Returns CAP REQ command to send.
  CapCommand requestCapabilities(List<String> capabilities) {
    for (final cap in capabilities) {
      _requested.add(Capability(name: cap));
    }
    return CapCommand.req(capabilities);
  }

  /// Ends capability negotiation.
  ///
  /// Returns CAP END command to send.
  CapCommand endNegotiation() {
    _setPhase(CapNegotiationPhase.completed);
    return CapCommand.end();
  }

  /// Filters a list of desired capabilities against available ones.
  ///
  /// Returns only capabilities that are both desired AND available.
  List<String> filterAvailable(List<String> desired) {
    return desired.where((cap) => _available.has(cap)).toList();
  }

  /// Checks if a capability is currently enabled.
  bool isCapabilityEnabled(String name) => _enabled.has(name);

  /// Resets the negotiator to initial state.
  void reset() {
    _phase = CapNegotiationPhase.idle;
    _available.clear();
    _requested.clear();
    _enabled.clear();
    _multiLineInProgress = false;
    _supportsVersion302 = false;
  }

  /// Disposes resources.
  void dispose() {
    _phaseController.close();
  }

  void _setPhase(CapNegotiationPhase newPhase) {
    if (newPhase != _phase) {
      _phase = newPhase;
      _phaseController.add(_phase);
    }
  }
}
