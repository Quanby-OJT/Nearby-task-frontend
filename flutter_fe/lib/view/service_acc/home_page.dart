import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/nav/user_navigation.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:flutter_fe/view/service_acc/fill_up.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CardSwiperController controller = CardSwiperController();
  final GetStorage storage = GetStorage();

  final ClientServices _clientServices = ClientServices();
  final ProfileController _profileController = ProfileController();
  AuthenticatedUser? _user;
  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;
  bool _documentValid = false;

  bool _isUploadDialogShown = false;
  bool _showButton = false;

  List<TaskModel> tasks = [];
  List<String> searchCategories = [
    'All',
    'Cleaning',
    'Delivery',
    'Repair',
    'Moving'
  ];
  List<String> selectedCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserIDImage();
    _fetchTasks();
  }

//For Displaying the record (record functionality)
  Future<void> _fetchTasks() async {
    try {
      JobPostService jobPostService = JobPostService();
      List<TaskModel> fetchedTasks = await jobPostService.fetchAllJobs();

      print("Raw API Response: $fetchedTasks"); // Print entire response
      print(
          "Parsed tasks count: ${fetchedTasks.length}"); // Check if tasks are parsed

      setState(() {
        tasks = fetchedTasks;
        print(tasks);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching tasks: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLikedJob(TaskModel task) async {
    try {
      debugPrint("Printing...$task");
      if (task.id == null) {
        print("Cannot save task: Task ID is null for task: ${task.title}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cannot like job: Invalid job ID"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      JobPostService jobPostService = JobPostService();

      // Call the service method to save the liked job - now passing an int
      final result = await jobPostService.saveLikedJob(task.id!);

      if (result['success']) {
        // Show success indicator
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
            content: Text(result['message']),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("Error saving liked job: $e");
      debugPrintStack(stackTrace: stackTrace);

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
              int userId = storage.read("user_id");
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FillUpTaskerLogin(userId: userId)),
              );
              if (result == true) {
                setState(() {
                  _isLoading = true;
                  // Keep the flag true since we're refreshing data
                });

                await _fetchUserIDImage(); // Refresh user profile and ID image data
                await _fetchTasks(); // Refresh tasker data if needed
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
      backgroundColor: Color(0xFF0272B1),
      appBar: NavUserScreen(),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 35, top: 20),
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: 200,
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                )
              else if (tasks.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Colors.white70,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No Jobs Available",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Check back later for new opportunities",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchTasks,
                          icon: Icon(Icons.refresh),
                          label: Text("Refresh"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF0272B1),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: CardSwiper(
                    allowedSwipeDirection: AllowedSwipeDirection.only(
                      left: true,
                      right: true,
                    ),
                    controller: controller,
                    cardsCount: tasks.length,
                    onSwipe: (previousIndex, targetIndex, swipeDirection) {
                      if (swipeDirection == CardSwiperDirection.left) {
                        print("Swiped Left (Disliked)");
                      } else if (swipeDirection == CardSwiperDirection.right) {
                        print("Swiped Right (Liked)");
                        if (_existingProfileImageUrl == null ||
                            _existingIDImageUrl == null ||
                            _existingProfileImageUrl!.isEmpty ||
                            _existingIDImageUrl!.isEmpty ||
                            !_documentValid) {
                          _showWarningDialog();
                          return false;
                        }
                        _saveLikedJob(tasks[previousIndex]);
                      }
                      return true;
                    },
                    cardBuilder:
                        (context, index, percentThresholdX, percentThresholdY) {
                      final task = tasks[index];
                      return Center(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 16.0, right: 16.0, bottom: 60),
                            child: Column(
                              spacing: 10,
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '\₱${NumberFormat("#,##0.00", "en_US").format(task.contactPrice!.roundToDouble())}',
                                  style: GoogleFonts.openSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  task.title ?? 'No Title',
                                  style: GoogleFonts.openSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  task.description ?? 'No Description',
                                  style: GoogleFonts.openSans(
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  spacing: 5,
                                  children: [
                                    Icon(
                                      Icons.location_pin,
                                      size: 20,
                                    ),
                                    Text(
                                      task.location ?? "Location",
                                      style: GoogleFonts.openSans(),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          if (!_isLoading && tasks.isNotEmpty && _showButton)
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
