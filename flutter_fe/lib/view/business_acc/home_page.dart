import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/business_acc/tasker_profile_page.dart';
import 'package:flutter_fe/view/error/missing_information.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:flutter_fe/view/nav/user_navigation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dropdown_search/dropdown_search.dart';

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
  final JobPostService jobPostService = JobPostService();
  final ClientServices _clientServices = ClientServices();
  final AuthenticationController _authController = AuthenticationController();
  List<UserModel> tasker = [];
  List<String> specialization = [];
  String? _errorMessage;
  int? cardNumber = 0;

  AuthenticatedUser? _user;
  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;
  bool _documentValid = false;

  bool _isLoading = true;
  bool _isUploadDialogShown = false;
  bool _showButton = false;

  double _currentRating = 0;

  String? _selectedSpecialization;
  List<String> _specializations = ['All'];
  bool _isSpecializationsLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSpecialization();
    _fetchTasker();
    _fetchUserIDImage();
  }

  Future<void> fetchSpecialization() async {
    try {
      setState(() {
        _isSpecializationsLoading = true;
      });

      // Fetch specializations from the service
      List<SpecializationModel> fetchedSpecializations =
          await jobPostService.getSpecializations();

      if (fetchedSpecializations.isNotEmpty) {
        setState(() {
          _specializations = [
            'All',
            ...fetchedSpecializations.map((spec) => spec.specialization)
          ];
          debugPrint("Fetched Specializations: $_specializations");
          _isSpecializationsLoading = false;
        });
      } else {
        debugPrint("No specializations found in the database.");
        setState(() {
          _isSpecializationsLoading = false;
        });
      }
    } catch (error) {
      debugPrint("Error fetching specializations: $error");
      setState(() {
        _isSpecializationsLoading = false;
      });
    }
  }

  Future<void> _fetchTasker() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      List<UserModel> tasks;
      if (_selectedSpecialization == null || _selectedSpecialization == 'All') {
        tasks = await _clientServices.fetchAllTasker();
      } else {
        tasks = await _clientServices
            .fetchTaskersBySpecialization(_selectedSpecialization!);
      }

      setState(() {
        if (tasks.isEmpty) {
          debugPrint(
              "No taskers returned for specialization: $_selectedSpecialization");
        } else {
          debugPrint("Successfully fetched ${tasks.length} taskers");
        }
        _isLoading = false;
        tasker = tasks;
        cardNumber = tasks.length;
      });
    } catch (error, stackTrace) {
      debugPrint("Error fetching taskers: $error");
      debugPrint(stackTrace.toString());

      setState(() {
        _isLoading = false;
        _errorMessage =
            "Failed to load taskers. Please check your connection and try again.";
      });
    }
  }

  void _cardCounter() {
    if (cardNumber == 0) {
      setState(() {
        _showButton = false;
      });
      return;
    } else {
      setState(() {
        cardNumber = cardNumber! - 1;
        _showButton = true;
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
      setState(() {
        _showButton = false;
      });

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

          // if (_existingProfileImageUrl != null && _existingIDImageUrl != null) {
          //   _showButton = true;
          // }
        });
      }
    } catch (e) {
      debugPrint("Error fetching ID image: $e");
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
                MaterialPageRoute(builder: (context) => const FillUpClient()),
              );
              if (result == true) {
                setState(() {
                  _isLoading = true;
                });

                await _fetchUserIDImage();
                await _fetchTasker();
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

  void _showRatingDialog(UserModel tasker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rate ${tasker.firstName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How would you rate your experience?'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _currentRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentRating = index + 1;
                    });
                  },
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _submitRating(tasker.id!, _currentRating);
              Navigator.pop(context);
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRating(int taskerId, double rating) async {
    try {
      final result = await _clientServices.submitTaskerRating(taskerId, rating);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchTasker(); // Refresh the tasker list to show updated rating
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to submit rating'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting rating'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: NavUserScreen(),
        body: Stack(children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                if (_isSpecializationsLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 35, vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          "Specialization: ",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFF0272B1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownSearch<String>(
                              items: _specializations,
                              selectedItem: _selectedSpecialization ?? 'All',
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  hintText: "Select Specialization",
                                  border: InputBorder.none,
                                ),
                              ),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedSpecialization = newValue;
                                });
                                _fetchTasker();
                              },
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: "Search Specialization",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null)
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
                      ElevatedButton(
                          onPressed: _fetchTasker, child: Text('Retry')),
                    ],
                  ))
                else if (tasker.isEmpty && tasker.length < 2)
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
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
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
                  Expanded(
                    child: CardSwiper(
                      numberOfCardsDisplayed: tasker.isEmpty
                          ? 1
                          : tasker.length, // Conditionally set
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
                        } else if (swipeDirection ==
                            CardSwiperDirection.right) {
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
                      cardBuilder: (context, index, percentThresholdX,
                          percentThresholdY) {
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
                                      child: task.image != null &&
                                              task.image!.isNotEmpty
                                          ? Image.network(
                                              task.image!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 80,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              },
                                            )
                                          : Center(
                                              child: Icon(
                                                Icons.person,
                                                size: 80,
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: EdgeInsets.only(
                                            bottom: 60, left: 16),
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
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                ...List.generate(5, (index) {
                                                  double rating = 4.5;
                                                  return Icon(
                                                    index < rating.floor()
                                                        ? Icons.star
                                                        : index < rating
                                                            ? Icons.star_half
                                                            : Icons.star_border,
                                                    color: Colors.amber,
                                                    size: 20,
                                                  );
                                                }),
                                                SizedBox(width: 8),
                                                Text(
                                                  "4.5",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
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
                                    Positioned(
                                      bottom: 16,
                                      right: 16,
                                      child: Column(
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
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          SizedBox(height: 10),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              if (_existingProfileImageUrl ==
                                                      null ||
                                                  _existingIDImageUrl == null ||
                                                  _existingProfileImageUrl!
                                                      .isEmpty ||
                                                  _existingIDImageUrl!
                                                      .isEmpty ||
                                                  !_documentValid) {
                                                _showWarningDialog();
                                              } else {
                                                _showRatingDialog(task);
                                              }
                                            },
                                            icon: Icon(Icons.star,
                                                color: Colors.white),
                                            label: Text('Rate Tasker'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.amber,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              if (_existingProfileImageUrl ==
                                                      null ||
                                                  _existingIDImageUrl == null ||
                                                  _existingProfileImageUrl!
                                                      .isEmpty ||
                                                  _existingIDImageUrl!
                                                      .isEmpty ||
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
                                              backgroundColor:
                                                  Color(0xFF0272B1),
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ],
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
            )
        ]));
  }
}
