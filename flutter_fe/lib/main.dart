import 'package:flutter/material.dart';
import 'package:flutter_fe/view/service_acc/service_acc_main_page.dart';
import 'package:flutter_fe/view/sign_up_acc/email_confirmation.dart';
import 'package:flutter_fe/view/business_acc/business_acc_main_page.dart';
import 'package:flutter_fe/view/welcome_page/welcome_page_view_main.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  final storage = GetStorage();
  final userId = storage.read('user_id');
  runApp(MyApp(isLoggedIn: userId != null, userId: userId));
}

class MyApp extends StatelessWidget {
  final storage = GetStorage();

  MyApp({Key? key, required bool isLoggedIn, required dynamic userId})
      : super(key: key);

  Future<Map<String, dynamic>> _loadUserData() async {
    await Future.delayed(Duration(milliseconds: 300));

    final userId = storage.read('user_id');
    final role = storage.read('role');

    return {'userId': userId, 'role': role};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final userId = snapshot.data!['userId'];
        final role = snapshot.data!['role'];

        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: _getInitialRoute(userId, role),
          getPages: [
            GetPage(name: '/welcome', page: () => WelcomePageViewMain()),
            GetPage(name: '/service-home', page: () => ServiceAccMain()),
            GetPage(name: '/client-home', page: () => BusinessAccMain()),
            GetPage(
                name: '/email-confirmation', page: () => EmailConfirmation()),
          ],
        );
      },
    );
  }

  String _getInitialRoute(dynamic userId, dynamic role) {
    if (userId == null || userId.toString().isEmpty) return '/welcome';

    if (role == 'Client') {
      return '/client-home';
    } else if (role == 'Tasker') {
      return '/service-home';
    }

    return '/welcome';
  }
}
