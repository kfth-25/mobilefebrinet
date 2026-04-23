import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../providers/notification_provider.dart';
import 'notification_service.dart';
import '../main.dart';

class SocketService {
  // Singleton pattern
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Ganti dengan IP komputer Anda jika debugging di physical device
  // Contoh: 'http://192.168.1.5:3000'
  final String _serverUrl = 'http://192.168.11.158:3000';

  void connect(String userChannel) {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      _serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket']) // Gunakan transport websocket
          .disableAutoConnect() // Jangan auto connect dulu
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('[Socket] Connected to server: $_serverUrl');
      _isConnected = true;
      
      // Bergabung ke channel khusus user ini
      _socket!.emit('join_channel', userChannel);
    });

    _socket!.onDisconnect((_) {
      print('[Socket] Disconnected from server');
      _isConnected = false;
    });

    _socket!.onConnectError((err) {
      print('[Socket] Connect Error: $err');
      _isConnected = false;
    });

    _socket!.onError((err) {
      print('[Socket] Error: $err');
    });

    // Contoh listen event global: pengumuman
    _socket!.on('announcement', (data) async {
      print('[Socket] New Announcement: $data');
      try {
        if (data is Map) {
          final title = data['title']?.toString() ?? 'Pengumuman Baru';
          final body = data['body']?.toString() ?? '';
          final type = data['type']?.toString() ?? 'general';

          // Ensure it's saved to the history provider
          final notif = AppNotification(
            title: title,
            body: body,
            type: type,
            deeplink: data['deeplink']?.toString(),
            ts: DateTime.now().toIso8601String(),
          );
          notificationProvider.addNotification(notif);

          await NotificationService().show(
            id: DateTime.now().millisecondsSinceEpoch % 100000,
            title: title,
            body: body,
            payload: jsonEncode(data),
          );
        }
      } catch (e) {
        print('[Socket] Error showing notification: $e');
      }
    });
  }

  // Mendaftarkan listener khusus (misal dari Screen tertentu)
  void onEvent(String event, Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on(event, callback);
    }
  }

  void offEvent(String event) {
    if (_socket != null) {
      _socket!.off(event);
    }
  }

  void disconnect(String userChannel) {
    if (_socket != null) {
      _socket!.emit('leave_channel', userChannel);
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
    }
  }
}
