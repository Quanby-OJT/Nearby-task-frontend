import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/tasker_service.dart';
import 'package:flutter_fe/view/business_acc/assignment/task_assignment.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../model/tasker_feedback.dart';
import '../../model/tasker_model.dart';

// In-memory cache for tasks
class TaskCache {
  static List<TaskModel>? _cachedTasks;
  static DateTime? _cacheTimestamp;

  static List<TaskModel>? getTasks() {
    if (_cachedTasks != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!).inMinutes < 5) {
      return _cachedTasks;
    }
    return null;
  }

  static void setTasks(List<TaskModel> tasks) {
    _cachedTasks = tasks;
    _cacheTimestamp = DateTime.now();
  }

  static void clear() {
    _cachedTasks = null;
    _cacheTimestamp = null;
  }
}

class TaskerProfilePage extends StatefulWidget {
  final TaskerModel tasker;
  final int? taskerId;
  final bool isSaved;

  const TaskerProfilePage({
    super.key,
    required this.tasker,
    required this.isSaved,
    required this.taskerId,
  });

  @override
  State<TaskerProfilePage> createState() => _TaskerProfilePageState();
}

class _TaskerProfilePageState extends State<TaskerProfilePage>
    with TickerProviderStateMixin {
  final TaskController taskController = TaskController();
  final ProfileController _profileController = ProfileController();
  final storage = GetStorage();

  AuthenticatedUser? _user;
  String? _role;
  bool _isLoading = true;
  String? _errorMessage;
  final bool _isAssigning = false;
  List<TaskModel>? _preloadedTasks;
  List<TaskerFeedback>? taskerFeedback;
  List<String> skills = [];
  String? _taskerProfileImageUrl;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _initializeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      skills = widget.tasker.skills
              ?.split(',')
              .map((skill) => skill.trim())
              .toList() ??
          [];

      await Future.wait([
        _loadTaskerDetails(),
        _fetchUserData(),
        _preloadClientTasks(),
        getAllTaskerReviews(),
        _fetchTaskerProfileImage(),
      ]);

      setState(() {
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load tasker profile: $e";
        debugPrint("Initialization error: $e");
        debugPrintStack(stackTrace: stackTrace);
      });
    }
  }

  Future<void> _fetchTaskerProfileImage() async {
    try {
      if (widget.tasker.user?.id != null) {
        final taskerService = TaskerService();
        final result =
            await taskerService.getTaskerImages(widget.tasker.user!.id!);

        if (result.containsKey('images') && result['images'] is List) {
          final List<dynamic> images = result['images'];
          if (images.isNotEmpty) {
            final firstImage = images.first;
            if (firstImage is Map && firstImage['image_link'] != null) {
              setState(() {
                _taskerProfileImageUrl = firstImage['image_link'];
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching tasker profile image: $e');
    }
  }

  Future<void> _fetchUserData() async {
    try {
      int userId = storage.read("user_id");
      debugPrint("Fetching user data for user ID: $userId");
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      debugPrint(user.toString());
      setState(() {
        _user = user;
        _role = user?.user.role;
        debugPrint("Role: $_role");
        debugPrint("User ID: ${_user?.user.id}");
      });
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<void> _loadTaskerDetails() async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
      debugPrint("Error loading tasker details: $e");
    }
  }

  Future<void> _preloadClientTasks() async {
    try {
      final tasks = await _fetchClientTasks();
      if (mounted) {
        setState(() {
          _preloadedTasks = tasks;
        });
      }
    } catch (e) {
      debugPrint("Error preloading tasks: $e");
    }
  }

  Future<List<TaskModel>> _fetchClientTasks() async {
    try {
      final cachedTasks = TaskCache.getTasks();
      if (cachedTasks != null) {
        debugPrint("Using cached tasks");
        return cachedTasks;
      }

      final clientServices = ClientServices();
      final String? clientId = await clientServices.getUserId();
      if (clientId == null) {
        debugPrint("Client ID is null");
        return [];
      }

      final tasks = await taskController.getCreatedTasksByClient(
          context, int.parse(clientId));
      TaskCache.setTasks(tasks);
      return tasks;
    } catch (e) {
      debugPrint("Error fetching client tasks: $e");
      return [];
    }
  }

  Future<void> getAllTaskerReviews() async {
    try {
      final taskerId = widget.tasker.id;
      final taskerService = TaskerService();
      final taskerReviews = await taskerService.getTaskerFeedback(taskerId);
      debugPrint(taskerReviews.toString());

      setState(() {
        taskerFeedback = taskerReviews;
      });
    } catch (e, stackTrace) {
      debugPrint("Error fetching tasker reviews: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _assignTask(TaskerModel tasker) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TaskAssignmentScreen(tasker: tasker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFB71A4A),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Container(
                    margin: EdgeInsets.all(24),
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Oops! Something went wrong',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _initializeData,
                          icon: Icon(Icons.refresh),
                          label: Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFB71A4A),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: CustomScrollView(
                      slivers: [
                        _buildModernAppBar(),
                        _buildStatsSection(),
                        _buildAboutSection(),
                        // _buildSkillsSection(),
                        // _buildBasicInfoSection(),
                        _buildActionButtons(),
                        _buildReviewsSection(),
                        SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 320,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFB71A4A),
                Color(0xFFE91E63),
                Color(0xFF9C27B0),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/pattern.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              // Profile content
              Positioned(
                bottom: 40,
                left: 24,
                right: 24,
                child: Column(
                  children: [
                    // Profile image with border and shadow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _taskerProfileImageUrl != null
                              ? NetworkImage(_taskerProfileImageUrl!)
                              : (widget.tasker.user?.image != null &&
                                      widget.tasker.user!.image
                                          .toString()
                                          .isNotEmpty
                                  ? NetworkImage(
                                      widget.tasker.user!.image.toString())
                                  : null),
                          backgroundColor: Colors.grey[100],
                          child: (_taskerProfileImageUrl == null &&
                                  (widget.tasker.user?.image == null ||
                                      widget.tasker.user!.image
                                          .toString()
                                          .isEmpty))
                              ? Text(
                                  "${widget.tasker.user?.firstName?[0] ?? ''}${widget.tasker.user?.lastName?[0] ?? ''}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB71A4A),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Name with better typography
                    Text(
                      "${widget.tasker.user?.firstName ?? ''} ${widget.tasker.user?.lastName ?? ''}",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    // Role badge with modern design
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        widget.tasker.user?.role ?? 'Tasker',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    // Specialization
                    if (widget.tasker.taskerSpecialization?.specialization !=
                        null)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.tasker.taskerSpecialization!.specialization,
                          style: GoogleFonts.poppins(
                            color: Color(0xFFB71A4A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildModernStatItem(
              widget.tasker.rating?.toStringAsFixed(1) ?? "4.5",
              "Rating",
              Icons.star_rounded,
              Color(0xFFFFB300),
            ),
            _buildDivider(),
            _buildModernStatItem(
              taskerFeedback?.length.toString() ?? "0",
              "Reviews",
              Icons.rate_review_rounded,
              Color(0xFF4CAF50),
            ),
            _buildDivider(),
            _buildModernStatItem(
              widget.tasker.wage != null
                  ? "₱${NumberFormat("#,##0", "en_US").format(widget.tasker.wage)}"
                  : "₱500",
              widget.tasker.payPeriod ?? "Per Hour",
              Icons.payments_rounded,
              Color(0xFFB71A4A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatItem(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[200],
      margin: EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildAboutSection() {
    return SliverToBoxAdapter(
      child: _buildModernSectionCard(
        "Bio",
        Icons.person_outline,
        [
          Text(
            widget.tasker.bio ?? "This tasker hasn't added a bio yet.",
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (!widget.isSaved) ...[
              Expanded(
                child: _buildModernActionButton(
                  onPressed: _likeTasker,
                  icon: Icons.favorite_rounded,
                  label: 'Like Tasker',
                  color: Color(0xFFE91E63),
                  isSecondary: true,
                ),
              ),
            ],
            if (widget.isSaved && _user != null) ...[
              Expanded(
                child: _buildModernActionButton(
                  onPressed: () => _assignTask(widget.tasker),
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'Assign Task',
                  color: Color(0xFFB71A4A),
                  isSecondary: false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isSecondary,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isSecondary
            ? null
            : LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isSecondary ? Colors.white : null,
        borderRadius: BorderRadius.circular(16),
        border: isSecondary ? Border.all(color: color, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isAssigning ? null : onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: isSecondary ? color : Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return SliverToBoxAdapter(
      child: _buildModernSectionCard(
        "Client Reviews",
        Icons.rate_review_rounded,
        taskerFeedback != null && taskerFeedback!.isNotEmpty
            ? taskerFeedback!
                .map((feedback) => _buildModernReviewItem(
                    "${feedback.client.user?.firstName ?? ''} ${feedback.client.user?.lastName ?? ''}",
                    feedback.comment,
                    feedback.rating.toInt()))
                .toList()
            : [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 12),
                      Text(
                        "No reviews yet",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        "This tasker is new to the platform",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildModernSectionCard(
      String title, IconData icon, List<Widget> children) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFB71A4A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Color(0xFFB71A4A), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernSkillChip(String skill) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFB71A4A).withOpacity(0.1),
            Color(0xFFE91E63).withOpacity(0.1)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFB71A4A).withOpacity(0.3)),
      ),
      child: Text(
        skill,
        style: GoogleFonts.poppins(
          color: Color(0xFFB71A4A),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildModernReviewItem(String reviewer, String comment, int rating) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFB71A4A),
                child: Text(
                  reviewer.isNotEmpty ? reviewer[0].toUpperCase() : 'U',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewer.isNotEmpty ? reviewer : 'Anonymous',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Color(0xFFFFB300),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            comment,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _likeTasker() async {
    try {
      final clientServices = ClientServices();
      final result = await clientServices.saveLikedTasker(widget.tasker.id);

      if (result.containsKey('message')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.favorite, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Successfully liked tasker!",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFFE91E63),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      } else {
        _showErrorSnackBar("Failed to like tasker. Please try again.");
      }
    } catch (e) {
      _showErrorSnackBar("An error occurred: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
