import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
// import 'package:flutter_fe/view/business_acc/profile_screen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/view/profile/profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class NavUserScreen extends StatefulWidget implements PreferredSizeWidget {
  const NavUserScreen({super.key});

  @override
  State<NavUserScreen> createState() => _NavUserScreenState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _NavUserScreenState extends State<NavUserScreen> {
  final ProfileController _profileController = ProfileController();
  final GetStorage storage = GetStorage();
  AuthenticatedUser? _user;
  String _fullName = "Loading...";
  String _role = "Loading...";
  String _image = "";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      int userId = storage.read("user_id");
      AuthenticatedUser? user = await _profileController.getAuthenticatedUser(
          context, userId);
      debugPrint(user.toString());
      setState(() {
        _user = user;

        _fullName = [
          _user?.user.firstName ?? '',
          _user?.user.middleName ?? '',
          _user?.user.lastName ?? '',
        ].where((name) => name.isNotEmpty).join(' ');

        _role = _user?.user.role ?? "Unknown";
        _image = user?.user.image ?? "Unknown";

        _profileController.firstNameController.text = _fullName;
        _profileController.roleController.text = _role;
        _profileController.imageController.text = _image;
      });
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        _fullName = "User not found";
        _role = "Error fetching user data";
        _image = "Error fetching user image";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => ProfileScreen(),
                  //   ),
                  // );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      image: DecorationImage(
                        image: NetworkImage(_image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _role,
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 10),
                  ),
                  Text(
                    _fullName, // Now dynamically updates!
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  print('Notifications clicked');
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              GestureDetector(
                onTap: () {
                  print('click menu');
                },
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          )
        ],
      ),
      backgroundColor: Colors.blue,
      centerTitle: true,
    );
  }
}
