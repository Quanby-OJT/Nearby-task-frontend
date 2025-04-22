import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/nav/user_navigation.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final CardSwiperController controller = CardSwiperController();
  final GetStorage storage = GetStorage();
  final ClientServices _clientServices = ClientServices();
  final ProfileController _profileController = ProfileController();
  final JobPostService jobPostService = JobPostService();

  AuthenticatedUser? _user;
  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;
  bool _documentValid = false;
  int? cardNumber;

  bool _isUploadDialogShown = false;
  bool _isLoading = true;

  List<TaskModel> tasks = [];
  String? _selectedCategory;
  List<String> categories = ['All'];
  bool _isCategoriesLoading = false;

  bool _showLikeAnimation = false;
  bool _showDislikeAnimation = false;
  AnimationController? _likeAnimationController;
  AnimationController? _dislikeAnimationController;

  @override
  void initState() {
    super.initState();
    _fetchUserIDImage();
    _fetchTasks();
    fetchSpecialization();

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

  Future<void> fetchSpecialization() async {
    try {
      setState(() {
        _isCategoriesLoading = true;
      });

      List<SpecializationModel> fetchedSpecializations =
          await jobPostService.getSpecializations();

      setState(() {
        categories = [
          'All',
          ...fetchedSpecializations.map((spec) => spec.specialization)
        ];
        _isCategoriesLoading = false;
      });
    } catch (error) {
      setState(() {
        _isCategoriesLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load categories. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchTasks() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<TaskModel> fetchedTasks;
      if (_selectedCategory == null || _selectedCategory == 'All') {
        fetchedTasks = await jobPostService.fetchAllJobs();
      } else {
        fetchedTasks =
            await jobPostService.fetchJobsBySpecialization(_selectedCategory!);
      }

      setState(() {
        tasks = fetchedTasks;
        cardNumber = tasks.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load jobs. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveLikedJob(TaskModel task) async {
    try {
      if (task.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cannot like job: Invalid job ID"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await jobPostService.saveLikedJob(task.id!);
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

  Future<void> _fetchUserIDImage() async {
    try {
      int userId = int.parse(storage.read('user_id').toString());
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      final response = await _clientServices.fetchUserIDImage(userId);

      if (response['success']) {
        setState(() {
          _user = user;
          _existingProfileImageUrl = user?.user.image;
          _existingIDImageUrl = response['url'];
          _documentValid = response['status'];
          _isLoading = false;
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
            "Please upload your Profile and ID images to complete your account."),
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
                await _fetchTasks();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: NavUserScreen(),
      body: Stack(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: DropdownSearch<String>(
                      items: categories,
                      selectedItem: _selectedCategory ?? 'All',
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: InputBorder.none,
                          hintText: "Search Specialization",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                        _fetchTasks();
                      },
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: "Type to search...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                        itemBuilder: (context, item, isSelected) {
                          return ListTile(
                            title: Text(
                              item,
                              style: TextStyle(
                                color: isSelected
                                    ? Color(0xFF0272B1)
                                    : Colors.black,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                          );
                        },
                      ),
                      filterFn: (item, filter) {
                        return item
                            .toLowerCase()
                            .contains(filter.toLowerCase());
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading || _isCategoriesLoading)
            Center(child: CircularProgressIndicator(color: Color(0xFF0272B1)))
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
              padding: const EdgeInsets.all(16.0),
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
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.65,
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
                                      task.specialization ??
                                          'No Specialization',
                                      style: GoogleFonts.openSans(
                                        fontSize: 14,
                                        color: Color(0xFF0272B1),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\₱${NumberFormat("#,##0.00", "en_US").format(task.contactPrice?.roundToDouble() ?? 0)}',
                                    style: GoogleFonts.openSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
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
                              Expanded(
                                child: Text(
                                  task.description ?? 'No Description',
                                  style: GoogleFonts.openSans(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 4,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.location_pin,
                                      size: 20, color: Colors.grey[600]),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      task.location ?? 'No Location',
                                      style: GoogleFonts.openSans(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
      floatingActionButton: tasks.isNotEmpty
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () => controller.swipe(CardSwiperDirection.left),
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.close),
                ),
                SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: () => controller.swipe(CardSwiperDirection.right),
                  backgroundColor: Colors.green,
                  child: Icon(Icons.favorite),
                ),
              ],
            )
          : null,
    );
  }
}
