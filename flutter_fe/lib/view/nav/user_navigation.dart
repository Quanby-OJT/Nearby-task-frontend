import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/view/business_acc/create_escrow_token.dart';

import 'package:flutter_fe/view/business_acc/notif_screen.dart';
import 'package:flutter_fe/view/business_acc/profile_screen.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:flutter_fe/view/service_acc/fill_up.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
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
  final AuthenticationController _authController = AuthenticationController();
  final GetStorage storage = GetStorage();
  AuthenticatedUser? _user;
  String _fullName = "Loading...";
  String _role = "Loading...";
  String _image = "";

  final GlobalKey _moreVertKey = GlobalKey();

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
          _fullName = "Not logged in";
          _role = "Please log in";
          _image = "Unknown";
        });
        return;
      }

      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      debugPrint(user.toString());

      if (user == null) {
        setState(() {
          _fullName = "User not found";
          _role = "Error fetching user data";
          _image = "Unknown";
        });
        return;
      }

      setState(() {
        _user = user;

        _fullName = [
          _user?.user.firstName ?? '',
          _user?.user.middleName ?? '',
          _user?.user.lastName ?? '',
        ].where((name) => name.isNotEmpty).join(' ');

        _role = _user?.user.role ?? "Unknown";
        _image = user.user.image ?? "Unknown";

        _profileController.firstNameController.text = _fullName;
        _profileController.roleController.text = _role;
        _profileController.imageController.text = _image;
      });
    } catch (e) {
      debugPrint("Error fetching user data: $e");
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
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      image: _image != "Unknown" && _image.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(_image),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                setState(() {
                                  _image = "Unknown";
                                });
                              },
                            )
                          : null,
                    ),
                    child: _image == "Unknown" || _image.isEmpty
                        ? Icon(Icons.person, color: Colors.grey)
                        : null,
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
                  debugPrint('Notifications clicked');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotifScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              GestureDetector(
                key: _moreVertKey, // Assign the key to more_vert
                onTap: () {
                  debugPrint('Menu clicked');
                  _showAnimatedMenu(context);
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

  void _showAnimatedMenu(BuildContext context) {
    final RenderBox renderBox =
        _moreVertKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    // Set menu width to half the screen width
    final double menuWidth = screenWidth / 2;

    // Calculate position for the popup
    final double leftPosition = position.dx + renderBox.size.width - menuWidth;
    final double topPosition = position.dy + renderBox.size.height;

    // Ensure the menu stays within screen bounds
    final double adjustedLeft = leftPosition < 0
        ? 0
        : leftPosition + menuWidth > screenWidth
            ? screenWidth - menuWidth
            : leftPosition;

    // Create an overlay entry
    OverlayState overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent barrier that dismisses the popup when tapped
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                overlayEntry.remove();
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // The actual popup menu
          Positioned(
            left: adjustedLeft,
            top: topPosition,
            width: menuWidth,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Profile'),
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return ProfileScreen();
                        }));
                        overlayEntry.remove();
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.domain_verification),
                      title: Text('Verify Account'),
                      onTap: () {
                        final userId = storage.read("user_id");
                        if (_user?.user.role.toLowerCase() == 'client') {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return FillUpClient();
                          }));
                          overlayEntry.remove();
                        } else {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return FillUpTaskerLogin(userId: userId as int);
                          }));
                          overlayEntry.remove();
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(FontAwesomeIcons.coins),
                      title: Text('Add NearByTask Tokens'),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) {
                          return EscrowTokenScreen();
                        }));
                        overlayEntry.remove();
                      }
                    ),
                    ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Settings'),
                      onTap: () {
                        // Handle navigation to E-Statement
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.card_giftcard),
                      title: Text('Referral Code'),
                      onTap: () {
                        // Handle navigation to Referral Code
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.help),
                      title: Text('FAQs'),
                      onTap: () {
                        // Handle navigation to FAQs
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.book),
                      title: Text('Our Handbook'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Logout'),
                      onTap: () {
                        _authController.logout(context);
                        overlayEntry.remove();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Add the overlay entry to the overlay
    overlayState.insert(overlayEntry);
  }
}
