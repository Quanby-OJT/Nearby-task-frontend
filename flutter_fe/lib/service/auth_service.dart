import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

class AuthService {
  static Future<String> getSessionToken() async {
    final session = GetStorage().read('session');
    debugPrint("Session: $session");
    return Future.value(
        session ?? ''); // Return empty string if session is null
  }
}
