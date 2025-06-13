import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/view/business_acc/business_acc_main_page.dart';
import 'package:flutter_fe/view/business_acc/tasker_profile_page.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../model/tasker_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  final ClientServices _clientServices = ClientServices();
  final TextEditingController _searchController = TextEditingController();

  final ProfileController _profileController = ProfileController();
  final GetStorage storage = GetStorage();
  bool _isLoading = true;
  List<TaskerModel> _likedTasks = [];
  List<TaskerModel> _filteredTasks = [];
  String? _errorMessage;
  int savedTasksCount = 0;
  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;
  AuthenticatedUser? _user;
  String _role = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_filterTaskFunction);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Wait for both data fetching operations to complete
      await Future.wait([
        _loadLikedTasks(),
        _fetchUserIDImage(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e, st) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error initializing data. Please try again.';
        debugPrint('Initialization error: $e');
        debugPrint(st.toString());
      });
    }
  }

  void _filterTaskFunction() {
    String query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredTasks = _likedTasks.where((task) {
        return (task.user?.firstName.toLowerCase().contains(query) ?? false) ||
            (task.user?.email.toLowerCase().contains(query) ?? false);
      }).toList();
      savedTasksCount = _filteredTasks.length;
    });
  }

  Future<void> _loadLikedTasks() async {
    try {
      final userId = await _clientServices.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _errorMessage = 'Please log in again to view your liked tasks';
        });
        return;
      }

      final likedTasks = await _clientServices.fetchUserLikedTasks();
      debugPrint("Liked Tasks: $likedTasks");
      setState(() {
        _likedTasks = likedTasks;
        _filteredTasks = List.from(_likedTasks);
        savedTasksCount = _filteredTasks.length;
      });
    } catch (e, st) {
      setState(() {
        _errorMessage = 'Error loading liked tasks. Please try again.';
        debugPrint('Load liked tasks error: $e');
        debugPrint(st.toString());
      });
    }
  }

  Future<void> _fetchUserIDImage() async {
    try {
      int userId = int.parse(storage.read('user_id').toString());
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(userId);

      debugPrint("Fetched User accStatus: ${user?.user.accStatus}");
      debugPrint("Fetched User role: ${user?.user.role}");

      final response = await _clientServices.fetchUserIDImage(userId);
      debugPrint("Document response: $response");

      setState(() {
        _user = user;
        _existingProfileImageUrl = user?.user.image;
        _existingIDImageUrl = response['success'] ? response['url'] : null;
        _role = user?.user.role ?? '';

        debugPrint("ID Image URL set to: $_existingIDImageUrl");
        debugPrint("Updated User accStatus in state: ${_user?.user.accStatus}");

        if (_user?.user.accStatus != null) {
          debugPrint(
              "Account status details - Original: '${_user?.user.accStatus}'");
          debugPrint(
              "Account status details - Lowercase: '${_user?.user.accStatus?.toLowerCase()}'");
          debugPrint(
              "Account status details - Trimmed: '${_user?.user.accStatus?.trim()}'");
          debugPrint(
              "Account status details - Trimmed+Lowercase: '${_user?.user.accStatus?.trim().toLowerCase()}'");
        } else {
          debugPrint("Account status is null");
        }
      });
    } catch (e) {
      debugPrint("Error fetching ID image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to fetch ID image.",
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
  }

  Future<void> _unlikeJob(UserModel job) async {
    try {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            title: Text('Remove from Saved Taskers?',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            content: Text(
                'Are you sure you want to remove this tasker from your saved taskers?',
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
                      child: Text('Remove',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ]),
      );

      if (confirm != true) return;

      final result = await _clientServices.unlikeTask(job.id!);
      if (result['success']) {
        setState(() {
          _likedTasks.removeWhere((item) => item.id == job.id);
          _filteredTasks.removeWhere((item) => item.id == job.id);
          savedTasksCount = _filteredTasks.length;
          _loadLikedTasks();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Successfully Unliked Task.",
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to unlike task. Please try again.",
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Saved',
          style: GoogleFonts.poppins(
            color: const Color(0xFFB71A4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                cursorColor: const Color(0xFFB71A4A),
                decoration: InputDecoration(
                    hintText: 'Search taskers...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    prefixIcon: Icon(
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
                    )),
              ),
            ),
          ),
          // Task Count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$savedTasksCount taskers',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // Task List
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Color(0xFFB71A4A)));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFB71A4A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No liked taskers yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => BusinessAccMain()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFB71A4A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Browse Taskers',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _initializeData,
      color: Color(0xFF0272B1),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredTasks.length,
        itemBuilder: (context, index) {
          final tasker = _filteredTasks[index];
          return _buildTaskerCard(tasker);
        },
      ),
    );
  }

  Widget _buildTaskerCard(TaskerModel tasker) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskerProfilePage(
                tasker: tasker,
                isSaved: true,
                taskerId: tasker.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar, Name, and Status Dot
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                            ),
                            child: tasker.user?.image != null &&
                                    tasker.user!.image!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: tasker.user!.image!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                      size: 30,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: 30,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name and Status Dot
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${tasker.user?.firstName ?? 'Unknown'} ${tasker.user?.lastName ?? ''}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: tasker.user?.accStatus == 'Active'
                                        ? Colors.green
                                        : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            if (tasker.user?.email != null &&
                                tasker.user!.email.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  tasker.user!.email,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        )),
                      ],
                    ),
                    // Email
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFB71A4A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Color(0xFFB71A4A),
                        size: 24,
                      ),
                      onPressed: () => _unlikeJob(tasker.user!),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
