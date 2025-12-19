import 'dart:async';

import 'package:conduit/core/irc/irc.dart';
import 'package:conduit/core/constants/irc_numerics.dart';

import '../config/test_config.dart';

class IrcTestClient {
  final TestConfig config;
  late final SecureSocketManager _socket;
  final List<IrcMessage> _messages = [];
  StreamSubscription<String>? _lineSubscription;

  IrcTestClient(this.config) {
    _socket = SecureSocketManager();
  }

  List<IrcMessage> get messages => List.unmodifiable(_messages);

  Stream<String> get lines => _socket.lines;
  Stream<ConnectionEvent> get events => _socket.events;
  ConnectionStatus get status => _socket.status;

  Future<void> connect() async {
    final connectionConfig = ConnectionConfig(
      host: config.host,
      port: config.port,
      allowInvalidCerts: config.allowInvalidCerts,
      password: config.password,
    );

    await _socket.connect(connectionConfig);

    _lineSubscription = _socket.lines.listen((line) {
      final msg = IrcParser.parse(line);
      _messages.add(msg);
    });
  }

  Future<void> disconnect() async {
    await _lineSubscription?.cancel();
    await _socket.disconnect();
  }

  void dispose() {
    _socket.dispose();
  }

  void send(IrcCommand command) {
    _socket.send(command.toRaw());
  }

  void sendRaw(String line) {
    if (!line.endsWith('\r\n')) {
      line = '$line\r\n';
    }
    _socket.send(line);
  }

  Future<IrcMessage> waitForMessage(
    bool Function(IrcMessage) predicate, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final completer = Completer<IrcMessage>();

    // Check existing messages
    for (final msg in _messages) {
      if (predicate(msg)) {
        return msg;
      }
    }

    // Listen for new messages
    late StreamSubscription<String> subscription;
    subscription = _socket.lines.listen((line) {
      final msg = IrcParser.parse(line);
      if (predicate(msg) && !completer.isCompleted) {
        subscription.cancel();
        completer.complete(msg);
      }
    });

    return completer.future.timeout(timeout, onTimeout: () {
      subscription.cancel();
      throw TimeoutException('Timed out waiting for message', timeout);
    });
  }

  Future<IrcMessage> waitForNumeric(
    int numeric, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    return waitForMessage(
      (msg) => msg.numericValue == numeric,
      timeout: timeout,
    );
  }

  Future<IrcMessage> waitForCommand(
    String command, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    return waitForMessage(
      (msg) => msg.command.toUpperCase() == command.toUpperCase(),
      timeout: timeout,
    );
  }

  Future<void> register({String? nick, String? user, String? realname}) async {
    send(NickCommand(nick ?? config.nick));
    send(UserCommand(
      username: user ?? config.user,
      realname: realname ?? 'Conduit Test Client',
    ));

    await waitForNumeric(IrcNumerics.rplWelcome);
  }

  Future<void> connectAndRegister() async {
    await connect();
    await register();
  }

  void clearMessages() {
    _messages.clear();
  }
}
