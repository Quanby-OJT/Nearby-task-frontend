import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/controller/job_post_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/setting_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/setting.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/address/set-up_address.dart';
import 'package:flutter_fe/view/business_acc/notif_screen.dart';
import 'package:flutter_fe/view/profile/profile_screen.dart';
import 'package:flutter_fe/view/service_acc/notif_screen.dart';
import 'package:flutter_fe/view/setting/setting.dart';
import 'package:flutter_fe/view/sign_in/sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_fe/view/verification/verification_page.dart';

class TaskerHomePage extends StatefulWidget {
  const TaskerHomePage({super.key});

  @override
  State<TaskerHomePage> createState() => _TaskerHomePageState();
}

class _TaskerHomePageState extends State<TaskerHomePage>
    with TickerProviderStateMixin {
  final CardSwiperController controller = CardSwiperController();
  final GetStorage storage = GetStorage();
  final ClientServices _clientServices = ClientServices();
  final ProfileController _profileController = ProfileController();
  final AuthenticationController _authController = AuthenticationController();
  final JobPostService jobPostService = JobPostService();
  final JobPostController jobPostController = JobPostController();
  final SettingController _settingController = SettingController();

  AuthenticatedUser? _user;
  String _fullName = "Loading...";
  String _role = "Loading...";
  String _image = "";
  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;
  bool _documentValid = false;
  int? cardNumber;
  bool _isUploadDialogShown = false;
  bool _isLoading = true;
  final GlobalKey _moreVertKey = GlobalKey();
  SettingModel _userPreference = SettingModel();

  List<TaskModel> tasks = [];
  String? _selectedCategory;
  List<String> categories = ['All'];
  final bool _isCategoriesLoading = false;

  bool _showLikeAnimation = false;
  bool _showDislikeAnimation = false;
  AnimationController? _likeAnimationController;
  AnimationController? _dislikeAnimationController;

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
        _fetchUserData(),
        _fetchUserIDImage(),
        fetchSpecialization(),
        _fetchTasks(),
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

      //Checker if User has been already been warned.
      if(!mounted) return;

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

  Future<void> fetchSpecialization() async {
    try {
      List<SpecializationModel> fetchedSpecializations =
          await jobPostService.getSpecializations();

      setState(() {
        categories = [
          'All',
          ...fetchedSpecializations.map((spec) => spec.specialization)
        ];
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load categories. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      List<TaskModel> fetchedTasks = await jobPostController.fetchAllJobs();

      setState(() {
        tasks = fetchedTasks;
        cardNumber = tasks.length;
      });
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load jobs. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLikedJob(TaskModel task) async {
    try {
      final result = await jobPostService.saveLikedJob(task.id);
      if (result.containsKey('message') && result['success']) {
        setState(() {
          _showLikeAnimation = true;
        });
        _likeAnimationController?.forward();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception("Failed to like job");
      }
    } catch (e) {
      setState(() {
        _showDislikeAnimation = true;
      });
      _dislikeAnimationController?.forward();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save like. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Account Verification"),
        content: const Text(
            "Please upload your Profile and ID images to complete your account."),
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
                await _fetchTasks();
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
                        // Handle navigation to FAQs
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
                              _fetchTasks();
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
                        color: Color(0xFFB71A4A), fontSize: 10),
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
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFFB71A4A),
                  size: 24,
                ),
              ),
              GestureDetector(
                key: _moreVertKey,
                onTap: () {
                  debugPrint('Menu clicked');
                  _showAnimatedMenu(context);
                },
                child: const Icon(
                  Icons.more_vert,
                  color: Color(0xFFB71A4A),
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
          if (_isLoading || _isCategoriesLoading)
            Center(child: CircularProgressIndicator())
          else if (tasks.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 80, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(
                    "No Jobs Available",
                    style: GoogleFonts.openSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Try adjusting your filters or check back later.",
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _fetchTasks,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF0272B1)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Refresh',
                      style: GoogleFonts.openSans(color: Color(0xFF0272B1)),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(0),
              child: CardSwiper(
                numberOfCardsDisplayed: tasks.length > 3 ? 3 : tasks.length,
                allowedSwipeDirection: AllowedSwipeDirection.only(
                  left: true,
                  right: true,
                ),
                controller: controller,
                cardsCount: tasks.length,
                onSwipe: (previousIndex, targetIndex, swipeDirection) {
                  if (swipeDirection == CardSwiperDirection.left) {
                    setState(() {
                      _showDislikeAnimation = true;
                    });
                    _dislikeAnimationController?.forward();
                    _cardCounter();
                  } else if (swipeDirection == CardSwiperDirection.right) {
                    if (_existingProfileImageUrl == null ||
                        _existingIDImageUrl == null ||
                        _existingProfileImageUrl!.isEmpty ||
                        _existingIDImageUrl!.isEmpty ||
                        !_documentValid) {
                      _showWarningDialog();
                      return false;
                    }
                    _saveLikedJob(tasks[previousIndex]);
                    _cardCounter();
                  }
                  return true;
                },
                cardBuilder:
                    (context, index, percentThresholdX, percentThresholdY) {
                  final task = tasks[index];
                  return Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF0272B1).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      task.taskerSpecialization
                                              ?.specialization ??
                                          'No Specialization',
                                      style: GoogleFonts.openSans(
                                        fontSize: 14,
                                        color: Color(0xFF0272B1),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Text(
                                task.title ?? 'No Title',
                                style: GoogleFonts.openSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                task.description ?? 'No Description',
                                style: GoogleFonts.openSans(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 4,
                              ),
                              SizedBox(height: 16),
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: task.imageUrl != null &&
                                        task.imageUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(
                                          task.imageUrl!,
                                          fit: BoxFit.cover,
                                          width: 150,
                                          height: 150,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: Center(
                                                child: Icon(
                                                  Icons.work_outline_outlined,
                                                  size: 50,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 50,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
                              ),
                              Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₱${NumberFormat("#,##0.00", "en_US").format(task.contactPrice.roundToDouble() ?? 0)}',
                                        style: GoogleFonts.openSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              controller.swipe(
                                                  CardSwiperDirection.left);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shape: CircleBorder(),
                                              fixedSize: Size(50, 50),
                                              padding: EdgeInsets.zero,
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.red,
                                              size: 24,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          ElevatedButton(
                                            onPressed: () {
                                              controller.swipe(
                                                  CardSwiperDirection.right);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
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
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
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
}
