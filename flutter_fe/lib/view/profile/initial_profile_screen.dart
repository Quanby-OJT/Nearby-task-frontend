import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:flutter_fe/view/fill_up/fill_up_tasker.dart';
import 'package:flutter_fe/view/profile/profile_screen.dart';
import 'package:flutter_fe/view/service_acc/fill_up.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
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

  final String _fullName = 'Loading...';
  final String _role = 'Loading...';
  final String _image = '';

  final bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            'Record',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Color(0xFF0272B1),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          children: [
            // Menu Items
          ],
        ),
      ),
    );
  }
}
