import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/view/business_acc/tasker_profile_page.dart';
import 'package:flutter_fe/view/error/missing_information.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:flutter_fe/view/nav/user_navigation.dart';
import 'package:get_storage/get_storage.dart';

import '../../controller/profile_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProfileController _profileController = ProfileController();
  final GetStorage storage = GetStorage();
  final CardSwiperController controller = CardSwiperController();
  final ClientServices _clientServices = ClientServices();
  final AuthenticationController _authController = AuthenticationController();
  List<UserModel> tasker = [];
  String? _errorMessage;
  int? cardNumber = 0;

  AuthenticatedUser? _user;
  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;
  bool _documentValid = false;

  bool _isLoading = true;
  bool _isUploadDialogShown = false;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _fetchTasker();
    _fetchUserIDImage();
  }

  Future<void> _fetchTasker() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      ClientServices clientServices = ClientServices();
      debugPrint("Fetching taskers...");
      List<UserModel> tasks = await clientServices.fetchAllTasker();

      if (!mounted) return;

      if (tasks.isEmpty) {
        debugPrint("No taskers returned from service");
      } else {
        debugPrint("Successfully fetched ${tasks.length} taskers");
      }

      setState(() {
        _isLoading = false;
        tasker = tasks;
        cardNumber = tasks.length;
      });
    } catch (e, st) {
      debugPrint("Error fetching taskers: $e");
      debugPrint(st.toString());

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Failed to load taskers. Please check your connection and try again.";
        });
      }
    }
  }

  void _cardCounter() {
    if (cardNumber == 0) {
      return;
    } else {
      setState(() {
        cardNumber = cardNumber! - 1;
      });
    }
  }

  Future<void> _saveLikedTasker(UserModel task) async {
    try {
      debugPrint("Printing...$task");

      ClientServices clientServices = ClientServices();

      final result = await clientServices.saveLikedTasker(task.id!);

      if (result.containsKey('message')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Show error indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("$e");
      debugPrintStack();

      // Show error indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save like. Please try again."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _fetchUserIDImage() async {
    try {
      int userId = int.parse(storage.read('user_id').toString());
      if (userId == null) {
        debugPrint("User ID not found in storage po");
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
      debugPrint(user.toString());

      final response = await _clientServices.fetchUserIDImage(userId);

      if (response['success']) {
        setState(() {
          _user = user;
          _existingProfileImageUrl = user?.user.image;
          _existingIDImageUrl = response['url'];
          _documentValid = response['status'];

          _isLoading = false;

          debugPrint(
              "Successfully loaded user image" + _existingProfileImageUrl!);
          debugPrint("Successfully loaded ID image" + _existingIDImageUrl!);

          if (_existingProfileImageUrl != null && _existingIDImageUrl != null) {
            _showButton = true;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching ID image: $e");
    }
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
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
                MaterialPageRoute(builder: (context) => const FillUpClient()),
              );
              if (result == true) {
                setState(() {
                  _isLoading = true;
                  // Keep the flag true since we're refreshing data
                });

                await _fetchUserIDImage(); // Refresh user profile and ID image data
                await _fetchTasker(); // Refresh tasker data if needed
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
                // Reset the flag when user cancels
                setState(() {
                  _isUploadDialogShown = false;
                });
              },
              child: Text('Cancel')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NavUserScreen(),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(onPressed: _fetchTasker, child: Text('Retry')),
              ],
            ))
          else if (tasker.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_search,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "No taskers found",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "We couldn't find any taskers at the moment.\nPlease try again later.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchTasker,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0272B1),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Refresh'),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 35, top: 20),
                    child: SizedBox(
                      width: 200,
                      child: Text(
                        "Swipe right to like, left to skip",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CardSwiper(
                    allowedSwipeDirection: AllowedSwipeDirection.only(
                      left: true,
                      right: true,
                    ),
                    controller: controller,
                    cardsCount: tasker.length,
                    onSwipe: (previousIndex, targetIndex, swipeDirection) {
                      if (swipeDirection == CardSwiperDirection.left) {
                        debugPrint(
                            "Swiped Left (Disliked) for tasker: ${tasker[previousIndex].firstName}");
                        _cardCounter();
                      } else if (swipeDirection == CardSwiperDirection.right) {
                        debugPrint(
                            "Swiped Right (Liked) for tasker: ${tasker[previousIndex].firstName}");

                        if (_existingProfileImageUrl == null ||
                            _existingIDImageUrl == null ||
                            _existingProfileImageUrl!.isEmpty ||
                            _existingIDImageUrl!.isEmpty ||
                            !_documentValid) {
                          _showWarningDialog();
                          return false;
                        }
                        _saveLikedTasker(tasker[previousIndex]);
                        _cardCounter();
                      }
                      return true;
                    },
                    cardBuilder:
                        (context, index, percentThresholdX, percentThresholdY) {
                      final task = tasker[index];
                      return Center(
                        child: SizedBox(
                          height: double.infinity,
                          child: FlipCard(
                            direction: FlipDirection.HORIZONTAL,
                            front: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.asset(
                                      'assets/images/image1.jpg',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding:
                                          EdgeInsets.only(bottom: 60, left: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.8),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      // padding: EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${task.firstName} ${task.lastName}",
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "Tap to see more details",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            back: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${task.firstName} ${task.lastName}",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0272B1),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Email: ${task.email}",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Role: ${task.role}",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 20),
                                    Center(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          if (_existingProfileImageUrl ==
                                                  null ||
                                              _existingIDImageUrl == null ||
                                              _existingProfileImageUrl!
                                                  .isEmpty ||
                                              _existingIDImageUrl!.isEmpty ||
                                              !_documentValid) {
                                            _showWarningDialog();
                                          } else {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TaskerProfilePage(
                                                        tasker: task),
                                              ),
                                            );
                                          }
                                        },
                                        icon: Icon(Icons.person,
                                            color: Colors.white),
                                        label: Text('View Full Profile'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF0272B1),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Spacer(),
                                    Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.touch_app,
                                            color: Colors.grey,
                                            size: 32,
                                          ),
                                          Text(
                                            'Tap to flip back',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          if (_showButton)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        controller.swipe(CardSwiperDirection.left);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: CircleBorder(),
                          fixedSize: Size(60, 60),
                          padding: EdgeInsets.zero),
                      child: Center(
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          weight: 4,
                          size: 30,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        controller.swipe(CardSwiperDirection.right);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: CircleBorder(),
                        fixedSize: Size(60, 60),
                        padding: EdgeInsets.zero, // Remove default padding
                      ),
                      child: Center(
                        // Use Center instead of Align
                        child: Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
