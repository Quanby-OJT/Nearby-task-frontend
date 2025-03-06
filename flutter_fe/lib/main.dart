import 'package:flutter/material.dart';
import 'package:flutter_fe/view/service_acc/service_acc_main_page.dart';
import 'package:flutter_fe/view/sign_up_acc/email_confirmation.dart';
import 'package:flutter_fe/view/welcome_page/welcome_page_view_main.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  final storage = GetStorage();
  final userId = storage.read('user_id');
  runApp(MyApp(isLoggedIn: userId != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: isLoggedIn ? '/service-home' : '/welcome',
        getPages: [
          GetPage(name: '/welcome', page: () => WelcomePageViewMain()),
          GetPage(name: '/service-home', page: () => ServiceAccMain()),
          GetPage(name: '/email-confirmation', page: () => EmailConfirmation())
        ]);
  }
}
