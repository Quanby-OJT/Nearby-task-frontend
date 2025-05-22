import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/setting_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/setting.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/model/tasker_feedback.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/controller/tasker_controller.dart';
import 'package:flutter_fe/view/address/set-up_address.dart';
import 'package:flutter_fe/view/business_acc/notif_screen.dart';
import 'package:flutter_fe/view/profile/profile_screen.dart';
import 'package:flutter_fe/view/service_acc/notif_screen.dart';
import 'package:flutter_fe/view/setting/setting.dart';
import 'package:flutter_fe/view/business_acc/tasker_profile_page.dart';
import 'package:flutter_fe/view/verification/verification_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage>
    with TickerProviderStateMixin {
  final ProfileController _profileController = ProfileController();
  final AuthenticationController _authController = AuthenticationController();
  final GetStorage storage = GetStorage();
  final CardSwiperController controller = CardSwiperController();
  final JobPostService jobPostService = JobPostService();
  final ClientServices _clientServices = ClientServices();
  final TaskerController _taskerController = TaskerController();
  final SettingController _settingController = SettingController();
  List<MapEntry<int, String>> categories = [];
  Map<String, bool> selectedCategories = {};

  SettingModel _userPreference = SettingModel();
  AuthenticatedUser? tasker;
  String _role = "Loading...";
  List<AuthenticatedUser> taskers = [];
  List<TaskerFeedback> taskerFeedback = [];
  String? _errorMessage;
  int? cardNumber = 0;
  final Map<int, List<TaskerFeedback>> _taskerFeedbacks = {};

  AuthenticatedUser? _user;
  String _fullName = "Loading...";
  String _image = "";
  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;
  bool _documentValid = false;
  bool _isLoading = true;
  bool _isUploadDialogShown = false;
  final GlobalKey _moreVertKey = GlobalKey();
  List<TaskerModel> fetchedTaskers = [];

  AnimationController? _likeAnimationController;
  AnimationController? _dislikeAnimationController;
  bool _showLikeAnimation = false;
  bool _showDislikeAnimation = false;

  @override
  void initState() {
    super.initState();
    _loadAllFunction();

    _likeAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _dislikeAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _likeAnimationController?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showLikeAnimation = false;
        });
        _likeAnimationController?.reset();
      }
    });

    _dislikeAnimationController?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showDislikeAnimation = false;
        });
        _dislikeAnimationController?.reset();
      }
    });
  }

  @override
  void dispose() {
    _likeAnimationController?.dispose();
    _dislikeAnimationController?.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadAllFunction() async {
    try {
      await Future.wait([
        _fetchUserIDImage(),
        _fetchUserData(),
        _fetchTaskers(),
      ]);
      setState(() {
        _isLoading = false;
      });

      final response = await _settingController.getLocation();
      setState(() {
        _userPreference = response;
      });

      debugPrint("User preference: ${_userPreference.id}");

      if (_userPreference.id == null) {
        setState(() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SetUpAddressScreen()),
          ).then((value) {
            setState(() {
              _isLoading = true;
              _loadAllFunction();
            });
          });
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load data: $e";
      });
    }
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
      debugPrint("Current User: $user");

      if (user == null) {
        setState(() {
          _fullName = "User not found";
          _role = "Error fetching user data";
          _image = "Unknown";
        });
        return;
      }

      if(user.user.accStatus == "Warn"){
        showWarnUser();
      }else if(user.user.accStatus == "Ban"){
        showBanUser();
      }else{
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
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      setState(() {
        _fullName = "User not found";
        _role = "Error fetching user data";
        _image = "Error fetching user image";
      });
    }
  }

  void showWarnUser() {
    showDialog(
        context: context,
        builder: (BuildContext childContext){
          return AlertDialog(
              content: Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.triangleExclamation,
                      color: Color(0XFFE7A335),
                      size: 50,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text(
                          "You have been flagged for suspicious activity in your account. Please Contact Support for more information. Tap anywhere to remove this warning.",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        )
                    )
                  ]
              )
          );
        }
    );
  }

  void showBanUser() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext childContext){
          return AlertDialog(
              content: Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.triangleExclamation,
                      color: Color(0XFFEB5A63),
                      size: 50,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text(
                          "You have been banned from using this application. Please contact our support if you want to appeal.",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        )
                    )
                  ]
              ),
              actions: [
                TextButton(
                    onPressed: () async{
                      await _authController.logout(context, () => mounted);
                    },
                    child: Text(
                      "Log Out",
                      style: GoogleFonts.poppins(
                        color: Color(0xFFB71A4A),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                )
              ]
          );
        }
    );
  }

  Future<void> _fetchUserIDImage() async {
    try {
      int userId = int.parse(storage.read('user_id').toString());
      if (userId == 0) {
        debugPrint("User ID not found in storage");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load user image. Please try again."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      final response = await _clientServices.fetchUserIDImage(userId);

      if (response['success']) {
        setState(() {
          _user = user;
          _existingProfileImageUrl = user?.user.image;
          _existingIDImageUrl = response['url'];
          _documentValid = response['status'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching ID image: $e");
    }
  }

  Future<void> _fetchTaskers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      fetchedTaskers = await _taskerController.getAllTaskers();

      debugPrint("Fetched Taskers: ${fetchedTaskers.length}");

      setState(() {
        taskers = fetchedTaskers
            .map((tasker) =>
                AuthenticatedUser(tasker: tasker, user: tasker.user!))
            .toList();
      });
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = "Unable to load taskers. Please try again.";
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLikedTasker(UserModel tasker) async {
    try {
      final result = await _clientServices.saveLikedTasker(tasker.id!);
      if (result.containsKey('message')) {
        setState(() {
          _showLikeAnimation = true;
        });
        _likeAnimationController?.forward();
      }
    } catch (e) {
      setState(() {
        _showDislikeAnimation = true;
      });
      _dislikeAnimationController?.forward();
    }
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Account Verification"),
        content: const Text(
            "Upload your Profile and ID images to complete your account. Verification will follow."),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const VerificationPage()),
              );
              if (result == true) {
                setState(() {
                  _isLoading = true;
                });
                await _fetchUserIDImage();
                await _fetchTaskers();
              } else {
                setState(() {
                  _isUploadDialogShown = false;
                });
              }
            },
            child: const Text("Verify Account"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isUploadDialogShown = false;
              });
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _cardCounter() {
    setState(() {
      cardNumber = cardNumber! - 1;
    });
  }

  void _showAnimatedMenu(BuildContext context) {
    final RenderBox renderBox =
        _moreVertKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    final double menuWidth = screenWidth / 1.5;
    final double leftPosition = position.dx + renderBox.size.width - menuWidth;
    final double topPosition = position.dy + renderBox.size.height;

    final double adjustedLeft = leftPosition < 0
        ? 0
        : leftPosition + menuWidth > screenWidth
            ? screenWidth - menuWidth
            : leftPosition;

    OverlayState overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
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
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.person,
                        color: const Color(0xFFB71A4A),
                      ),
                      title: Text(
                        'Profile',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfileScreen()),
                        );
                        overlayEntry.remove();
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.domain_verification,
                        color: const Color(0xFFB71A4A),
                      ),
                      title: Text(
                        'Verify Account',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const VerificationPage()),
                        );
                        overlayEntry.remove();
                      },
                    ),
                    // if (_role == "Client") ...[
                    //   ListTile(
                    //     leading: Icon(
                    //       FontAwesomeIcons.coins,
                    //       color: const Color(0xFFB71A4A),
                    //     ),
                    //     title: Text(
                    //       'Manage Tokens',
                    //       style: GoogleFonts.poppins(
                    //         color: Colors.black,
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.w300,
                    //       ),
                    //     ),
                    //     onTap: () {
                    //       if (_user?.user.accStatus?.toLowerCase() ==
                    //           'review') {
                    //         Navigator.push(
                    //           context,
                    //           MaterialPageRoute(
                    //               builder: (context) => EscrowTokenScreen()),
                    //         );
                    //         overlayEntry.remove();
                    //         return;
                    //       }
                    //
                    //       if (_existingProfileImageUrl == null ||
                    //           _existingIDImageUrl == null ||
                    //           _existingProfileImageUrl!.isEmpty ||
                    //           _existingIDImageUrl!.isEmpty ||
                    //           !_documentValid) {
                    //         overlayEntry.remove();
                    //         _showWarningDialog();
                    //         return;
                    //       }
                    //       Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //             builder: (context) => EscrowTokenScreen()),
                    //       );
                    //       overlayEntry.remove();
                    //     },
                    //   ),
                    // ],
                    // ListTile(
                    //   leading: Icon(
                    //     FontAwesomeIcons.coins,
                    //     color: const Color(0xFF03045E),
                    //   ),
                    //   title: Text(
                    //     'Tokens',
                    //     style: GoogleFonts.poppins(
                    //       color: const Color(0xFF03045E),
                    //       fontSize: 14,
                    //       fontWeight: FontWeight.w300,
                    //     ),
                    //   ),
                    //   onTap: () {
                    //     if (_existingProfileImageUrl == null ||
                    //         _existingIDImageUrl == null ||
                    //         _existingProfileImageUrl!.isEmpty ||
                    //         _existingIDImageUrl!.isEmpty ||
                    //         !_documentValid) {
                    //       overlayEntry.remove();
                    //       _showWarningDialog();
                    //       return;
                    //     }
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //           builder: (context) => EscrowTokenScreen()),
                    //     );
                    //     overlayEntry.remove();
                    //   },
                    // ),
                    ListTile(
                      leading: Icon(
                        Icons.help,
                        color: const Color(0xFFB71A4A),
                      ),
                      title: Text(
                        'FAQs',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      onTap: () {
                        overlayEntry.remove();
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.card_giftcard,
                        color: const Color(0xFFB71A4A),
                      ),
                      title: Text(
                        'Referral Code',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      onTap: () {
                        overlayEntry.remove();
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.book,
                        color: const Color(0xFFB71A4A),
                      ),
                      title: Text(
                        'Our Handbook',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      onTap: () {
                        overlayEntry.remove();
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.settings,
                        color: const Color(0xFFB71A4A),
                      ),
                      title: Text(
                        'Settings',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SettingScreen()),
                        ).then((value) => setState(() {
                              _fetchTaskers();
                            }));
                        overlayEntry.remove();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xFFB71A4A),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.logout,
                            color: Colors.white,
                          ),
                          title: Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            _showLogoutConfirmationDialog();
                            overlayEntry.remove();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlayState.insert(overlayEntry);
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          title: Text('Logout',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to logout?',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w300)),
          actions: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB71A4A),
                      )),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: const Color(0xFFB71A4A),
                  ),
                  child: TextButton(
                    child: Text('Logout',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                    onPressed: () {
                      _authController.logout(context, () => mounted);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ]),
    );
  }

  AppBar _buildAppBar() {
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
                    style: GoogleFonts.poppins(
                        color: const Color(0xFFB71A4A), fontSize: 10),
                  ),
                  Text(
                    _fullName,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
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
                  debugPrint('Notifications clicked _role: $_role');
                  if (_role == "Client") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotifScreen(),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotifSTaskerScreen(),
                      ),
                    );
                  }
                },
                icon: Icon(
                  Icons.notifications_outlined,
                  color: const Color(0xFFB71A4A),
                  size: 24,
                ),
              ),
              GestureDetector(
                key: _moreVertKey,
                onTap: () {
                  debugPrint('Menu clicked');
                  _showAnimatedMenu(context);
                },
                child: Icon(
                  Icons.more_vert,
                  color: const Color(0xFFB71A4A),
                  size: 24,
                ),
              ),
            ],
          )
        ],
      ),
      backgroundColor: Colors.grey[100],
      centerTitle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline,
                                    size: 60, color: Colors.grey[400]),
                                SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchTaskers,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF0272B1),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text('Retry',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white)),
                                ),
                              ],
                            ),
                          )
                        : taskers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_search,
                                        size: 80, color: Colors.grey[300]),
                                    SizedBox(height: 16),
                                    Text(
                                      "No Taskers Available",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Try adjusting your filters or check back later.",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600]),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 16),
                                    OutlinedButton(
                                      onPressed: _fetchTaskers,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: Color(0xFF0272B1)),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text('Refresh',
                                          style: TextStyle(
                                              color: Color(0xFF0272B1))),
                                    ),
                                  ],
                                ),
                              )
                            : CardSwiper(
                                numberOfCardsDisplayed: taskers.length,
                                allowedSwipeDirection:
                                    AllowedSwipeDirection.only(
                                  left: true,
                                  right: true,
                                ),
                                controller: controller,
                                cardsCount: taskers.length,
                                onSwipe: (previousIndex, targetIndex,
                                    swipeDirection) {
                                  if (swipeDirection ==
                                      CardSwiperDirection.left) {
                                    setState(() {
                                      _showDislikeAnimation = true;
                                    });
                                    _dislikeAnimationController?.forward();
                                    _cardCounter();
                                  } else if (swipeDirection ==
                                      CardSwiperDirection.right) {
                                    if (_user?.user.accStatus?.toLowerCase() ==
                                        'review') {
                                      _saveLikedTasker(
                                          taskers[previousIndex].user);
                                      _cardCounter();
                                      return true;
                                    }

                                    // Only show verification dialog if the user isn't verified
                                    // We check both document validity AND if both images exist
                                    if (!_documentValid ||
                                        _existingProfileImageUrl == null ||
                                        _existingIDImageUrl == null ||
                                        _existingProfileImageUrl!.isEmpty ||
                                        _existingIDImageUrl!.isEmpty) {
                                      _showWarningDialog();
                                      return false;
                                    }
                                    _saveLikedTasker(
                                        taskers[previousIndex].user);
                                    _cardCounter();
                                  }
                                  return true;
                                },
                                cardBuilder: (context, index, percentThresholdX,
                                    percentThresholdY) {
                                  final tasker = taskers[index];
                                  return Container(
                                    width: double.infinity,
                                    height: MediaQuery.of(context).size.height,
                                    padding: EdgeInsets.only(top: 0, bottom: 8),
                                    child: Card(
                                      elevation: 8,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      margin: EdgeInsets.zero,
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: tasker.user.image != null &&
                                                    tasker
                                                        .user.image!.isNotEmpty
                                                ? Image.network(
                                                    tasker.user.image!,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Container(
                                                        color: Colors.grey[200],
                                                        child: Center(
                                                          child: Icon(
                                                            Icons.person,
                                                            size: 100,
                                                            color: Colors
                                                                .grey[400],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : Container(
                                                    color: Colors.grey[200],
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.person,
                                                        size: 100,
                                                        color: Colors.grey[400],
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                          // Darker overlay on the entire image
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.black
                                                        .withOpacity(0.2),
                                                    Colors.black
                                                        .withOpacity(0.5),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        bottom: Radius.circular(
                                                            20)),
                                                gradient: LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  colors: [
                                                    Colors.black
                                                        .withOpacity(0.7),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "${tasker.user.firstName} ${tasker.user.lastName}",
                                                    style: TextStyle(
                                                      fontSize: 26,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      ...List.generate(5,
                                                          (index) {
                                                        double rating = tasker
                                                                .tasker
                                                                ?.rating ??
                                                            4.5;
                                                        return Icon(
                                                          index < rating.floor()
                                                              ? Icons.star
                                                              : index < rating
                                                                  ? Icons
                                                                      .star_half
                                                                  : Icons
                                                                      .star_border,
                                                          color: Colors.amber,
                                                          size: 18,
                                                        );
                                                      }),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        "${tasker.tasker?.rating ?? 4.5}",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    tasker.tasker
                                                            ?.specialization ??
                                                        "No specialization",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 16,
                                            right: 16,
                                            child: IconButton(
                                              icon: Icon(Icons.info_outline,
                                                  color: Colors.white),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        TaskerProfilePage(
                                                      tasker: tasker.tasker!,
                                                      isSaved: false,
                                                      taskerId:
                                                          tasker.tasker?.id,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 16,
                                            right: 16,
                                            child: Column(
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () {
                                                    controller.swipe(
                                                        CardSwiperDirection
                                                            .left);
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    shape: CircleBorder(),
                                                    fixedSize: Size(50, 50),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                  child: Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    controller.swipe(
                                                        CardSwiperDirection
                                                            .right);
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFFB71A4A),
                                                    shape: CircleBorder(),
                                                    fixedSize: Size(50, 50),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                  child: Icon(
                                                    Icons.favorite,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              )
            ],
          ),
          if (_showLikeAnimation)
            Center(
              child: Lottie.asset(
                'assets/lottie/like.json',
                controller: _likeAnimationController,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          if (_showDislikeAnimation)
            Center(
              child: Lottie.asset(
                'assets/lottie/dislike.json',
                controller: _dislikeAnimationController,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String reviewer, String comment, int rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                reviewer,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
