import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/business_acc/tasker_profile_page.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:flutter_fe/view/nav/user_navigation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:lottie/lottie.dart';
import 'package:flip_card/flip_card.dart';
import '../../controller/profile_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final ProfileController _profileController = ProfileController();
  final GetStorage storage = GetStorage();
  final CardSwiperController controller = CardSwiperController();
  final JobPostService jobPostService = JobPostService();
  final ClientServices _clientServices = ClientServices();
  final AuthenticationController _authController = AuthenticationController();
  List<AuthenticatedUser> taskers = [];
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

  AnimationController? _likeAnimationController;
  AnimationController? _dislikeAnimationController;
  bool _showLikeAnimation = false;
  bool _showDislikeAnimation = false;

  @override
  void initState() {
    super.initState();
    fetchSpecialization();
    _fetchTaskers();
    _fetchUserIDImage();

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

  void _cardCounter() {
    setState(() {
      cardNumber = cardNumber! - 1;
      _showButton = cardNumber! > 0;
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
        _isSpecializationsLoading = true;
      });

      List<SpecializationModel> fetchedSpecializations =
          await jobPostService.getSpecializations();

      setState(() {
        _specializations = [
          'All',
          ...fetchedSpecializations.map((spec) => spec.specialization)
        ];
        _isSpecializationsLoading = false;
      });
    } catch (error) {
      setState(() {
        _isSpecializationsLoading = false;
      });
    }
  }

  Future<void> _fetchTaskers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      List<UserModel> fetchedTaskers;
      if (_selectedSpecialization == null || _selectedSpecialization == 'All') {
        fetchedTaskers = await _clientServices.fetchAllTasker();
      } else {
        fetchedTaskers = await _clientServices
            .fetchTaskersBySpecialization(_selectedSpecialization!);
      }

      setState(() {
        taskers = fetchedTaskers
            .map((tasker) => AuthenticatedUser(user: tasker))
            .toList();
        cardNumber = fetchedTaskers.length;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Unable to load taskers. Please try again.";
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
            "Upload your Profile and ID images to complete your account."),
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
                await _fetchTaskers();
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
        await _fetchTaskers();
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
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: DropdownSearch<String>(
                      items: _specializations,
                      selectedItem: _selectedSpecialization ?? 'All',
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: InputBorder.none,
                          hintText: "Filter by Specialization",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedSpecialization = newValue;
                        });
                        _fetchTaskers();
                      },
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: "Search Specialization",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading || _isSpecializationsLoading)
            Center(child: CircularProgressIndicator(color: Color(0xFF0272B1)))
          else if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchTaskers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0272B1),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Retry',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            )
          else if (taskers.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search, size: 80, color: Colors.grey[300]),
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _fetchTaskers,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF0272B1)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Refresh',
                        style: TextStyle(color: Color(0xFF0272B1))),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(0),
              child: CardSwiper(
                numberOfCardsDisplayed: taskers.length,
                allowedSwipeDirection: AllowedSwipeDirection.only(
                  left: true,
                  right: true,
                ),
                controller: controller,
                cardsCount: taskers.length,
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
                    _saveLikedTasker(taskers[previousIndex].user);
                    _cardCounter();
                  }
                  return true;
                },
                cardBuilder:
                    (context, index, percentThresholdX, percentThresholdY) {
                  final tasker = taskers[index];
                  return Center(
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: FlipCard(
                        direction: FlipDirection.HORIZONTAL,
                        front: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: tasker.user.image != null &&
                                        tasker.user.image!.isNotEmpty
                                    ? Image.network(
                                        tasker.user.image!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: Icon(
                                                Icons.person,
                                                size: 100,
                                                color: Colors.grey[400],
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
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(20)),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.7),
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
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          ...List.generate(5, (index) {
                                            double rating =
                                                tasker.tasker?.rating ?? 4.5;
                                            return Icon(
                                              index < rating.floor()
                                                  ? Icons.star
                                                  : index < rating
                                                      ? Icons.star_half
                                                      : Icons.star_border,
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
                                        tasker.tasker?.specialization ??
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
                                        builder: (context) => TaskerProfilePage(
                                          tasker: tasker.user,
                                          isSaved: false,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        back: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${tasker.user.firstName} ${tasker.user.lastName}",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0272B1),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.email,
                                        size: 20, color: Colors.grey[600]),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Email: ${tasker.user.email}",
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[800]),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.work,
                                        size: 20, color: Colors.grey[600]),
                                    SizedBox(width: 8),
                                    Text(
                                      "Role: ${tasker.user.role}",
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[800]),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.build,
                                        size: 20, color: Colors.grey[600]),
                                    SizedBox(width: 8),
                                    Text(
                                      "Specialization: ${tasker.tasker?.specialization ?? 'None'}",
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[800]),
                                    ),
                                  ],
                                ),
                                Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        if (_existingProfileImageUrl == null ||
                                            _existingIDImageUrl == null ||
                                            _existingProfileImageUrl!.isEmpty ||
                                            _existingIDImageUrl!.isEmpty ||
                                            !_documentValid) {
                                          _showWarningDialog();
                                        } else {
                                          _showRatingDialog(tasker.user);
                                        }
                                      },
                                      icon: Icon(Icons.star, size: 20),
                                      label: Text('Rate'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TaskerProfilePage(
                                              tasker: tasker.user,
                                              isSaved: false,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.person, size: 20),
                                      label: Text('Profile'),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: Color(0xFF0272B1)),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
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
      floatingActionButton: taskers.isNotEmpty
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
