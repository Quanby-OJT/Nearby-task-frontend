import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:flutter_fe/model/verification_model.dart';
import 'package:flutter_fe/view/business_acc/edit_task_page.dart';
import 'package:flutter_fe/view/task/task_archive.dart';
import 'package:flutter_fe/view/task/task_cancelled.dart';
import 'package:flutter_fe/view/task/task_confirmed.dart';
import 'package:flutter_fe/view/task/task_declined.dart';
import 'package:flutter_fe/view/task/task_finished.dart';
import 'package:flutter_fe/view/task/task_ongoing.dart';
import 'package:flutter_fe/view/task/task_pending.dart';
import 'package:flutter_fe/view/task/task_rejected.dart';
import 'package:flutter_fe/view/task/task_review.dart';
import 'package:flutter_fe/view/verification/verification_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/service/tasker_service.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/view/business_acc/business_task_detail.dart';
import 'package:flutter_fe/view/business_acc/task_creation/add_task.dart';
import 'package:flutter_fe/view/task/task_disputed.dart';
import 'package:intl/intl.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class JobPostPage extends StatefulWidget {
  const JobPostPage({super.key});

  @override
  State<JobPostPage> createState() => _JobPostPageState();
}

class _JobPostPageState extends State<JobPostPage>
    with SingleTickerProviderStateMixin {
  // Controllers
  final TaskController _taskController = TaskController();
  final JobPostService _jobPostService = JobPostService();
  final ClientServices _clientServices = ClientServices();
  final ProfileController _profileController = ProfileController();
  final GlobalKey<PopupMenuButtonState> _moreVertKey =
      GlobalKey<PopupMenuButtonState>();
  final Connectivity _connectivity = Connectivity();

  final GetStorage _storage = GetStorage();
  final TextEditingController _searchController = TextEditingController();
  late final PageController _pageController;
  late final TabController _tabController;
  late SharedPreferences _prefs;
  bool _isOfflineMode = false;

  // Data
  List<TaskModel> _clientTasks = [];
  List<TaskModel> _filteredTasksManagement = [];
  List<TaskFetch> _clientTasksTasker = [];
  List<TaskFetch> _filteredTasksStatus = [];
  List<String> _specializations = [];
  String? _currentFilterManagement;
  String? _currentFilterStatus;
  AuthenticatedUser? _user;
  String? _profileImageUrl;
  String? _idImageUrl;
  final bool _isDocumentValid = false;
  bool _isLoading = true;
  final bool _showButton = false;
  bool _isUploadDialogShown = false;

  // Add tasker profile images cache
  final Map<int, String> _taskerProfileImages = {};

  VerificationModel? _existingVerification;
  String? _verificationStatus;
  final bool _isIdVerified = false;
  final bool _isSelfieVerified = false;
  final bool _isDocumentsUploaded = false;
  final bool _isGeneralInfoCompleted = false;
  String? _idType;
  final Map<String, dynamic> _userInfo = {};
  final GetStorage storage = GetStorage();
  // Task management and status filters
  static const List<String> _taskManagementFilters = [
    'All',
    'Available',
    'Already Taken',
    'On Hold',
    'Closed',
  ];

  static const List<String> _taskStatusFilters = [
    'All',
    'Pending',
    'Available',
    'Confirmed',
    'Ongoing',
    'Review',
    'Completed',
    'Cancelled',
    'Disputed',
    'Rejected',
    'Closed',
    'Declined'
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(_filterTasks);
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await _initializeSharedPreferences();
    await _checkInternetConnection();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _pageController.dispose();
    _searchController
      ..removeListener(_filterTasks)
      ..dispose();
    super.dispose();
  }

  // Handle tab changes to sync with PageView
  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _pageController.animateToPage(
      _tabController.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Initialize data by fetching user info, specializations, and tasks
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      await _all();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error occurred",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
      _initializeData();
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
      // Load cached tasks for management view
      final cachedManagementTasks = _prefs.getString('cached_management_tasks');
      if (cachedManagementTasks != null) {
        final List<dynamic> tasksData = json.decode(cachedManagementTasks);
        setState(() {
          _clientTasks =
              tasksData.map((data) => TaskModel.fromJson(data)).toList();
          _filteredTasksManagement = List.from(_clientTasks);
          debugPrint(
              "Loaded ${_clientTasks.length} management tasks from cache");
        });
      }

      // Load cached tasks for status view
      final cachedStatusTasks = _prefs.getString('cached_status_tasks');
      if (cachedStatusTasks != null) {
        final List<dynamic> tasksData = json.decode(cachedStatusTasks);
        setState(() {
          _clientTasksTasker =
              tasksData.map((data) => TaskFetch.fromJson(data)).toList();
          _filteredTasksStatus = List.from(_clientTasksTasker);
          debugPrint(
              "Loaded ${_clientTasksTasker.length} status tasks from cache");
        });
      }

      // Load cached specializations
      final cachedSpecializations =
          _prefs.getStringList('cached_specializations');
      if (cachedSpecializations != null) {
        setState(() {
          _specializations = cachedSpecializations;
          debugPrint(
              "Loaded ${_specializations.length} specializations from cache");
        });
      }

      // Load cached verification status
      _verificationStatus = _prefs.getString('cached_verification_status');

      // Load cached tasker profile images
      final cachedTaskerImages =
          _prefs.getString('cached_tasker_profile_images');
      if (cachedTaskerImages != null) {
        final Map<String, dynamic> imageData = json.decode(cachedTaskerImages);
        setState(() {
          _taskerProfileImages.clear();
          imageData.forEach((key, value) {
            _taskerProfileImages[int.parse(key)] = value.toString();
          });
          debugPrint(
              "Loaded ${_taskerProfileImages.length} tasker profile images from cache");
        });
      }
    } catch (e) {
      debugPrint("Error loading cached data: $e");
    }
  }

  Future<void> _saveDataToCache() async {
    try {
      if (_clientTasks.isNotEmpty) {
        await _prefs.setString('cached_management_tasks',
            json.encode(_clientTasks.map((t) => t.toJson()).toList()));
        debugPrint("Saved ${_clientTasks.length} management tasks to cache");
      }

      if (_clientTasksTasker.isNotEmpty) {
        await _prefs.setString('cached_status_tasks',
            json.encode(_clientTasksTasker.map((t) => t.toJson()).toList()));
        debugPrint("Saved ${_clientTasksTasker.length} status tasks to cache");
      }

      if (_specializations.isNotEmpty) {
        await _prefs.setStringList('cached_specializations', _specializations);
        debugPrint("Saved ${_specializations.length} specializations to cache");
      }

      if (_verificationStatus != null) {
        await _prefs.setString(
            'cached_verification_status', _verificationStatus!);
        debugPrint("Saved verification status to cache");
      }

      if (_taskerProfileImages.isNotEmpty) {
        await _prefs.setString(
            'cached_tasker_profile_images', json.encode(_taskerProfileImages));
        debugPrint(
            "Saved ${_taskerProfileImages.length} tasker profile images to cache");
      }
    } catch (e) {
      debugPrint("Error saving data to cache: $e");
    }
  }

  Future<void> _all() async {
    if (!_isOfflineMode) {
      await Future.wait([
        _fetchSpecializations(),
        _fetchTasksManagement(),
        _fetchTasksStatus(),
        _checkVerificationStatus(),
      ]);
      // Fetch tasker profile images after tasks are loaded
      if (_clientTasksTasker.isNotEmpty) {
        await _fetchTaskerProfileImages();
      }
      await _saveDataToCache();
    } else {
      await _loadCachedData();
    }
  }

  // Fetch specializations
  Future<void> _fetchSpecializations() async {
    try {
      final fetchedSpecializations = await _jobPostService.getSpecializations();
      setState(() {
        _specializations =
            fetchedSpecializations.map((spec) => spec.specialization).toList();
      });
    } catch (e) {
      _showErrorSnackBar('Error fetching specializations: $e');
    }
  }

  // Fetch tasks for management view
  Future<void> _fetchTasksManagement() async {
    final userId = _storage.read('user_id');
    if (userId == null) {
      setState(() {
        _clientTasks = [];
        _filteredTasksManagement = [];
      });
      return;
    }

    try {
      final tasks =
          await _taskController.getJobsforClient(context, userId) ?? [];
      setState(() {
        _clientTasks = tasks;
        _filteredTasksManagement = List.from(tasks);
        _filterTasks();
      });
    } catch (e) {
      _showErrorSnackBar('Error fetching tasks: $e');
    }
  }

  // Fetch tasks for status view
  Future<void> _fetchTasksStatus() async {
    try {
      final tasks = await _taskController.getTaskClient(context);

      debugPrint('Fetched ${tasks.length} tasks for status view');
      setState(() {
        _clientTasksTasker = tasks as List<TaskFetch>;
        _filteredTasksStatus = List.from(_clientTasksTasker);
        _filterTasks();
      });

      debugPrint(
          'Set ${_clientTasksTasker.length} tasks in _clientTasksTasker');

      // Debug first few tasks
      for (int i = 0; i < _clientTasksTasker.length && i < 3; i++) {
        final task = _clientTasksTasker[i];
        debugPrint('Task $i: ${task.toString()}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error while rendering tasks for status view: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showErrorSnackBar(
          'An error occurred while displaying your tasks. Please Try Again.');
    }
  }

  // Fetch tasker profile images for all taskers in the task list
  Future<void> _fetchTaskerProfileImages() async {
    try {
      debugPrint("Starting to fetch profile images for taskers in task list");
      debugPrint("_clientTasksTasker length: ${_clientTasksTasker.length}");
      final Set<int> taskerIds = {};

      // Collect unique tasker IDs from the task list
      for (final task in _clientTasksTasker) {
        debugPrint(
            "Task ${task.id}: tasker=${task.tasker}, taskerId=${task.taskerId}");
        debugPrint("Task ${task.id}: tasker.user=${task.tasker?.user}");
        debugPrint("Task ${task.id}: tasker.user.id=${task.tasker?.user?.id}");

        int? taskerId;

        // Try different ways to get the tasker ID
        if (task.tasker?.user?.id != null) {
          taskerId = task.tasker!.user!.id!;
          debugPrint("✅ Found tasker ID via task.tasker.user.id: $taskerId");
        } else if (task.taskerId != null) {
          taskerId = task.taskerId!;
          debugPrint("✅ Found tasker ID via task.taskerId: $taskerId");
        } else if (task.tasker?.userId != null) {
          taskerId = task.tasker!.userId;
          debugPrint("✅ Found tasker ID via task.tasker.userId: $taskerId");
        }

        if (taskerId != null) {
          taskerIds.add(taskerId);
          debugPrint("Added tasker ID: $taskerId");
        } else {
          debugPrint("❌ Task ${task.id} has no tasker ID available");
        }
      }

      debugPrint(
          "Found ${taskerIds.length} unique taskers to fetch images for: $taskerIds");

      for (final taskerId in taskerIds) {
        // Skip if already cached
        if (_taskerProfileImages.containsKey(taskerId)) {
          debugPrint("Tasker $taskerId image already cached");
          continue;
        }

        try {
          debugPrint("Fetching images for tasker ID: $taskerId");
          final taskerService = TaskerService();
          final result = await taskerService.getTaskerImages(taskerId);
          debugPrint("Raw result for tasker $taskerId: $result");

          if (result.containsKey('images') && result['images'] is List) {
            final List<dynamic> images = result['images'];
            debugPrint("Found ${images.length} images for tasker $taskerId");

            if (images.isNotEmpty) {
              final firstImage = images.first;
              debugPrint("First image data: $firstImage");

              if (firstImage is Map && firstImage['image_link'] != null) {
                final imageUrl = firstImage['image_link'];
                if (mounted) {
                  setState(() {
                    _taskerProfileImages[taskerId] = imageUrl;
                  });
                }
                debugPrint(
                    "✅ Successfully set profile image for tasker $taskerId: $imageUrl");
              } else {
                debugPrint(
                    "❌ First image is not a Map or image_link is null for tasker $taskerId");
              }
            } else {
              debugPrint("❌ No images found for tasker $taskerId");
            }
          } else {
            debugPrint(
                "❌ Result doesn't contain 'images' key or it's not a List for tasker $taskerId");
          }
        } catch (e) {
          debugPrint("❌ Error fetching profile image for tasker $taskerId: $e");
        }
      }

      debugPrint(
          "Finished fetching profile images. Total cached: ${_taskerProfileImages.length}");
      debugPrint("Cached images: $_taskerProfileImages");
    } catch (e) {
      debugPrint("Error in _fetchTaskerProfileImages: $e");
    }
  }

  // Fetch individual tasker profile image on-demand
  Future<void> _fetchSingleTaskerImage(int taskerId) async {
    if (_taskerProfileImages.containsKey(taskerId)) {
      return; // Already cached
    }

    try {
      debugPrint("Lazy loading image for tasker ID: $taskerId");
      final taskerService = TaskerService();
      final result = await taskerService.getTaskerImages(taskerId);

      if (result.containsKey('images') && result['images'] is List) {
        final List<dynamic> images = result['images'];
        if (images.isNotEmpty) {
          final firstImage = images.first;
          if (firstImage is Map && firstImage['image_link'] != null) {
            final imageUrl = firstImage['image_link'];
            if (mounted) {
              setState(() {
                _taskerProfileImages[taskerId] = imageUrl;
              });
            }
            debugPrint("✅ Lazy loaded image for tasker $taskerId: $imageUrl");
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Error lazy loading image for tasker $taskerId: $e");
    }
  }

  // Get tasker profile image decoration with priority logic (similar to home page)
  DecorationImage? _getTaskerProfileImageDecoration(
      TaskFetch task, int? taskerId) {
    // Priority 1: Profile image from tasker_images table (cached)
    if (taskerId != null && _taskerProfileImages.containsKey(taskerId)) {
      final profileImageUrl = _taskerProfileImages[taskerId];
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        debugPrint(
            "Using profile image from tasker_images for tasker $taskerId: $profileImageUrl");
        return DecorationImage(
          image: NetworkImage(profileImageUrl),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            debugPrint('Error loading tasker profile image: $exception');
            if (mounted) {
              setState(() {
                _taskerProfileImages.remove(taskerId); // Clear the failed URL
              });
            }
          },
        );
      }
    }

    // Priority 2: Default user image from user.image field
    final userImage = task.tasker?.user?.image ?? task.tasker?.user?.imageName;
    if (userImage != null && userImage.isNotEmpty && userImage != "Unknown") {
      debugPrint("Using default user image for tasker $taskerId: $userImage");
      return DecorationImage(
        image: NetworkImage(userImage),
        fit: BoxFit.cover,
        onError: (exception, stackTrace) {
          debugPrint('Error loading default user image: $exception');
          // Don't need to clear anything here since it's not cached
        },
      );
    }

    debugPrint(
        "No valid image found for tasker $taskerId, showing person icon");
    return null;
  }

  void _filterTasks() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      // Filter management tasks
      _filteredTasksManagement = _clientTasks.where((task) {
        if (_currentFilterManagement == 'All') return true;
        final matchesSearch =
            (task.title.toLowerCase().contains(query) ?? false) ||
                (task.description.toLowerCase().contains(query) ?? false);
        final matchesStatus = _currentFilterManagement == null ||
            task.status == _currentFilterManagement;
        return matchesSearch && matchesStatus;
      }).toList();

      // Filter status tasks
      _filteredTasksStatus = _clientTasksTasker.where((task) {
        if (_currentFilterStatus == 'All') return true;
        final matchesSearch =
            (task.post_task?.title.toLowerCase().contains(query) ?? false) ||
                (task.post_task?.description.toLowerCase().contains(query) ??
                    false);
        final matchesStatus = _currentFilterStatus == null ||
            task.taskStatus == _currentFilterStatus;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _navigateToTaskDetail(TaskModel task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BusinessTaskDetail(task: task)),
    );
    if (result == true) {
      await _fetchTasksManagement();
    }
  }

  void _showWarningDialog() {
    if (_isUploadDialogShown) return;
    setState(() => _isUploadDialogShown = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        title: Text(
          'Complete Your Profile',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Please upload your profile and ID images to post tasks.',
          style: GoogleFonts.poppins(
              fontSize: 14, color: Colors.black, fontWeight: FontWeight.w300),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isUploadDialogShown = false);
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w500),
            ),
          ),
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
                );
                if (result == true) {
                  await _all();
                }
                setState(() => _isUploadDialogShown = false);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showWarningDialogOffline() {
    if (_isUploadDialogShown) return;
    setState(() => _isUploadDialogShown = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        title: Text(
          'Offline Mode',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Cannot add new tasks while offline.',
          style: GoogleFonts.poppins(
              fontSize: 14, color: Colors.black, fontWeight: FontWeight.w300),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: const Color(0xFFB71A4A),
            ),
            child: TextButton(
              child: Text('OK',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isUploadDialogShown = false);
                setState(() => _isUploadDialogShown = false);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModalManagement() {
    _showFilterModal(
      title: 'Filter Tasks',
      filters: _taskManagementFilters,
      currentFilter: _currentFilterManagement,
      onFilterSelected: (value) {
        setState(() {
          _currentFilterManagement = value;
          _filterTasks();
        });
      },
    );
  }

  void _showFilterModalStatus() {
    _showFilterModal(
      title: 'Filter Task Status',
      filters: _taskStatusFilters,
      currentFilter: _currentFilterStatus,
      onFilterSelected: (value) {
        setState(() {
          _currentFilterStatus = value;
          _filterTasks();
        });
      },
    );
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

        debugPrint('VerificationPage: Result: $result');

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

  void _showFilterModal({
    required String title,
    required List<String> filters,
    required String? currentFilter,
    required ValueChanged<String?> onFilterSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB71A4A),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  return RadioListTile<String>(
                    title:
                        Text(filter, style: GoogleFonts.poppins(fontSize: 14)),
                    value: filter,
                    groupValue: currentFilter,
                    onChanged: (value) {
                      onFilterSelected(value);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskManagementView() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterBar(
          count: _filteredTasksManagement.length,
          onFilterPressed: _showFilterModalManagement,
        ),
        Expanded(
          child: _buildTaskList(
            isLoading: _isLoading,
            tasks: _filteredTasksManagement,
            onRefresh: loadInitialData,
            buildTaskCard: _buildTaskManagementViewCard,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskStatusView() {
    return Column(
      children: [
        _buildSearchBar(hint: 'Search tasks by status...'),
        _buildFilterBar(
          count: _filteredTasksStatus.length,
          filterLabel:
              _currentFilterStatus == 'All' ? '' : _currentFilterStatus,
          onFilterPressed: _showFilterModalStatus,
        ),
        Expanded(
          child: _buildTaskList(
            isLoading: _isLoading,
            tasks: _filteredTasksStatus,
            onRefresh: loadInitialData,
            buildTaskCard: (task) => _buildTaskStatusViewCard(task),
          ),
        ),
      ],
    );
  }

  void _showSelectorModal(BuildContext context, TaskFetch task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          elevation: 8.0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Options',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildModalOption(
                  context,
                  icon: Icons.archive_outlined,
                  title: 'Archive Task',
                  color: Colors.blueAccent,
                  onTap: () async {
                    try {
                      await _taskController.updateTaskStatus(
                          context, task.id, 'Archived');
                      setState(() {
                        // Remove the task from both lists
                        _clientTasksTasker.removeWhere((t) => t.id == task.id);
                        _filteredTasksStatus
                            .removeWhere((t) => t.id == task.id);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Task archived successfully',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(10),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to archive task',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(10),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      debugPrint('Error archiving task: $e');
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildModalOption(
                  context,
                  icon: Icons.delete_outline,
                  title: 'Delete Task',
                  color: Colors.redAccent,
                  onTap: () async {
                    try {
                      await _taskController.updateTaskStatus(
                          context, task.id, 'Deleted');
                      setState(() {
                        // Remove the task from both lists
                        _clientTasksTasker.removeWhere((t) => t.id == task.id);
                        _filteredTasksStatus
                            .removeWhere((t) => t.id == task.id);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Task deleted successfully',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(10),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to delete task',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(10),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      debugPrint('Error deleting task: $e');
                    }
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100], // Light background for contrast
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar({String hint = 'Search tasks...'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          cursorColor: const Color(0xFFB71A4A),
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            prefixIcon: const Icon(
              FontAwesomeIcons.magnifyingGlass,
              color: Color(0xFFB71A4A),
              size: 18,
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Color(0xFFB71A4A),
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar({
    required int count,
    String? filterLabel,
    required VoidCallback onFilterPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count ${filterLabel ?? "tasks"}',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          TextButton.icon(
            onPressed: onFilterPressed,
            icon: const Icon(Icons.filter_list, color: Color(0xFFB71A4A)),
            label: Text('Filter',
                style: GoogleFonts.poppins(color: const Color(0xFFB71A4A))),
          ),
        ],
      ),
    );
  }

  // Reusable task list widget
  Widget _buildTaskList({
    required bool isLoading,
    required List tasks,
    required Future<void> Function() onRefresh,
    required Widget Function(dynamic) buildTaskCard,
  }) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE23670)));
    }
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.screwdriverWrench,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
            ),
            Text(
              'Create a new task to get started!',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFFE23670),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          if (task == null) return const SizedBox.shrink();
          return buildTaskCard(task);
        },
      ),
    );
  }

  // Build task card for management view
  Widget _buildTaskManagementViewCard(dynamic task) {
    final status = task.status ?? 'Unknown';
    final statusColor = status == 'Available'
        ? Colors.blue
        : status == 'Already Taken'
            ? Colors.green
            : status == 'On Hold'
                ? Colors.orange
                : status == 'Closed'
                    ? Colors.grey[500]
                    : Colors.red;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToTaskDetail(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: statusColor,
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFFE23670)),
                        onPressed: () =>
                            task.ableToDelete == true && task.status != 'Closed'
                                ? _navigateToEditTask(task)
                                : task.status == 'Closed'
                                    ? _cannotEditTaskClosed(task)
                                    : _cannotEditTask(task),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete, color: Color(0xFFB71A4A)),
                        onPressed: () => task.ableToDelete == true
                            ? _confirmDeleteTask(task.id)
                            : _cannotDeleteTask(task),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.title ?? 'Untitled Task',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 8),
              _buildTaskInfoRow(
                icon: FontAwesomeIcons.locationPin,
                iconColor: Colors.red[400],
                text: task.address?.formattedAddress ?? 'N/A',
              ),
              const SizedBox(height: 8),
              _buildTaskInfoRow(
                icon: FontAwesomeIcons.pesoSign,
                iconColor: Colors.green[400],
                text: '${task.contactPrice ?? 0}',
              ),
              const SizedBox(height: 8),
              _buildTaskInfoRow(
                icon: FontAwesomeIcons.screwdriverWrench,
                iconColor: const Color(0xFFE23670),
                text: task.taskerSpecialization?.specialization ?? 'N/A',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskStatusViewCard(TaskFetch task) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToTaskStatusPage(task),
        // onLongPress: () {
        //   _showSelectorModal(context, task);
        // },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTaskReceived(task),
                  _buildTaskStatusColor(task),
                ],
              ),
              const SizedBox(height: 8),
              _buildTaskInfo(task),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTaskStatusPage(TaskFetch task) {
    final statusPages = {
      'Completed': TaskFinished(taskInformation: task),
      'Pending': TaskPending(taskInformation: task),
      'Confirmed': TaskConfirmed(taskInformation: task),
      'Cancelled': TaskCancelled(taskInformation: task),
      'Ongoing': TaskOngoing(taskInformation: task, role: _user?.user.role),
      'Review': TaskReview(taskInformation: task),
      'Declined': TaskDeclined(taskInformation: task),
      'Rejected': TaskRejected(taskInformation: task),
      'Disputed': TaskDisputed(taskInformation: task),
    };

    final page = statusPages[task.taskStatus];
    if (page != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      ).then((_) {
        _initializeData();
      });
    }
  }

  Widget _buildTaskStatusColor(TaskFetch task) {
    final statusColors = {
      'Pending': Colors.grey[500],
      'Completed': Colors.green,
      'Confirmed': Colors.green,
      'Dispute Settled': Colors.green,
      'Ongoing': Colors.blue,
      'Interested': Colors.blue,
      'Review': Colors.yellow,
      'Disputed': Colors.orange,
      'Rejected': Colors.red,
      'Declined': Colors.red,
      'Cancelled': Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: statusColors[task.taskStatus] ?? Colors.red,
      ),
      child: Text(
        task.taskStatus,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // Build task received timestamp
  Widget _buildTaskReceived(TaskFetch task) {
    final updatedDateTime = DateTime.parse(task.updatedAt.toString());
    final formattedDate = DateFormat('MMM d, yyyy').format(updatedDateTime);
    final difference = DateTime.now().toUtc().difference(updatedDateTime);
    final timeAgo = difference.inMinutes < 60
        ? '${difference.inMinutes} ${difference.inMinutes == 1 ? 'min' : 'mins'} ago'
        : '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formattedDate, style: GoogleFonts.poppins(fontSize: 14)),
        Text(timeAgo,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTaskInfo(TaskFetch task, {double size = 40.0}) {
    // Find the tasker ID using multiple fallback methods
    int? taskerId;
    if (task.tasker?.user?.id != null) {
      taskerId = task.tasker!.user!.id!;
    } else if (task.taskerId != null) {
      taskerId = task.taskerId!;
    } else if (task.tasker?.userId != null) {
      taskerId = task.tasker!.userId;
    }

    // Try to lazy load the tasker image if not cached
    if (taskerId != null && !_taskerProfileImages.containsKey(taskerId)) {
      debugPrint("Attempting lazy load for tasker $taskerId");
      _fetchSingleTaskerImage(taskerId);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              image: _getTaskerProfileImageDecoration(task, taskerId),
            ),
            child: _getTaskerProfileImageDecoration(task, taskerId) == null
                ? const Icon(Icons.person, color: Colors.grey, size: 24)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (task.post_task?.title.length ?? 0) > 20
                  ? '${task.post_task?.title.substring(0, 20)}...'
                  : task.post_task?.title ?? 'Untitled Task',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              "${task.tasker?.user?.firstName ?? 'Unknown'} ${task.tasker?.user?.lastName ?? 'Unknown'}",
              style: GoogleFonts.poppins(
                  color: const Color(0xFFB71A4A), fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskInfoRow({
    required IconData icon,
    required Color? iconColor,
    required String text,
  }) {
    return Row(
      children: [
        FaIcon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteTask(int taskId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        title: Text(
          'Delete Task',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this task?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: const Color(0xFFB71A4A)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Color(0xFFB71A4A),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _taskController.deleteTask(taskId);
        await _fetchTasksManagement();
      } catch (e) {
        _showErrorSnackBar('Error deleting task: $e');
      }
    }
  }

  Future<void> _cannotDeleteTask(TaskModel task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        title: Text(
          'Cannot Delete Task',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: Text(
          'This task is currently being worked on by a tasker. Please wait for the task to be completed before deleting it.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: Colors.grey[800],
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Color(0xFFB71A4A),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cannotEditTask(TaskModel task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        title: Text(
          'Cannot Edit Task',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: Text(
          'This task is currently being worked on by a tasker. Please wait for the task to be completed before editing it.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: Colors.grey[800],
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Color(0xFFB71A4A),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cannotEditTaskClosed(TaskModel task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        title: Text(
          'Cannot Edit Closed Task',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: Text(
          'This task is already closed. You cannot edit it. Please create a new task instead.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: Colors.grey[800],
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Color(0xFFB71A4A),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAnimatedMenu(BuildContext context) {
    final RenderBox renderBox =
        _moreVertKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    final double menuWidth = screenWidth / 1.5;
    final double leftPosition =
        position.dx + renderBox.size.width - menuWidth - 10;
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
                      Icons.archive_outlined,
                      "Task Archive",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  TaskArchivePage(role: 'Client')),
                        );
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

    overlayState.insert(overlayEntry);
  }

  Widget buildListTile(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFFB71A4A),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        ),
        onTap: onTap);
  }

  void _navigateToEditTask(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditTaskPage(task: task)),
    ).then((value) => _fetchTasksManagement());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Tasks',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB71A4A),
          ),
        ),
        // actions: [
        //   IconButton(
        //     key: _moreVertKey,
        //     icon: Icon(
        //       Icons.more_vert,
        //       color: Color(0xFFB71A4A),
        //     ),
        //     onPressed: () {
        //       _showAnimatedMenu(context);
        //     },
        //   ),
        // ],
        centerTitle: true,
        backgroundColor: Colors.grey[100],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_isOfflineMode ? 80 : 48),
          child: Column(
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
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFE23670),
                indicatorWeight: 3,
                labelColor: const Color(0xFFB71A4A),
                unselectedLabelColor: Colors.grey[600],
                labelStyle: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
                tabs: const [
                  Tab(text: 'Manage Tasks'),
                  Tab(text: 'Task Status'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => _tabController.animateTo(index),
        children: [
          _buildTaskManagementView(),
          _buildTaskStatusView(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _isOfflineMode == true
                  ? () => _showWarningDialogOffline()
                  : _isOfflineMode == false &&
                          (_verificationStatus == 'Review' ||
                              _verificationStatus == 'Active')
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AddTask()),
                          ).then((value) => _fetchTasksManagement())
                      : _showWarningDialog,
              backgroundColor: const Color(0xFFE23670),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(FontAwesomeIcons.plus, color: Colors.white),
            )
          : null,
    );
  }
}
