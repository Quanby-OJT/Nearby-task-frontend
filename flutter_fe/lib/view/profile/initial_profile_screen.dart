import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:flutter_fe/view/fill_up/fill_up_tasker.dart';
import 'package:flutter_fe/view/profile/profile_screen.dart';
import 'package:flutter_fe/view/service_acc/fill_up.dart';
import 'package:get_storage/get_storage.dart';

class InitialProfileScreen extends StatefulWidget {
  const InitialProfileScreen({super.key});

  @override
  State<InitialProfileScreen> createState() => _InitialProfileScreenState();
}

class _InitialProfileScreenState extends State<InitialProfileScreen> {
  final ProfileController _userController = ProfileController();
  final AuthenticationController _authController = AuthenticationController();
  final storage = GetStorage();
  final ProfileController _profileController = ProfileController();
  AuthenticatedUser? _user;
  bool isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      int userId = storage.read("user_id");
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      debugPrint(user.toString());
      setState(() {
        isLoading = false;
        _user = user;
      });
    } catch (e, stackTrace) {
      debugPrint("Error fetching user data: $e");
      debugPrintStack(stackTrace: stackTrace);
      setState(() => _user = null);
    }
  }

  String _fullName = 'Loading...';
  String _role = 'Loading...';
  String _image = '';

  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    // if (_isLoading) {
    //   return Center(
    //     child: CircularProgressIndicator(),
    //   );
    // }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('Profile'),
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          children: [
            // Menu Items
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Personal Data'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ProfileScreen();
                }));
                // Handle navigation to Personal Data
              },
            ),
            ListTile(
              leading: Icon(Icons.domain_verification),
              title: Text('Verify Account'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                final userId = storage.read("user_id");
                if (_user?.user.role.toLowerCase() == 'client') {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return FillUpClient();
                  }));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return FillUpTaskerLogin(userId: userId as int);
                  }));
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Handle navigation to E-Statement
              },
            ),
            ListTile(
              leading: Icon(Icons.card_giftcard),
              title: Text('Referral Code'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Handle navigation to Referral Code
              },
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text('FAQs'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Handle navigation to FAQs
              },
            ),
            ListTile(
              leading: Icon(Icons.book),
              title: Text('Our Handbook'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                _authController.logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
