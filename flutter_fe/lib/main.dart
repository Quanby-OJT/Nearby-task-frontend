import 'package:flutter/material.dart';
import 'package:flutter_fe/config/url_strategy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_strategy/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy(); // Enable web URL strategy
  await GetStorage.init();
  runApp(const MyApp());
}

//TODO: Implement one hour session for the app where after 1 hour of inactivity, the app will automatically logout the user.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NearbyTask',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

//   final storage = GetStorage();
//   final userId = storage.read('user_id'); // This could be null or any type
//   runApp(MyApp(isLoggedIn: userId != null, userId: userId));
// }

// class MyApp extends StatelessWidget {
//   final storage = GetStorage();


//   MyApp({Key? key, required bool isLoggedIn, required dynamic userId})
//       : super(key: key);


//   Future<Map<String, dynamic>> _loadUserData() async {
//     await Future.delayed(Duration(milliseconds: 300));

//     final userId = storage.read('user_id');
//     final role = storage.read('role');

//     return {'userId': userId, 'role': role};
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<Map<String, dynamic>>(
//       future: _loadUserData(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return MaterialApp(
//             home: Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             ),
//           );
//         }

//         final userId = snapshot.data!['userId'];
//         final role = snapshot.data!['role'];

//         return GetMaterialApp(
//           debugShowCheckedModeBanner: false,
//           initialRoute: _getInitialRoute(userId, role),
//           getPages: [
//             GetPage(name: '/welcome', page: () => WelcomePageViewMain()),
//             GetPage(name: '/service-home', page: () => ServiceAccMain()),
//             GetPage(name: '/client-home', page: () => BusinessAccMain()),
//             GetPage(name: '/email-confirmation', page: () => EmailConfirmation()),
//           ],
//         );
//       },
//     );
//   }

//   String _getInitialRoute(dynamic userId, dynamic role) {
//     if (userId == null || userId.toString().isEmpty) return '/welcome';

//     if (role == 'Client') {
//       return '/client-home';
//     } else if (role == 'Tasker') {
//       return '/service-home';
//     }

//     return '/welcome';
//   }
// }
