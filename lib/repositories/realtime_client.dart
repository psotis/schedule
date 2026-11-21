import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class RealtimeClient {
  RealtimeClient({required this.baseUrl});

  final String baseUrl;
  final StreamController<String> _changes = StreamController.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  String? _token;
  String? _storeId;
  int _connectionGeneration = 0;
  bool _manuallyDisconnected = true;

  Stream<void> watch(String resource) => _changes.stream
      .where((changedResource) =>
          changedResource == resource || changedResource == '*')
      .map((_) {});

  Future<void> connect({required String token, required String storeId}) async {
    if (token.isEmpty || storeId.isEmpty || baseUrl.isEmpty) return;
    if (_token == token &&
        _storeId == storeId &&
        _channel != null &&
        !_manuallyDisconnected) {
      return;
    }

    await disconnect();
    _token = token;
    _storeId = storeId;
    _manuallyDisconnected = false;
    _open(++_connectionGeneration);
  }

  Future<void> disconnect() async {
    _manuallyDisconnected = true;
    _connectionGeneration++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  void _open(int generation) {
    if (_manuallyDisconnected || generation != _connectionGeneration) return;

    final apiUri = Uri.parse(baseUrl);
    final socketUri = apiUri.replace(
      scheme: apiUri.scheme == 'https' ? 'wss' : 'ws',
      path: '${apiUri.path.replaceFirst(RegExp(r'/$'), '')}/realtime',
      query: null,
      fragment: null,
    );
    final channel = WebSocketChannel.connect(socketUri);
    _channel = channel;

    channel.ready.then((_) {
      if (_manuallyDisconnected || generation != _connectionGeneration) {
        channel.sink.close();
        return;
      }
      channel.sink.add(jsonEncode({
        'type': 'authenticate',
        'token': _token,
        'store_id': _storeId,
      }));
    }).catchError((_) {
      _scheduleReconnect(generation);
    });

    _subscription = channel.stream.listen(
      (data) {
        if (generation != _connectionGeneration) return;
        final message = jsonDecode(data.toString()) as Map<String, dynamic>;
        if (message['type'] == 'authenticated') {
          _changes.add('*');
          return;
        }
        if (message['type'] != 'store_changed') return;
        for (final resource in (message['resources'] as List? ?? const [])) {
          _changes.add(resource.toString());
        }
      },
      onError: (_) => _scheduleReconnect(generation),
      onDone: () => _scheduleReconnect(generation),
      cancelOnError: true,
    );
  }

  void _scheduleReconnect(int generation) {
    if (_manuallyDisconnected || generation != _connectionGeneration) return;
    _subscription = null;
    _channel = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      if (_manuallyDisconnected || generation != _connectionGeneration) return;
      _open(generation);
    });
  }
}
