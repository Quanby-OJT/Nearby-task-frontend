import 'package:flutter_fe/service/api_service.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';

class FirebaseController extends GetxController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GetStorage _storage = GetStorage();
  String? _fcmToken;

  @override
  void onInit() {
    super.onInit();
    initFirebaseMessaging();
  }

  Future<void> initFirebaseMessaging() async {
    try {
      // Request permission
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('User granted permission: ${settings.authorizationStatus}');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get initial FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint("Initial Firebase: $_fcmToken");

      await _updateTokenOnServer(_fcmToken!);

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint("Firebase refreshed: $newToken");
        _fcmToken = newToken;
        await _updateTokenOnServer(_fcmToken!);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
            "Received foreground message: ${message.notification?.title}");
        _showLocalNotification(message);
      });

      // Handle background messages when app is in background and user taps notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
            "Opened app from background message: ${message.notification?.title}");
        // Handle navigation or other actions based on the message
        _handleNotificationTap(message);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;

        debugPrint("Received background message: ${notification?.title}");

        if (notification != null) {
          _showLocalNotification(message);
        }

        if (notification != null) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            SnackBar(
              content:
                  Text("Received background message: ${notification.title}"),
            ),
          );
        }
      });
    } catch (e, stackTrace) {
      debugPrint("Error initializing Firebase Messaging: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _updateTokenOnServer(String fcmToken) async {
    if (fcmToken.isEmpty) {
      debugPrint("FCM token is empty, skipping FCM token update");
      return;
    }

    try {
      final userId = _storage.read('user_id');
      debugPrint(
          "Attempting to update FCM token. User ID: $userId, Token: $fcmToken");

      if (userId == null) {
        debugPrint("No user ID found in storage, skipping FCM token update");
        return;
      }

      final result = await ApiService.updateFcmToken(fcmToken, userId);
      if (result['success'] == true) {
        // debugPrint("FCM token updated successfully on server")
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text("FCM token updated successfully on server"),
          ),
        );
      } else {
        debugPrint("Failed to update FCM token on server: ${result['error']}");
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text("Failed to update FCM token on server"),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("Error updating FCM token on server: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Add your notification tap handling logic here
    // For example, navigate to a specific screen based on the message data
    debugPrint("Handling notification tap with data: ${message.data}");
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
        // Handle notification tap when app is in foreground
        if (response.payload != null) {
          _handleNotificationPayload(response.payload!);
        }
      },
    );
  }

  void _handleNotificationPayload(String payload) {
    // Add your notification payload handling logic here
    debugPrint("Handling notification payload: $payload");
    // You can parse the payload and navigate to appropriate screen
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }
}
