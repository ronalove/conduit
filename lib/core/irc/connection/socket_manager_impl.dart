import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'connection_config.dart';
import 'line_buffer.dart';
import 'socket_manager.dart';

/// SecureSocket implementation of [SocketManager].
///
/// Uses TLS for all connections.
class SecureSocketManager implements SocketManager {
  SecureSocket? _socket;
  final LineBuffer _lineBuffer = LineBuffer();
  final StreamController<String> _linesController =
      StreamController<String>.broadcast();
  final StreamController<ConnectionEvent> _eventsController =
      StreamController<ConnectionEvent>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  StreamSubscription<List<int>>? _dataSubscription;

  @override
  Stream<String> get lines => _linesController.stream;

  @override
  Stream<ConnectionEvent> get events => _eventsController.stream;

  @override
  ConnectionStatus get status => _status;

  @override
  Future<void> connect(ConnectionConfig config) async {
    if (_status == ConnectionStatus.connecting ||
        _status == ConnectionStatus.connected) {
      return;
    }

    _status = ConnectionStatus.connecting;

    try {
      _socket = await SecureSocket.connect(
        config.host,
        config.port,
        timeout: config.timeout,
        onBadCertificate: config.allowInvalidCerts ? (_) => true : null,
      );

      _status = ConnectionStatus.connected;
      _eventsController.add(ConnectionEstablished(
        host: config.host,
        port: config.port,
      ));

      _dataSubscription = _socket!.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );
    } on SocketException catch (e, st) {
      _status = ConnectionStatus.error;
      _eventsController.add(ConnectionError(error: e, stackTrace: st));
      rethrow;
    } on HandshakeException catch (e, st) {
      _status = ConnectionStatus.error;
      _eventsController.add(ConnectionError(error: e, stackTrace: st));
      rethrow;
    } catch (e, st) {
      _status = ConnectionStatus.error;
      _eventsController.add(ConnectionError(error: e, stackTrace: st));
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    _dataSubscription = null;

    try {
      await _socket?.close();
    } catch (_) {
      // Ignore errors during close
    }
    _socket = null;

    _lineBuffer.clear();
    _status = ConnectionStatus.disconnected;
  }

  @override
  void send(String line) {
    if (_socket == null || _status != ConnectionStatus.connected) {
      throw StateError('Not connected');
    }

    var data = line;
    if (!data.endsWith('\r\n')) {
      if (data.endsWith('\n')) {
        data = '${data.substring(0, data.length - 1)}\r\n';
      } else {
        data = '$data\r\n';
      }
    }

    _socket!.write(data);
  }

  @override
  void dispose() {
    disconnect();
    _linesController.close();
    _eventsController.close();
  }

  void _onData(List<int> data) {
    final text = utf8.decode(data, allowMalformed: true);
    final lines = _lineBuffer.addData(text);
    for (final line in lines) {
      _linesController.add(line);
    }
  }

  void _onError(Object error, StackTrace stackTrace) {
    _status = ConnectionStatus.error;
    _eventsController.add(ConnectionError(error: error, stackTrace: stackTrace));
  }

  void _onDone() {
    final wasConnected = _status == ConnectionStatus.connected;
    _status = ConnectionStatus.disconnected;
    _socket = null;

    if (wasConnected) {
      _eventsController.add(const ConnectionLost());
    }
  }
}
