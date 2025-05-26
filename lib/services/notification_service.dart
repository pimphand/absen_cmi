import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:provider/provider.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  // WebSocket related properties
  WebSocketChannel? _channel;
  List<NotificationData> _notifications = [];
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  String? _currentUserId;
  static const _reconnectDelay = Duration(seconds: 5);
  static const _heartbeatInterval = Duration(seconds: 30);
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 5;

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Getters
  List<NotificationData> get notifications => _notifications;
  bool get isConnected => _isConnected;

  // Initialize local notifications
  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // Request notification permissions
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel?.sink.add(jsonEncode({'type': 'ping'}));
          print('Heartbeat sent');
        } catch (e) {
          print('Error sending heartbeat: $e');
          _reconnect();
        }
      }
    });
  }

  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(_reconnectDelay, (timer) async {
      if (!_isConnected && _currentUserId != null) {
        if (_reconnectAttempts >= _maxReconnectAttempts) {
          print('Max reconnect attempts reached. Stopping reconnect timer.');
          _reconnectTimer?.cancel();
          return;
        }

        final hasInternet = await _checkInternetConnection();
        if (!hasInternet) {
          print('No internet connection. Skipping reconnect attempt.');
          return;
        }

        print(
            'Attempting to reconnect... (Attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)');
        _reconnectAttempts++;
        connect(_currentUserId!);
      }
    });
  }

  void _reconnect() {
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
    notifyListeners();

    if (_currentUserId != null) {
      connect(_currentUserId!);
    }
  }

  // WebSocket methods
  void connect(String userId) async {
    _currentUserId = userId;

    try {
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        print('No internet connection. Cannot establish WebSocket connection.');
        _isConnected = false;
        notifyListeners();
        return;
      }

      final wsUrl = Uri.parse('wss://websocket.dmpt.my.id/ws');
      _channel = WebSocketChannel.connect(wsUrl);

      _channel?.stream.listen(
        (message) {
          final data = jsonDecode(message);
          if (data['type'] == 'pong') {
            print('Received pong response');
            return;
          }

          if (data['channel'] == 'leaves-$userId' && data['data'] != null) {
            final notification = NotificationData(
              title: data['data']['title'],
              content: data['data']['content'],
              timestamp: DateTime.now(),
            );
            _notifications.insert(0, notification);
            // Show local notification when receiving WebSocket message
            showNotification(
              id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
              title: notification.title,
              body: notification.content,
            );
            notifyListeners();
          }
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _isConnected = false;
          notifyListeners();
          _startReconnectTimer();
        },
        onDone: () {
          print('WebSocket Connection Closed');
          _isConnected = false;
          notifyListeners();
          _startReconnectTimer();
        },
      );

      // Subscribe to channel
      _channel?.sink.add(jsonEncode({'channel': 'leaves-$userId'}));

      _isConnected = true;
      _reconnectAttempts =
          0; // Reset reconnect attempts on successful connection
      _startHeartbeat();
      notifyListeners();
    } catch (e) {
      print('Connection Error: $e');
      _isConnected = false;
      notifyListeners();
      _startReconnectTimer();
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _currentUserId = null;
    _reconnectAttempts = 0;
    _isConnected = false;
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  // Local notification methods
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'absen_cmi_channel',
        'Absen CMI Notifications',
        channelDescription: 'Notifications for Absen CMI app',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(id, title, body, details,
          payload: payload);
      print('Notification shown successfully: $title');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'absen_cmi_channel',
        'Absen CMI Notifications',
        channelDescription: 'Notifications for Absen CMI app',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      print('Notification scheduled successfully: $title');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      print('Notification cancelled successfully: $id');
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      print('All notifications cancelled successfully');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
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
