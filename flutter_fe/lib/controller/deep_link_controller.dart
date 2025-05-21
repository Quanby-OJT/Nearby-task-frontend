import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/view/sign_in/forgot_password.dart';
import 'package:get/get.dart';
import '../view/auth/email_verification_page.dart';
import '../view/profile/payment_processing.dart';

class DeepLinkController extends GetxController {
  final AppLinks _appLinks = AppLinks();
  late final StreamSubscription<Uri> _linkSub;

  @override
  void onInit() {
    super.onInit();
    _listenToDeepLinks();
  }

  void _listenToDeepLinks() async {
    // Handle cold start
    final Uri? initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _routeToDestination(initialUri);

    // Handle live incoming links
    _linkSub = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) _routeToDestination(uri);
    }, onError: (err) {
      debugPrint("🔴 Deep link error: $err");
    });
  }

  void _routeToDestination(Uri uri) {
    debugPrint("📥 Routing deep link: $uri");

    switch (uri.host) {
      case 'verify':
        Get.to(() => ForgotPassword(uri: uri));
        break;
      case 'paymongo':
        Get.to(() => PaymentProcessingPage(uri: uri));
        break;
      case 'nextpay':
      // Add other cases here
        break;
      default:
        debugPrint("⚠️ Unknown deep link host: ${uri.host}");
    }
  }

  @override
  void onClose() {
    _linkSub.cancel();
    super.onClose();
  }
}
