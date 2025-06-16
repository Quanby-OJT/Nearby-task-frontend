import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/controller/job_post_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/setting_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/images_model.dart';
import 'package:flutter_fe/model/setting.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/verification_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/address/set-up_address.dart';
import 'package:flutter_fe/view/business_acc/notif_screen.dart';
import 'package:flutter_fe/view/configuration/configuration_list.dart';
import 'package:flutter_fe/view/profile/profile_screen.dart';
import 'package:flutter_fe/view/service_acc/notif_screen.dart';
import 'package:flutter_fe/view/service_acc/tasker_feedback.dart';
import 'package:flutter_fe/view/setting/setting.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_fe/view/verification/verification_page.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'dart:convert';
import 'package:flutter_fe/service/api_service.dart';

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

  final Map<int, int> _imageSwiperIndex = {};

  AuthenticatedUser? _user;
  String _fullName = "Loading...";
  String _role = "Loading...";
  String _image = "";
  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;
  final bool _documentValid = false;
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

  // Add flip animation controllers and state
  final Map<int, AnimationController> _flipControllers = {};
  final Map<int, bool> _isFlipped = {};
  List<ImagesModel> taskImages = [];
  List<int> imagesToDelete = [];
  List<int> existingImageIds = [];

  VerificationModel? _existingVerification;
  String? _verificationStatus;
  final bool _isIdVerified = false;
  final bool _isSelfieVerified = false;
  final bool _isDocumentsUploaded = false;
  final bool _isGeneralInfoCompleted = false;
  String? _idType;
  final Map<String, dynamic> _userInfo = {};

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
    // Dispose flip controllers
    for (var controller in _flipControllers.values) {
      controller.dispose();
    }
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadAllFunction() async {
    try {
      await Future.wait([
        _fetchUserData(),
        fetchSpecialization(),
        _checkVerificationStatus(),
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
      if (!mounted) return;

      if (user.user.accStatus == "Warn") {
        bool hasShownWarning = storage.read('hasShownWarning') ?? false;
        if (!hasShownWarning) {
          storage.write('hasShownWarning', true);
          showWarnUser();
        }
      } else if (user.user.accStatus == "Ban") {
        showBanUser();
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

  void showWarnUser() {
    showDialog(
        context: context,
        builder: (BuildContext childContext) {
          return AlertDialog(
              content: Row(children: [
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
            ))
          ]));
        });
  }

  void showBanUser() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext childContext) {
          return AlertDialog(
              content: Row(children: [
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
                ))
              ]),
              actions: [
                TextButton(
                    onPressed: () async {
                      await _authController.logout(context, () => mounted);
                    },
                    child: Text(
                      "Log Out",
                      style: GoogleFonts.poppins(
                        color: Color(0xFFB71A4A),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ))
              ]);
        });
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final userId = storage.read('user_id');
      debugPrint('VerificationPage: Retrieved user_id from storage: $userId');
      debugPrint('VerificationPage: user_id type: ${userId.runtimeType}');

      if (userId != null) {
        final parsedUserId = int.parse(userId.toString());
        debugPrint('VerificationPage: Parsed user_id: $parsedUserId');

        final result =
            await ApiService.getTaskerVerificationStatus(parsedUserId);
        debugPrint(
            'Verification status check result tasker: ${jsonEncode(result)}');

        if (result['success'] == true && result['exists'] == true) {
          // User has existing verification data
          if (result['verification'] != null) {
            final verificationData = result['verification'];
            setState(() {
              _verificationStatus = verificationData['acc_status'];
              debugPrint(
                  'VerificationPage: Set _verificationStatus to: $_verificationStatus');
            });
          }
        } else {
          setState(() {
            _verificationStatus = 'Pending';
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking verification status: $e');
      setState(() {
        _verificationStatus = 'Error';
      });
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
      debugPrint("Error fetching specialization: $error");
    }
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch all tasks
      List<TaskModel> fetchedTasks = await jobPostController.fetchAllJobs();

      debugPrint("Fetched Tasks: ${fetchedTasks.length}");

      for (int i = 0; i < fetchedTasks.length; i++) {
        try {
          final images =
              await jobPostService.fetchTaskImages(fetchedTasks[i].id);
          fetchedTasks[i] = TaskModel(
            id: fetchedTasks[i].id,
            title: fetchedTasks[i].title,
            description: fetchedTasks[i].description,
            contactPrice: fetchedTasks[i].contactPrice,
            taskerSpecialization: fetchedTasks[i].taskerSpecialization,
            imageUrls: images,
            urgency: fetchedTasks[i].urgency,
            workType: fetchedTasks[i].workType,
            scope: fetchedTasks[i].scope,
            client: fetchedTasks[i].client,
            address: fetchedTasks[i].address,
            taskBeginDate: fetchedTasks[i].taskBeginDate,
          );
        } catch (e) {
          debugPrint(
              "Error fetching images for task ${fetchedTasks[i].id}: $e");
          fetchedTasks[i] = TaskModel(
            id: fetchedTasks[i].id,
            title: fetchedTasks[i].title,
            description: fetchedTasks[i].description,
            contactPrice: fetchedTasks[i].contactPrice,
            taskerSpecialization: fetchedTasks[i].taskerSpecialization,
            imageUrls: [],
            urgency: fetchedTasks[i].urgency,
            workType: fetchedTasks[i].workType,
            scope: fetchedTasks[i].scope,
          );
        }
      }

      setState(() {
        tasks = fetchedTasks;
        cardNumber = tasks.length;
        // Initialize flip controllers and reset image swiper indices
        for (int i = 0; i < tasks.length; i++) {
          _initializeFlipController(i);
          _imageSwiperIndex[i] = 0; // Reset index for each task
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      debugPrint("Error fetching tasks: $e");
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
      } else {
        throw Exception("Failed to like job");
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: Text("Account Verification",
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
            "Upload your Profile and ID images to complete your account.",
            style:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w300)),
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
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isUploadDialogShown = false;
                  });
                },
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: const Color(0xFFB71A4A),
                ),
                child: TextButton(
                  child: Text('Verify Now',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white)),
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const VerificationPage()),
                    ).then((value) async {
                      await _loadAllFunction();
                    });
                    if (result == true) {
                      setState(() {
                        _isLoading = true;
                      });
                      await _loadAllFunction();
                    } else {
                      setState(() {
                        _isUploadDialogShown = false;
                      });
                    }
                  },
                ),
              ),
            ],
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

  Widget buildListTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFFB71A4A),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        ),
        onTap: onTap);
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
                    buildListTile(
                      FontAwesomeIcons.solidUser,
                      "Profile",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfileScreen()),
                        );
                        overlayEntry.remove();
                      },
                    ),
                    //Implement Here verification Check.
                    buildListTile(FontAwesomeIcons.userCheck, "Verify Account",
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const VerificationPage()),
                      );
                      overlayEntry.remove();
                    }),
                    buildListTile(
                        FontAwesomeIcons.rankingStar, "My Client Ratings", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TaskerFeedbackPage()),
                      );
                      overlayEntry.remove();
                    }),
                    buildListTile(FontAwesomeIcons.question, "FAQs", () {
                      overlayEntry.remove();
                    }),
                    buildListTile(FontAwesomeIcons.ticket, "Referral Code", () {
                      overlayEntry.remove();
                    }),
                    buildListTile(FontAwesomeIcons.book, "Our Handbook", () {
                      overlayEntry.remove();
                    }),
                    buildListTile(FontAwesomeIcons.gear, "Configuration", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ConfigurationList()),
                      ).then((value) => setState(() {
                            _fetchTasks();
                          }));
                      overlayEntry.remove();
                    }),

                    buildListTile(FontAwesomeIcons.gears, "Settings", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingScreen()),
                      ).then((value) => setState(() {
                            _fetchTasks();
                          }));
                      overlayEntry.remove();
                    }),
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
                      setState(() {
                        _isLoading = true;
                      });
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
                    _fullName,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _role,
                    style: GoogleFonts.poppins(
                        color: Color(0xFFB71A4A), fontSize: 10),
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
            Center(child: CircularProgressIndicator(color: Color(0xFFB71A4A)))
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
                      side: BorderSide(color: Color(0xFFB71A4A)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Refresh',
                      style: GoogleFonts.openSans(color: Color(0xFFB71A4A)),
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
                    if (_verificationStatus != "Active" &&
                        _verificationStatus != "Review") {
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
                  _initializeFlipController(index);

                  // Initialize image swiper index if not exists
                  if (!_imageSwiperIndex.containsKey(index)) {
                    _imageSwiperIndex[index] = 0;
                  }

                  return Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 600,
                      child: GestureDetector(
                        onTap: () => _toggleCardFlip(index),
                        child: AnimatedBuilder(
                          animation: _flipControllers[index]!,
                          builder: (context, child) {
                            final isShowingFront =
                                _flipControllers[index]!.value < 0.5;
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(
                                    _flipControllers[index]!.value * 3.14159),
                              child: isShowingFront
                                  ? _buildFrontCard(task, index)
                                  : Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..rotateY(3.14159),
                                      child: _buildBackCard(task, index),
                                    ),
                            );
                          },
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

  // Add method to initialize flip controllers for cards
  void _initializeFlipController(int index) {
    if (!_flipControllers.containsKey(index)) {
      _flipControllers[index] = AnimationController(
        duration: Duration(milliseconds: 600),
        vsync: this,
      );
      _isFlipped[index] = false;
    }
  }

  // Add method to toggle card flip
  void _toggleCardFlip(int index) {
    _initializeFlipController(index);
    if (_isFlipped[index] == true) {
      _flipControllers[index]?.reverse();
      _isFlipped[index] = false;
    } else {
      _flipControllers[index]?.forward();
      _isFlipped[index] = true;
    }
  }

  Widget _buildFrontCard(TaskModel task, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.75;
    final imageHeight = cardHeight * 0.6;

    // Reset image swiper index to 0 when card is built to prevent RangeError
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_imageSwiperIndex[index] != null &&
          task.imageUrls != null &&
          _imageSwiperIndex[index]! >= task.imageUrls!.length) {
        setState(() {
          _imageSwiperIndex[index] = 0;
        });
      }
    });

    return Center(
      child: SizedBox(
        width: screenWidth * 0.95,
        height: cardHeight,
        child: Card(
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image swiper section
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      task.imageUrls != null && task.imageUrls!.isNotEmpty
                          ? CarouselSlider.builder(
                              itemCount: task.imageUrls!.length,
                              itemBuilder: (context, imageIndex, realIndex) {
                                if (imageIndex >= task.imageUrls!.length) {
                                  return _buildNoImagePlaceholder(imageHeight);
                                }
                                final image = task.imageUrls![imageIndex];
                                return Container(
                                  width: double.infinity,
                                  child: Image.network(
                                    image.image_url.isNotEmpty
                                        ? image.image_url
                                        : 'https://via.placeholder.com/150',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: imageHeight,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFB71A4A),
                                          value: progress.expectedTotalBytes !=
                                                  null
                                              ? progress.cumulativeBytesLoaded /
                                                  progress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildNoImagePlaceholder(
                                          imageHeight);
                                    },
                                  ),
                                );
                              },
                              options: CarouselOptions(
                                height: imageHeight,
                                viewportFraction: 1.0,
                                enableInfiniteScroll: false,
                                autoPlay: false,
                                onPageChanged: (imageIndex, reason) {
                                  setState(() {
                                    _imageSwiperIndex[index] = imageIndex;
                                  });
                                },
                              ),
                            )
                          : _buildNoImagePlaceholder(imageHeight),
                      // Flip indicator
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.flip_to_back,
                            color: Color(0xFF0272B1),
                            size: 20,
                          ),
                        ),
                      ),
                      // Dots indicator
                      if (task.imageUrls != null && task.imageUrls!.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: DotsIndicator(
                              dotsCount: task.imageUrls!.length,
                              position: (_imageSwiperIndex[index] ?? 0)
                                  .clamp(0, task.imageUrls!.length - 1)
                                  .toDouble(),
                              decorator: DotsDecorator(
                                activeColor: Color(0xFFB71A4A),
                                color: Colors.white.withOpacity(0.5),
                                size: const Size.square(8.0),
                                activeSize: const Size(12.0, 8.0),
                                activeShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Content section
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(0xFFB71A4A),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: Color(0xFFB71A4A),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            task.taskerSpecialization?.specialization ?? 'All',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(
                          task.title ?? 'No Title',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₱${NumberFormat("#,##0.00", "en_US").format(task.contactPrice.roundToDouble() ?? 0)}',
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      controller
                                          .swipe(CardSwiperDirection.left);
                                    },
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.red[600],
                                      size: 24,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFB71A4A),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Color(0xFFB71A4A).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      controller
                                          .swipe(CardSwiperDirection.right);
                                    },
                                    icon: Icon(
                                      Icons.favorite,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for no-image placeholder
  Widget _buildNoImagePlaceholder(double imageHeight) {
    return Container(
      height: imageHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0272B1).withOpacity(0.8),
            Color(0xFFB71A4A).withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 60,
              color: Colors.white,
            ),
            SizedBox(height: 12),
            Text(
              'No Images Uploaded',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(TaskModel task, int index) {
    return Center(
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            height: 600,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with category and flip icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFFB71A4A),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Color(0xFFB71A4A),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        task.taskerSpecialization?.specialization ?? 'General',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF0272B1).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.flip_to_front,
                        color: Color(0xFF0272B1),
                        size: 20,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),
                Center(
                  child: Text(
                    task.title ?? 'No Title',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                SizedBox(height: 20),

                // Description section
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Container(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Name',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Column(children: [
                              SingleChildScrollView(
                                child: Text(
                                  '${task.client?.user?.firstName} ${task.client?.user?.lastName}' ??
                                      'No client name available for this task.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ]),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  'Location',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Column(children: [
                              SingleChildScrollView(
                                child: Text(
                                  '${task.address?.formattedAddress}' ??
                                      'No location available for this task.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ]),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  'Start Date',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Column(children: [
                              SingleChildScrollView(
                                child: Text(
                                  DateFormat('MMM dd, yyyy HH:mm a').format(
                                          DateTime.parse(
                                              task.taskBeginDate ?? '')) ??
                                      'No start date available for this task.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ]),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  'Description',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Column(children: [
                              SingleChildScrollView(
                                child: Text(
                                  task.description ??
                                      'No description available for this task.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ]),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  'Price',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Column(children: [
                              SingleChildScrollView(
                                child: Text(
                                  '₱${NumberFormat("#,##0.00", "en_US").format(task.contactPrice.roundToDouble() ?? 0)}' ??
                                      'No price available for this task.',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Bottom section with price and actions
                Container(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              onPressed: () {
                                controller.swipe(CardSwiperDirection.left);
                              },
                              icon: Icon(
                                Icons.close,
                                color: Colors.red[600],
                                size: 24,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFB71A4A),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFB71A4A).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                controller.swipe(CardSwiperDirection.right);
                              },
                              icon: Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
