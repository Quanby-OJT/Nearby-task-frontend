import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/business_acc/assignment/task_assignment.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../model/tasker_feedback.dart';
import '../../model/tasker_model.dart';
import '../../service/tasker_service.dart';

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

class _TaskerProfilePageState extends State<TaskerProfilePage> {
  final TaskController taskController = TaskController();
  final ProfileController _profileController = ProfileController();
  final storage = GetStorage();

  AuthenticatedUser? _user;
  String? _role;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAssigning = false;
  List<TaskModel>? _preloadedTasks;
  List<TaskerFeedback>? taskerFeedback;
  List<String> skills = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      skills = widget.tasker.skills.split(',');

      await Future.wait([
        _loadTaskerDetails(),
        _fetchUserData(),
        _preloadClientTasks(),
        getAllTaskerReviews(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load tasker profile: $e";
        debugPrint("Initialization error: $e");
        debugPrintStack(stackTrace: stackTrace);
      });
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

      final tasks =
          await taskController.getCreatedTasksByClient(int.parse(clientId));
      TaskCache.setTasks(tasks);
      return tasks;
    } catch (e) {
      debugPrint("Error fetching client tasks: $e");
      return [];
    }
  }

  Future<List<TaskModel>> _filterAvailableTasks(
      List<TaskModel> tasks, int taskerId) async {
    debugPrint(
        "Filtering ${tasks.length} available tasks for tasker $taskerId");
    final jobPostService = JobPostService();
    try {
      final assignmentStatuses = await Future.wait(
        tasks.map((task) async {
          try {
            final userId = await storage.read('user_id');
            debugPrint("Checking task ${task.id} for tasker $taskerId");
            return await jobPostService.hasTaskEverBeenAssignedToTasker(
                task.id, taskerId, userId! as int);
          } catch (e) {
            debugPrint("Error checking task ${task.id}: $e");
            return false;
          }
        }),
      );

      return tasks
          .asMap()
          .entries
          .where((entry) => !assignmentStatuses[entry.key])
          .map((entry) => entry.value)
          .toList();
    } catch (e) {
      debugPrint("Error in _filterAvailableTasks: $e");
      return tasks;
    }
  }

  Future<TaskModel?> _showTaskSelectionDialog(List<TaskModel> tasks) async {
    return showDialog<TaskModel>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Center(
          child: Text(
            'Select a Task to Assign',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF03045E),
            ),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: tasks.length > 3 ? 300 : null,
          child: tasks.isEmpty
              ? const Text("No available tasks to assign.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          task.title ?? 'Untitled Task',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          task.description ?? 'No description',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        trailing: Text(
                          '\$${task.contactPrice ?? 0}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(task),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
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

  // Future<void> _assignTask(TaskerModel tasker) async {
  //   if (_isAssigning) return;

  //   debugPrint(
  //       "Filtering available tasks for tasker ${tasker.id} and client ${_user?.user.id}");

  //   debugPrint("Assigning task to tasker ${tasker.id}");
  //   setState(() {
  //     _isAssigning = true;
  //   });

  //   try {
  //     List<TaskModel> clientTasks =
  //         _preloadedTasks ?? await _fetchClientTasks();

  //     if (clientTasks.isEmpty) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('You have no active tasks to assign.'),
  //           backgroundColor: Colors.orange,
  //         ),
  //       );
  //       return;
  //     }

  //     final availableTasks =
  //         await _filterAvailableTasks(clientTasks, widget.tasker.id);

  //     debugPrint(
  //         "Available tasks: ${clientTasks.length} tasks ${widget.tasker.id}");

  //     if (availableTasks.isEmpty) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('All your active tasks are already assigned.'),
  //           backgroundColor: Colors.orange,
  //         ),
  //       );
  //       return;
  //     }

  //     final selectedTask = await _showTaskSelectionDialog(availableTasks);
  //     if (selectedTask == null) return;

  //     final clientServices = ClientServices();
  //     final String? clientId = await clientServices.getUserId();
  //     if (clientId == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Unable to identify client. Please log in again.'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //       return;
  //     }

  //     OverlayEntry? loadingOverlay;
  //     try {
  //       loadingOverlay = OverlayEntry(
  //         builder: (context) => Container(
  //           color: Colors.black45,
  //           child: const Center(child: CircularProgressIndicator()),
  //         ),
  //       );
  //       if (mounted) Overlay.of(context).insert(loadingOverlay);

  //       final result = await taskController.assignTask(
  //         selectedTask.id,
  //         int.parse(clientId),
  //         tasker.id ?? 0,
  //         _role ?? 'client',
  //       );

  //       final isSuccess = !result.toLowerCase().contains('already') &&
  //           !result.toLowerCase().contains('error') &&
  //           !result.toLowerCase().contains('failed');

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(result),
  //           backgroundColor: isSuccess ? Colors.green : Colors.red,
  //           duration: const Duration(seconds: 3),
  //         ),
  //       );

  //       if (isSuccess) {
  //         final jobPostService = JobPostService();
  //         jobPostService.updateAssignmentCache(
  //             selectedTask.id, tasker.id ?? 0, true, clientId);
  //         TaskCache.clear();
  //         _preloadClientTasks();
  //       }
  //     } finally {
  //       loadingOverlay?.remove();
  //     }
  //   } catch (e) {
  //     debugPrint("Error in _assignTask: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Failed to assign task: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   } finally {
  //     if (mounted) setState(() => _isAssigning = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0272B1),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 300,
                      floating: false,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF0272B1),
                                    Color(0xFFE3F2FD),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 20,
                              left: 20,
                              right: 20,
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundImage:
                                        widget.tasker.user?.image != null &&
                                                widget.tasker.user!.image
                                                    .toString()
                                                    .isNotEmpty
                                            ? NetworkImage(widget
                                                .tasker.user!.image
                                                .toString())
                                            : null,
                                    backgroundColor: Colors.white,
                                    child: widget.tasker.user?.image == null ||
                                            widget.tasker.user!.image
                                                .toString()
                                                .isEmpty
                                        ? Text(
                                            "${widget.tasker.user?.firstName[0]}${widget.tasker.user?.lastName[0]}",
                                            style: GoogleFonts.poppins(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0272B1),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "${widget.tasker.user?.firstName} ${widget.tasker.user?.lastName}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      widget.tasker.user!.role,
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF0272B1),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem("4.8", "Rating", Icons.star),
                            _buildStatItem(taskerFeedback!.length.toString(),
                                "Jobs", Icons.work),
                            _buildStatItem("2 yrs", "Experience", Icons.timer),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSectionCard(
                        "About",
                        [
                          Text(
                            "Experienced tasker specializing in various home services with a commitment to quality and customer satisfaction.",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSectionCard(
                        "Contact Information",
                        [
                          _buildInfoRow(
                              Icons.email, "Email", widget.tasker.user!.email),
                          _buildInfoRow(
                              Icons.phone, "Phone", "+63 XXX XXX XXXX"),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSectionCard(
                        "Basic Information",
                        [
                          _buildInfoRow(
                              Icons.badge, "ID", "#${widget.tasker.id}"),
                          _buildInfoRow(Icons.work, "Specialization",
                              widget.tasker.specialization),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSectionCard(
                        "Skills & Expertise",
                        [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: skills.map((skill) {
                              return _buildSkillChip(skill);
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!widget.isSaved)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isAssigning
                                      ? null
                                      : () {
                                          _likeTasker();
                                        },
                                  icon: const Icon(Icons.favorite_border,
                                      color: Colors.white),
                                  label: const Text('Like'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.isSaved && _user != null)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isAssigning
                                      ? null
                                      // : () => _assignTask(widget.tasker),
                                      : () => _assignTask(widget.tasker),
                                  icon: const Icon(Icons.assignment_turned_in,
                                      color: Colors.white),
                                  label: const Text('Assign Task'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0272B1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: taskerFeedback != null &&
                              taskerFeedback!.isNotEmpty
                          ? _buildSectionCard(
                              "Reviews from Other Clients",
                              taskerFeedback!
                                  .map((feedback) => _buildReviewItem(
                                      "${feedback.client.user!.firstName} ${feedback.client.user!.lastName}",
                                      feedback.comment,
                                      feedback.rating.toInt()))
                                  .toList())
                          : _buildSectionCard(
                              "Reviews", [const Text("No reviews yet.")]),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF0272B1), size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0272B1),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0272B1),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0272B1), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Chip(
      label: Text(skill),
      backgroundColor: const Color(0xFFE3F2FD),
      labelStyle: GoogleFonts.poppins(
        color: const Color(0xFF0272B1),
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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

  void _likeTasker() async {
    try {
      final clientServices = ClientServices();
      final result = await clientServices.saveLikedTasker(widget.tasker.id);

      if (result.containsKey('message')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Tasker liked successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? "Failed to like tasker"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to like tasker: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
