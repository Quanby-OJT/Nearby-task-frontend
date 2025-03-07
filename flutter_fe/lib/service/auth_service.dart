import 'package:get_storage/get_storage.dart';

class AuthService{
  static Future<String> getSessionToken() async{
    return Future.value(GetStorage().read('session'));
  }
}