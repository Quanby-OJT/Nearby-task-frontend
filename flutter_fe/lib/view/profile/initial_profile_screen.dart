import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:flutter_fe/view/fill_up/fill_up_tasker.dart';
import 'package:flutter_fe/view/profile/profile_screen.dart';
import 'package:get_storage/get_storage.dart';

class InitialProfileScreen extends StatefulWidget {
  const InitialProfileScreen({super.key});

  @override
  State<InitialProfileScreen> createState() => _InitialProfileScreenState();
}

class _InitialProfileScreenState extends State<InitialProfileScreen> {
  final ProfileController _userController = ProfileController();
  final AuthenticationController _authController = AuthenticationController();
  final GetStorage storage = GetStorage();
  AuthenticatedUser? _user;
  String _fullName = 'Loading...';
  String _role = 'Loading...';
  String _image = '';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final dynamic userId = storage.read("user_id");

      if (userId == null) {
        setState(() {
          _fullName = "Error...";
          _role = "";
          _image = "Unknown";
          _isLoading = false;
        });
        return;
      }

      AuthenticatedUser? user =
          await _userController.getAuthenticatedUser(context, userId);
      debugPrint(user.toString());

      if (user == null) {
        setState(() {
          _fullName = "User not found";
          _role = "Error fetching user data";
          _image = "Unknown";
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _user = user;

        _fullName = [
          _user?.user.firstName ?? '',
          _user?.user.middleName ?? '',
          _user?.user.lastName ?? '',
        ].where((name) => name.isNotEmpty).join(' ');

        _role = _user?.user.role ?? "Unknown";
        _image = user.user.image ?? "Unknown";

        _userController.firstNameController.text = _fullName;
        _userController.roleController.text = _role;
        _userController.imageController.text = _image;
      });
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
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
            // Profile Section
            Container(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150', // Replace with actual profile image URL
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userController.firstNameController.text,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _userController.roleController.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(),
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
                if (_userController.roleController.text == 'Client') {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return FillUpClient();
                  }));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return FillUpTasker(userId: userId as int);
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
              onTap: () {
                // Handle navigation to Handbook
              },
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
