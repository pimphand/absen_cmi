import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class NotificationService extends ChangeNotifier {
  WebSocketChannel? _channel;
  List<NotificationData> _notifications = [];
  bool _isConnected = false;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Timer? _reconnectTimer;
  String? _lastUserId;
  int _badgeCount = 0;

  List<NotificationData> get notifications => _notifications;
  bool get isConnected => _isConnected;
  int get badgeCount => _badgeCount;

  NotificationService() {
    _initializeNotifications();
  }

  Future<void> _updateBadgeCount() async {
    _badgeCount = _notifications.length;

    // Update iOS badge
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Update Android badge
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            'leaves_channel',
            'Leaves Notifications',
            description: 'Notifications for leave requests',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
            showBadge: true,
            enableLights: true,
          ),
        );

    notifyListeners();
  }

  Future<void> _initializeNotifications() async {
    debugPrint('Initializing notifications...');

    // Request permissions for iOS
    final bool? iOSPermission = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    debugPrint('iOS notification permission: $iOSPermission');

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('Notification clicked: ${response.payload}');
        await WakelockPlus.enable();
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'leaves_channel',
      'Leaves Notifications',
      description: 'Notifications for leave requests',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
      enableLights: true,
    );

    try {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      debugPrint('Android notification channel created successfully');
    } catch (e) {
      debugPrint('Error creating notification channel: $e');
    }
  }

  Future<void> _showNotification(String title, String content) async {
    try {
      debugPrint('Attempting to show notification: $title - $content');

      // Enable wake lock before showing notification
      await WakelockPlus.enable();

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'leaves_channel',
        'Leaves Notifications',
        channelDescription: 'Notifications for leave requests',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: Color(0xFF4CAF50),
        ledColor: Color(0xFF4CAF50),
        ledOnMs: 1000,
        ledOffMs: 500,
        ticker: 'New notification',
        styleInformation: BigTextStyleInformation(''),
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('id_1', 'Action 1'),
          AndroidNotificationAction('id_2', 'Action 2'),
        ],
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        sound: 'default',
        badgeNumber: 1,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecond,
        title,
        content,
        platformChannelSpecifics,
        payload: 'leaves_notification',
      );

      // Update badge count
      await _updateBadgeCount();

      debugPrint('Notification shown successfully');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (!_isConnected && _lastUserId != null) {
        debugPrint('Attempting to reconnect WebSocket...');
        connect(_lastUserId!);
      }
    });
  }

  void connect(String userId) {
    try {
      _lastUserId = userId;
      debugPrint('Connecting to WebSocket...');
      final wsUrl = Uri.parse('wss://websocket.dmpt.my.id/ws');
      _channel = WebSocketChannel.connect(wsUrl);

      _channel?.stream.listen(
        (message) async {
          debugPrint('Received WebSocket message: $message');
          final data = jsonDecode(message);
          if (data['channel'] == 'leaves-$userId' && data['data'] != null) {
            final notification = NotificationData(
              title: data['data']['title'],
              content: data['data']['content'],
              timestamp: DateTime.now(),
            );
            _notifications.insert(0, notification);

            // Show notification with retry
            int retryCount = 0;
            while (retryCount < 3) {
              try {
                await _showNotification(
                    notification.title, notification.content);
                break;
              } catch (e) {
                retryCount++;
                debugPrint('Retry $retryCount showing notification: $e');
                await Future.delayed(Duration(seconds: 1));
              }
            }

            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('WebSocket Error: $error');
          _isConnected = false;
          notifyListeners();
        },
        onDone: () {
          debugPrint('WebSocket Connection Closed');
          _isConnected = false;
          notifyListeners();
        },
      );

      // Subscribe to channel
      _channel?.sink.add(jsonEncode({'channel': 'leaves-$userId'}));
      debugPrint('Subscribed to channel: leaves-$userId');

      _isConnected = true;
      _startReconnectTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('Connection Error: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _lastUserId = null;
    WakelockPlus.disable();
    notifyListeners();
  }

  Future<void> clearNotifications() async {
    _notifications.clear();
    _badgeCount = 0;

    // Clear iOS badge
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Clear Android badge
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            'leaves_channel',
            'Leaves Notifications',
            description: 'Notifications for leave requests',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
            showBadge: false,
            enableLights: true,
          ),
        );

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
