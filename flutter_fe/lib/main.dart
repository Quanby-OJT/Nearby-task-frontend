import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/view/business_acc/business_acc_main_page.dart';
import 'package:flutter_fe/view/service_acc/service_acc_main_page.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_fe/view/welcome_page/welcome_page_view_main.dart';
import 'config/url_strategy.dart';
import 'controller/deep_link_controller.dart'; // Adjust import
import 'package:firebase_core/firebase_core.dart';
import 'firebase_option.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_fe/service/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotificationService.initializeNotifications();

  setPathUrlStrategy();
  WebViewPlatform.instance = AndroidWebViewPlatform();

  await GetStorage.init();
  final storage = GetStorage();
  await dotenv.load(fileName: ".env");
  HttpOverrides.global = MyHttpOverrides();
  Get.put(DeepLinkController());

  final session = storage.read('session');
  final role = storage.read('role');

  runApp(MyApp(
    isLoggedIn: session != null,
    role: role,
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? role;

  const MyApp({super.key, required this.isLoggedIn, required this.role});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: AuthenticationController.navigatorKey,
      title: 'QTask',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: isLoggedIn
          ? (role == "Client"
              ? const BusinessAccMain()
              : const ServiceAccMain())
          : const WelcomePageViewMain(),
    );
  }
}
