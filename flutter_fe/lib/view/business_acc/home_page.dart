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
import 'package:flutter_fe/model/verification_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/controller/tasker_controller.dart';
import 'package:flutter_fe/view/address/set-up_address.dart';
import 'package:flutter_fe/view/business_acc/notif_screen.dart';
import 'package:flutter_fe/view/configuration/configuration_list.dart';
import 'package:flutter_fe/view/profile/profile_screen.dart';
import 'package:flutter_fe/view/service_acc/notif_screen.dart';
import 'package:flutter_fe/view/setting/setting.dart';
import 'package:flutter_fe/view/business_acc/tasker_profile_page.dart';
import 'package:flutter_fe/view/verification/verification_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'package:flutter_fe/service/api_service.dart';
import 'package:flutter_fe/service/tasker_service.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../profile/legal_terms_and_conditions.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage>
    with TickerProviderStateMixin {
  final ProfileController _profileController = ProfileController();
  final AuthenticationController _authController = AuthenticationController();
  final Connectivity _connectivity = Connectivity();
  final GetStorage storage = GetStorage();
  final CardSwiperController controller = CardSwiperController();
  final JobPostService jobPostService = JobPostService();
  final ClientServices _clientServices = ClientServices();
  final TaskerController _taskerController = TaskerController();
  final SettingController _settingController = SettingController();
  List<MapEntry<int, String>> categories = [];
  Map<String, bool> selectedCategories = {};
  final TaskerController taskerController = TaskerController();

  SettingModel _userPreference = SettingModel();
  AuthenticatedUser? tasker;
  String _role = "Loading...";
  List<AuthenticatedUser> taskers = [];
  List<TaskerFeedback> taskerFeedback = [];
  String? _errorMessage;
  int? cardNumber = 0;
  final Map<int, List<TaskerFeedback>> _taskerFeedbacks = {};
  final Map<int, String?> _taskerProfileImages =
      {}; // Cache for profile images from tasker_images

  AuthenticatedUser? _user;
  String _fullName = "Loading...";
  String _image = "";
  String? _clientProfileImageUrl; // Store client profile image URL
  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;
  final bool _documentValid = false;
  bool _isLoading = true;
  bool _isUploadDialogShown = false;
  final GlobalKey _moreVertKey = GlobalKey();
  List<TaskerModel> fetchedTaskers = [];

  AnimationController? _likeAnimationController;
  AnimationController? _dislikeAnimationController;
  bool _showLikeAnimation = false;
  bool _showDislikeAnimation = false;

  VerificationModel? _existingVerification;
  String? _verificationStatus;
  final bool _isIdVerified = false;
  final bool _isSelfieVerified = false;
  final bool _isDocumentsUploaded = false;
  final bool _isGeneralInfoCompleted = false;
  String? _idType;
  final Map<String, dynamic> _userInfo = {};

  bool _isOfflineMode = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initializeSharedPreferences();
    _checkInternetConnection();

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

  Future<void> _initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _checkInternetConnection() async {
    setState(() {
      _isLoading = true;
    });
    final result = await _connectivity.checkConnectivity();

    if (result.contains(ConnectivityResult.mobile) == true ||
        result.contains(ConnectivityResult.wifi) == true) {
      setState(() {
        _isLoading = false;
        _isOfflineMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Internet connection is available",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          duration: Duration(seconds: 3),
        ),
      );
      _loadAllFunction();
    } else {
      setState(() {
        _isOfflineMode = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              "Using offline mode",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          backgroundColor: Color(0xFFB71A4A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          duration: Duration(seconds: 3),
        ),
      );
      _loadCachedData();
    }
  }

  Future<void> _loadCachedData() async {
    try {
      // Load cached user data
      final cachedUserData = _prefs.getString('cached_user_data');
      if (cachedUserData != null) {
        final userData = json.decode(cachedUserData);
        setState(() {
          _user = AuthenticatedUser.fromJson(userData);
          _fullName = [
            _user?.user.firstName ?? '',
            _user?.user.middleName ?? '',
            _user?.user.lastName ?? '',
          ].where((name) => name.isNotEmpty).join(' ');
          _role = _user?.user.role ?? "Unknown";
          _image = _user?.user.image ?? "Unknown";
        });

        // Load cached client profile image if available
        final cachedClientProfileImage =
            _prefs.getString('cached_client_profile_image');
        if (cachedClientProfileImage != null &&
            cachedClientProfileImage.isNotEmpty) {
          setState(() {
            _clientProfileImageUrl = cachedClientProfileImage;
          });
        }
      }

      // Load cached taskers
      final cachedTaskers = _prefs.getString('cached_taskers');
      if (cachedTaskers != null) {
        final List<dynamic> taskersData = json.decode(cachedTaskers);
        setState(() {
          taskers = taskersData.map((data) {
            final userData = data['user'];
            final taskerData = data['tasker'];

            return AuthenticatedUser(
              user: UserModel.fromJson(userData),
              isClient: data['is_client'] ?? false,
              isTasker: data['is_tasker'] ?? true,
              tasker:
                  taskerData != null ? TaskerModel.fromJson(taskerData) : null,
              client: null,
            );
          }).toList();
          debugPrint("Loaded ${taskers.length} taskers from cache");
        });
      }

      // Load cached verification status
      _verificationStatus = _prefs.getString('cached_verification_status');
    } catch (e) {
      debugPrint("Error loading cached data: $e");
    }
  }

  Future<void> _saveDataToCache() async {
    try {
      if (_user != null) {
        await _prefs.setString(
            'cached_user_data', json.encode(_user!.toJson()));
        debugPrint("Saved user data to cache");
      }

      if (taskers.isNotEmpty) {
        final taskersData = taskers
            .map((t) => {
                  'user': t.user.toJson(),
                  'is_client': t.isClient,
                  'is_tasker': t.isTasker,
                  'tasker': t.tasker?.toJson(),
                  'client': t.client?.toJson(),
                })
            .toList();

        await _prefs.setString('cached_taskers', json.encode(taskersData));
        debugPrint("Saved ${taskers.length} taskers to cache");
      }

      if (_verificationStatus != null) {
        await _prefs.setString(
            'cached_verification_status', _verificationStatus!);
        debugPrint("Saved verification status to cache");
      }

      // Save client profile image to cache
      if (_clientProfileImageUrl != null &&
          _clientProfileImageUrl!.isNotEmpty) {
        await _prefs.setString(
            'cached_client_profile_image', _clientProfileImageUrl!);
        debugPrint("Saved client profile image to cache");
      }
    } catch (e) {
      debugPrint("Error saving data to cache: $e");
    }
  }

  Future<void> _loadAllFunction() async {
    try {
      if (!_isOfflineMode) {
        await Future.wait([
          _fetchUserData(),
          _fetchTaskers(),
          _checkVerificationStatus(),
        ]);

        await _saveDataToCache();
      } else {
        await _loadCachedData();
      }

      setState(() {
        _isLoading = false;
      });

      final response = await _settingController.getLocation();
      setState(() {
        _userPreference = response;
      });

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
            'Verification status check result client: ${jsonEncode(result)}');

        if (result['success'] == true && result['exists'] == true) {
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

      if (user.user.accStatus == "Warn") {
        bool hasShownWarning = storage.read('hasShownWarning') ?? false;
        if (!hasShownWarning) {
          storage.write('hasShownWarning', true);
          showWarnUser();
        }
      } else if (user.user.accStatus == "Ban") {
        showBanUser();
      }

      debugPrint("User Image: ${user.user.image}");

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

        debugPrint("FCM Token: ${_user?.user.fcmToken}");
      });

      // Fetch client profile image if user is a client
      await _fetchClientProfileImage();
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

      // Fetch profile images for all taskers
      await _fetchTaskerProfileImages();

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

  Future<void> _fetchTaskerProfileImages() async {
    debugPrint(
        "Starting to fetch profile images for ${taskers.length} taskers");
    for (final tasker in taskers) {
      if (tasker.user.id != null) {
        try {
          debugPrint("Fetching images for tasker ID: ${tasker.user.id}");
          final taskerService = TaskerService();
          final result = await taskerService.getTaskerImages(tasker.user.id!);
          debugPrint("Raw result for tasker ${tasker.user.id}: $result");

          if (result.containsKey('images') && result['images'] is List) {
            final List<dynamic> images = result['images'];
            debugPrint(
                "Found ${images.length} images for tasker ${tasker.user.id}");

            if (images.isNotEmpty) {
              // Get the first image as profile picture
              final firstImage = images.first;
              debugPrint("First image data: $firstImage");

              if (firstImage is Map && firstImage['image_link'] != null) {
                final imageUrl = firstImage['image_link'];
                setState(() {
                  _taskerProfileImages[tasker.user.id!] = imageUrl;
                });
                debugPrint(
                    "✅ Successfully set profile image for tasker ${tasker.user.id}: $imageUrl");
              } else {
                debugPrint(
                    "❌ First image is not a Map or image_link is null for tasker ${tasker.user.id}");
              }
            } else {
              debugPrint("❌ No images found for tasker ${tasker.user.id}");
            }
          } else {
            debugPrint(
                "❌ Result doesn't contain 'images' key or it's not a List for tasker ${tasker.user.id}");
          }
        } catch (e) {
          debugPrint(
              "❌ Error fetching profile image for tasker ${tasker.user.id}: $e");
        }
      } else {
        debugPrint("❌ Tasker user ID is null");
      }
    }
    debugPrint(
        "Finished fetching profile images. Total cached: ${_taskerProfileImages.length}");
    debugPrint("Cached images: $_taskerProfileImages");
  }

  Future<void> _fetchClientProfileImage() async {
    try {
      final userId = storage.read('user_id');
      if (userId != null && _user?.user.role.toLowerCase() == 'client') {
        debugPrint("Fetching client profile image for user ID: $userId");
        final clientService = ClientServices();
        final result =
            await clientService.getClientImages(int.parse(userId.toString()));

        debugPrint("Client profile image fetch result: $result");

        if (result.containsKey('images') && result['images'] is List) {
          final List<dynamic> images = result['images'];
          if (images.isNotEmpty) {
            final firstImage = images.first;
            if (firstImage is Map && firstImage['image_link'] != null) {
              setState(() {
                _clientProfileImageUrl = firstImage['image_link'];
              });
              debugPrint(
                  '✅ Found client profile image: $_clientProfileImageUrl');

              // Save to cache
              _prefs.setString(
                  'cached_client_profile_image', _clientProfileImageUrl!);
            }
          } else {
            debugPrint('No client profile images found');
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching client profile image: $e');
    }
  }

  DecorationImage? _getProfileImageDecoration() {
    // Prioritize client profile image from client_images table
    if (_clientProfileImageUrl != null && _clientProfileImageUrl!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(_clientProfileImageUrl!),
        fit: BoxFit.cover,
        onError: (exception, stackTrace) {
          debugPrint('Error loading client profile image: $exception');
          setState(() {
            _clientProfileImageUrl = null; // Clear the failed URL
          });
        },
      );
    }
    // Fallback to default user image
    else if (_image != "Unknown" && _image.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(_image),
        fit: BoxFit.cover,
        onError: (exception, stackTrace) {
          setState(() {
            _image = "Unknown";
          });
        },
      );
    }
    return null;
  }

  bool _shouldShowPersonIcon() {
    return (_clientProfileImageUrl == null ||
            _clientProfileImageUrl!.isEmpty) &&
        (_image == "Unknown" || _image.isEmpty);
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: Text("Account Verification",
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
            "Upload your Profile and ID images to complete your account. Verification will follow.",
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
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const LegalTermsAndConditionsScreen()));
                        overlayEntry.remove();
                      },
                    ),
                    // ListTile(
                    //   leading: Icon(
                    //     Icons.settings,
                    //     color: const Color(0xFFB71A4A),
                    //   ),
                    //   title: Text(
                    //     'Configuration',
                    //     style: GoogleFonts.poppins(
                    //       color: Colors.black,
                    //       fontSize: 14,
                    //       fontWeight: FontWeight.w300,
                    //     ),
                    //   ),
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //           builder: (context) => ConfigurationList()),
                    //     ).then((value) => setState(() {
                    //           _fetchTaskers();
                    //         }));
                    //     overlayEntry.remove();
                    //   },
                    // ),
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
                      image: _getProfileImageDecoration(),
                    ),
                    child: _shouldShowPersonIcon()
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
                        color: const Color(0xFFB71A4A), fontSize: 10),
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
              if (_isOfflineMode)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  color: Color(0xFFB71A4A),
                  child: Center(
                    child: Text(
                      "Offline Mode",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFB71A4A),
                        ),
                      )
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
                                      _isOfflineMode
                                          ? "No Taskers Available"
                                          : "No Taskers Available",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      _isOfflineMode
                                          ? "Please connect to the internet to fetch new data."
                                          : "Try adjusting your filters or check back later.",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600]),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 16),
                                    OutlinedButton(
                                      onPressed: _isOfflineMode
                                          ? _checkInternetConnection
                                          : _fetchTaskers,
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
                                      child: Text(
                                          _isOfflineMode
                                              ? 'Check Connection'
                                              : 'Refresh',
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
                                    // Check if account status allows interaction without verification warning
                                    final accountStatus = _user?.user.accStatus;
                                    final userRole = _user?.user.role;

                                    // For Client users, allow interaction if:
                                    // 1. Account status is Review/Active, OR
                                    // 2. Account status is empty/null (default client state), OR
                                    // 3. Verification status is Approved/Review
                                    if (userRole == 'Client' &&
                                        (accountStatus == 'Review' ||
                                            accountStatus == 'Active' ||
                                            accountStatus == null ||
                                            accountStatus == '' ||
                                            _verificationStatus == "Approved" ||
                                            _verificationStatus == "Review")) {
                                      _saveLikedTasker(
                                          taskers[previousIndex].user);
                                      _cardCounter();
                                    } else if (accountStatus == 'Ban' ||
                                        accountStatus == 'Suspended') {
                                      _showWarningDialog();
                                      return false;
                                    }
                                  }
                                  return true;
                                },
                                cardBuilder: (context, index, percentThresholdX,
                                    percentThresholdY) {
                                  final tasker = taskers[index];
                                  final profileImageUrl =
                                      _taskerProfileImages[tasker.user.id];
                                  debugPrint(
                                      "All Taskers in Card: ${tasker.tasker}");
                                  debugPrint(
                                      "Profile image URL for tasker ${tasker.user.id}: $profileImageUrl");

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
                                          // Background image container
                                          Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: Colors.grey[300],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: profileImageUrl != null &&
                                                      profileImageUrl.isNotEmpty
                                                  ? Image.network(
                                                      profileImageUrl,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      headers: {
                                                        'User-Agent':
                                                            'Mozilla/5.0 (compatible; Flutter app)',
                                                      },
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          debugPrint(
                                                              "Image loaded successfully for tasker ${tasker.user.id}");
                                                          return child;
                                                        }
                                                        debugPrint(
                                                            "Loading image for tasker ${tasker.user.id}: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}");
                                                        return Container(
                                                          color:
                                                              Colors.grey[200],
                                                          child: Center(
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                CircularProgressIndicator(
                                                                  color: Color(
                                                                      0xFFB71A4A),
                                                                  value: loadingProgress
                                                                              .expectedTotalBytes !=
                                                                          null
                                                                      ? loadingProgress
                                                                              .cumulativeBytesLoaded /
                                                                          loadingProgress
                                                                              .expectedTotalBytes!
                                                                      : null,
                                                                ),
                                                                SizedBox(
                                                                    height: 8),
                                                                Text(
                                                                  'Loading image...',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                            .grey[
                                                                        600],
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        debugPrint(
                                                            "Error loading profile image for tasker ${tasker.user.id}: $error");
                                                        debugPrint(
                                                            "Image URL: $profileImageUrl");
                                                        debugPrint(
                                                            "Stack trace: $stackTrace");
                                                        return Container(
                                                          color:
                                                              Colors.grey[300],
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .broken_image,
                                                                color: Colors
                                                                    .grey[600],
                                                                size: 60,
                                                              ),
                                                              SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                'Image failed to load',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                          .grey[
                                                                      600],
                                                                  fontSize: 12,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                              SizedBox(
                                                                  height: 4),
                                                              Text(
                                                                'URL: ${profileImageUrl.substring(0, 50)}...',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                          .grey[
                                                                      500],
                                                                  fontSize: 10,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : Container(
                                                      color: Colors.grey[300],
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.person,
// =======
//                                           ClipRRect(
//                                             borderRadius:
//                                                 BorderRadius.circular(20),
//                                             child: tasker.tasker
//                                                             ?.taskerImages ==
//                                                         null ||
//                                                     tasker.tasker!.taskerImages!
//                                                         .isEmpty
//                                                 ? Center(
//                                                     child: Icon(
//                                                       FontAwesomeIcons
//                                                           .screwdriverWrench,
//                                                       size: 150,
//                                                       color: Colors.grey[400],
//                                                     ),
//                                                   )
//                                                 : PageView.builder(
//                                                     itemCount: tasker.tasker!
//                                                         .taskerImages!.length,
//                                                     itemBuilder:
//                                                         (context, imageIndex) {
//                                                       return Image.network(
//                                                         tasker
//                                                             .tasker!
//                                                             .taskerImages![
//                                                                 imageIndex]
//                                                             .toString(),
//                                                         fit: BoxFit.cover,
//                                                         width: double.infinity,
//                                                         height: double.infinity,
//                                                         errorBuilder: (context,
//                                                                 error,
//                                                                 stackTrace) =>
//                                                             Center(
//                                                           child: Icon(
//                                                             Icons.broken_image,
// >>>>>>> qtask-presentation
                                                            color: Colors
                                                                .grey[600],
                                                            size: 80,
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            'No profile image',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[600],
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            top: 0,
                                            bottom: 0,
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
                                                    tasker
                                                            .tasker
                                                            ?.taskerSpecialization
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

  Widget _buildFallbackImage() {
    return Center(
      child: Icon(
        Icons.broken_image,
        color: Colors.grey[400],
        size: 100,
      ),
    );
  }
}
