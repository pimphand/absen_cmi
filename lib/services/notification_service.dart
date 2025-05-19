import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class NotificationService extends ChangeNotifier {
  WebSocketChannel? _channel;
  List<NotificationData> _notifications = [];
  bool _isConnected = false;

  List<NotificationData> get notifications => _notifications;
  bool get isConnected => _isConnected;

  void connect(String userId) {
    try {
      final wsUrl = Uri.parse('wss://websocket.dmpt.my.id/ws');
      _channel = WebSocketChannel.connect(wsUrl);

      _channel?.stream.listen(
        (message) {
          final data = jsonDecode(message);
          if (data['channel'] == 'leaves-$userId' && data['data'] != null) {
            final notification = NotificationData(
              title: data['data']['title'],
              content: data['data']['content'],
              timestamp: DateTime.now(),
            );
            _notifications.insert(0, notification);
            notifyListeners();
          }
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _isConnected = false;
          notifyListeners();
        },
        onDone: () {
          print('WebSocket Connection Closed');
          _isConnected = false;
          notifyListeners();
        },
      );

      // Subscribe to channel
      _channel?.sink.add(jsonEncode({'channel': 'leaves-$userId'}));

      _isConnected = true;
      notifyListeners();
    } catch (e) {
      print('Connection Error: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}

class NotificationData {
  final String title;
  final String content;
  final DateTime timestamp;

  NotificationData({
    required this.title,
    required this.content,
    required this.timestamp,
  });
}
