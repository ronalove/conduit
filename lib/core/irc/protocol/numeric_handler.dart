import '../parser/irc_message.dart';

/// Callback type for numeric reply handlers.
typedef NumericCallback = void Function(IrcMessage message);

/// Dispatches IRC numeric replies to registered handlers.
///
/// Numerics are 3-digit command codes like 001 (welcome), 353 (names), etc.
class NumericHandler {
  final Map<int, List<NumericCallback>> _handlers = {};
  final NumericCallback? _defaultHandler;

  /// Creates a numeric handler.
  ///
  /// The optional [defaultHandler] is called for numerics without registered handlers.
  NumericHandler({NumericCallback? defaultHandler})
      : _defaultHandler = defaultHandler;

  /// Handles an IRC message if it's a numeric reply.
  ///
  /// Returns true if the message was a numeric and was handled.
  bool handle(IrcMessage message) {
    final numeric = int.tryParse(message.command);
    if (numeric == null) return false;

    final callbacks = _handlers[numeric];
    if (callbacks != null && callbacks.isNotEmpty) {
      for (final callback in callbacks) {
        callback(message);
      }
      return true;
    }

    if (_defaultHandler case final handler?) {
      handler(message);
      return true;
    }

    return false;
  }

  /// Registers a handler for a specific numeric.
  ///
  /// Multiple handlers can be registered for the same numeric.
  /// They will be called in registration order.
  void registerHandler(int numeric, NumericCallback callback) {
    _handlers.putIfAbsent(numeric, () => []).add(callback);
  }

  /// Registers multiple handlers at once.
  void registerHandlers(Map<int, NumericCallback> handlers) {
    handlers.forEach(registerHandler);
  }

  /// Removes a specific handler for a numeric.
  void removeHandler(int numeric, NumericCallback callback) {
    _handlers[numeric]?.remove(callback);
  }

  /// Removes all handlers for a specific numeric.
  void clearHandlers(int numeric) {
    _handlers.remove(numeric);
  }

  /// Removes all registered handlers.
  void clearAllHandlers() {
    _handlers.clear();
  }
}
