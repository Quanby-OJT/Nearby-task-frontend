import 'dart:io';

import 'package:flutter/material.dart';
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
  await dotenv.load(fileName: ".env");
  HttpOverrides.global = MyHttpOverrides();
  Get.put(DeepLinkController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'NearbyTask',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WelcomePageViewMain(),
    );
  }
}
