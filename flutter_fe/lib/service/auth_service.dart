import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

class AuthService{
  static Future<String> getSessionToken() async{
    debugPrint("Session: ${GetStorage().read('session')}");
    return Future.value(GetStorage().read('session'));
  }
}