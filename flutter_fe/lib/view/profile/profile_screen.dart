import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/controller/profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _userController = ProfileController();
  final AuthenticationController _authController = AuthenticationController();
  final GetStorage storage = GetStorage();
  AuthenticatedUser? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      int userId = storage.read("user_id");
      AuthenticatedUser? user =
          await _userController.getAuthenticatedUser(context, userId);
      debugPrint(user.toString());
      setState(() {
        _user = user;
        _isLoading = false;

        // Concatenate full name
        String fullName = [
          _user?.user.firstName ?? '',
          _user?.user.middleName ?? '',
          _user?.user.lastName ?? ''
        ].where((name) => name.isNotEmpty).join(' ');

        // Populate controllers
        _userController.firstNameController.text = fullName;
        _userController.emailController.text = _user?.user.email ?? '';
        _userController.birthdateController.text = _user?.user.birthdate ?? '';
        _userController.prefsController.text = _user?.client?.preferences ?? '';
        _userController.clientAddressController.text =
            _user?.client?.clientAddress ?? '';
      });
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
            'Edit Your Profile',
          style: GoogleFonts.roboto(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                ],
              )
            )
          )
        )
      ),
    );
  }
}
