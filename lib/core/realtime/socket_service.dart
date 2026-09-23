import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';
import '../storage/token_storage.dart';

/// Real-time push — mirrors the server side exactly: src/realtime/socketServer.js
/// authenticates the handshake with the SAME access token as the REST API
/// (`handshake.auth.token`), and the server pushes a `call:event` message whenever a real call
/// changes state, or an `sms:event` message for a real SMS (src/realtime/callEvents.js's
/// emitCallEvent()/emitSmsEvent()). This is not polling dressed up as real-time — there is a
/// real Socket.IO connection here, or there is nothing.
///
/// Room scoping happens entirely server-side (a socket only ever joins its own
/// `client:<clientId>` room) — this client just listens for whatever the server actually sends.
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;

  /// Call after login (and again after a token refresh that follows a reconnect failure).
  Future<void> connect({
    required void Function(Map<String, dynamic> event) onCallEvent,
    void Function(Map<String, dynamic> event)? onSmsEvent,
  }) async {
    final token = await TokenStorage.instance.accessToken;
    if (token == null) return;

    disconnect();

    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .build(),
    );

    _socket!.on('call:event', (data) {
      if (data is Map) {
        onCallEvent(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('sms:event', (data) {
      if (data is Map && onSmsEvent != null) {
        onSmsEvent(Map<String, dynamic>.from(data));
      }
    });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;
}
