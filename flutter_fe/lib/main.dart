import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/view/business_acc/business_acc_main_page.dart';
import 'package:flutter_fe/view/custom_loading/file_indicators.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  WebViewPlatform.instance = AndroidWebViewPlatform();

  await GetStorage.init();
  final storage = GetStorage();
  await dotenv.load(fileName: ".env");
  HttpOverrides.global = MyHttpOverrides();
  Get.put(DeepLinkController());

  final session = storage.read('session');
  final userId = storage.read('user_id');
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
