import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/task/task_archive.dart';
import 'package:flutter_fe/view/task/task_cancelled.dart';
import 'package:flutter_fe/view/task/task_confirmed.dart';
import 'package:flutter_fe/view/task/task_declined.dart';
import 'package:flutter_fe/view/task/task_finished.dart';
import 'package:flutter_fe/view/task/task_ongoing.dart';
import 'package:flutter_fe/view/task/task_pending.dart';
import 'package:flutter_fe/view/task/task_rejected.dart';
import 'package:flutter_fe/view/task/task_review.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../model/client_model.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage>
    with SingleTickerProviderStateMixin {
  final TaskController controller = TaskController();
  final JobPostService jobPostService = JobPostService();
  final ClientServices _clientServices = ClientServices();
  final ProfileController _profileController = ProfileController();
  final EscrowManagementController _escrowManagementController =
      EscrowManagementController();
  final GetStorage storage = GetStorage();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<PopupMenuButtonState> _moreVertKey =
      GlobalKey<PopupMenuButtonState>();
  ClientModel? clientModel;
  String? _message;
  final bool _isSuccess = false;
  String? selectedTimePeriod;
  String? selectedUrgency;
  String? selectedSpecialization;
  String selectedWorkType = "Solo";
  List<String> items = ['Day/s', 'Week/s', 'Month/s', 'Year/s'];
  List<String> urgency = ['Non-Urgent', 'Urgent'];
  List<String> workTypes = ['Solo', 'Group'];
  List<String> taskStatuses = [
    'Pending',
    'Completed',
    'Disputed',
    'Interested',
    'Confirmed',
    'Rejected',
    'Declined',
    'Cancelled',
    'Review',
  ];
  List<String> specialization = [];
  List<TaskFetch?> clientTasks = [];
  List<TaskFetch?> filteredTasks = [];
  final Map<String, String> errors = {};
  String? existingProfileImageUrl;
  String? existingIDImageUrl;
  AuthenticatedUser? user;
  bool isLoading = true;

  final bool _isUploadDialogShown = false;
  bool documentValid = false;

  final List<String> _tabStatuses = ["Pending", "Ongoing", "More"];
  late TabController _tabController;
  String? _currentFilter = 'Pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          if (_tabController.index == 0) {
            _currentFilter = 'Pending';
          } else if (_tabController.index == 1) {
            _currentFilter = "Ongoing";
          }
          _filterTasks();
        });
      }
    });
    _loadMethod();
    _searchController.addListener(_filterTasks);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadMethod() async {
    setState(() {
      isLoading = true;
    });
    await Future(() async {
      await fetchSpecialization();
      await _loadSkills();
      await _fetchUserIDImage();
      await fetchCreatedTasks();
      if (mounted) {
        // Ensure widget is still mounted before adding listener
        _searchController.addListener(_filterTasks);
      }
    });
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchSpecialization() async {
    try {
      List<SpecializationModel> fetchedSpecializations =
          await jobPostService.getSpecializations();
      if (mounted) {
        setState(() {
          specialization = fetchedSpecializations
              .map((spec) => spec.specialization)
              .toList();
          debugPrint("Specializations: $specialization");
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Error fetching specializations: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _loadSkills() async {
    try {
      final String response =
          await rootBundle.loadString('assets/tesda_skills.json');
      final data = jsonDecode(response);
      if (mounted) {
        setState(() {
          skills = List<String>.from(data['tesda_skills']);
        });
      }
    } catch (e, stackTrace) {
      print('Error loading skills: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String? selectedSkill;
  List<String> skills = [];

  Future<void> fetchCreatedTasks() async {
    try {
      if (!mounted) return; // Check if the widget is still mounted
      final tasks = await controller.getTask(context);
      debugPrint("All Tasks applied by tasker: $tasks");
      if (mounted) {
        setState(() {
          clientTasks = tasks;
          filteredTasks = List.from(clientTasks);
          debugPrint("Filtered Tasks: $filteredTasks");
        });
        _filterTasks(); // Call filter tasks only if mounted
      }

      debugPrint("Tasker Tasks: ${clientTasks.toString()}");
    } catch (e, stackTrace) {
      debugPrint("Error fetching created tasks: $e");
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        // Check if the widget is still mounted before showing SnackBar
        // Ensure context is still valid
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          //
          SnackBar(
            content: Text("Failed to load tasks. Please try again."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadMethod,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  void _filterTasks() {
    String query = _searchController.text.trim().toLowerCase();
    if (mounted) {
      setState(() {
        filteredTasks = clientTasks.where((task) {
          if (task == null) return false;
          bool matchesSearch = (task.taskDetails!.title
                      .toLowerCase()
                      .contains(query) ??
                  false) ||
              (task.taskDetails!.description.toLowerCase().contains(query) ??
                  false);
          bool matchesStatus =
              _currentFilter == null || task.taskStatus == _currentFilter;
          return matchesSearch && matchesStatus;
        }).toList();
      });
    }
  }

  Future<void> _fetchUserIDImage() async {
    try {
      int userId = int.parse(storage.read('user_id').toString());
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      final response = await _clientServices.fetchUserIDImage(userId);

      if (response['success']) {
        if (mounted) {
          setState(() {
            user = user;
            existingProfileImageUrl = user?.user.image;
            existingIDImageUrl = response['url'];
            documentValid = response['status'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching ID image: $e");
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(16),
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
              SizedBox(height: 16),
              Center(
                child: Text(
                  'Filter Tasks',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB71A4A)),
                ),
              ),
              SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: taskStatuses.length,
                itemBuilder: (context, index) {
                  final status = taskStatuses[index];
                  return RadioListTile<String>(
                    title: Text(
                      status,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    value: status,
                    groupValue: _currentFilter,
                    onChanged: (value) {
                      setState(() {
                        _currentFilter = value;
                        _filterTasks();
                      });
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
                                  TaskArchivePage(role: 'Tasker')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Task',
          style: GoogleFonts.poppins(
            color: const Color(0xFFB71A4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
        backgroundColor: Colors.grey[100],
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB71A4A),
              ),
            )
          : clientTasks.isEmpty
              ? Center(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              FontAwesomeIcons.screwdriverWrench,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks yet. Click "Apply" after saving your desired task.',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            )
                          ])))
              : Column(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
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
                            hintText: 'Search tasks...',
                            hintStyle:
                                GoogleFonts.poppins(color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      FontAwesomeIcons.xmark,
                                      color: const Color(0xFFB71A4A),
                                      size: 18,
                                    ),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : Icon(
                                    FontAwesomeIcons.magnifyingGlass,
                                    color: const Color(0xFFB71A4A),
                                    size: 18,
                                  ),
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                          onChanged: (value) {
                            // Trigger rebuild to show/hide clear button
                            (context as Element).markNeedsBuild();
                          },
                        ),
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      isScrollable: false,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      indicatorColor: const Color(0xFFB71A4A),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorWeight: 3.0,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black,
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                      unselectedLabelStyle:
                          TextStyle(fontWeight: FontWeight.normal),
                      onTap: (index) {
                        if (index == 2) {
                          _showFilterModal();
                        } else {
                          setState(() {
                            if (index == 0) {
                              _currentFilter = 'Pending';
                            } else if (index == 1) _currentFilter = "Ongoing";
                            _filterTasks();
                          });
                        }
                      },
                      tabs: _tabStatuses.map((status) {
                        return Tab(
                          child: SizedBox(
                            width: 90,
                            child: Center(
                              child: status == "More"
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          status,
                                          style: TextStyle(fontSize: 12),
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 16,
                                          color: Colors.black,
                                        ),
                                      ],
                                    )
                                  : Text(
                                      status,
                                      style: TextStyle(fontSize: 12),
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // Task Count
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${filteredTasks.length} ${_currentFilter == null ? "" : "$_currentFilter"} tasks',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    // Task List
                    Expanded(
                      child: isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFB71A4A)))
                          : filteredTasks.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.task_alt,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No tasks found',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Create a new task to get started!',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: fetchCreatedTasks,
                                  color: Color(0xFF0272B1),
                                  child: ListView.builder(
                                    padding: EdgeInsets.all(16),
                                    itemCount: filteredTasks.length,
                                    itemBuilder: (context, index) {
                                      final task = filteredTasks[index];
                                      if (task == null) {
                                        return SizedBox.shrink();
                                      }
                                      return _buildTaskCard(task);
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
    );
  }

  void _navigateToTaskStatusPage(TaskFetch task) {
    final statusPages = {
      'Completed': TaskFinished(taskInformation: task),
      'Pending': TaskPending(taskInformation: task),
      'Confirmed': TaskConfirmed(taskInformation: task),
      'Cancelled': TaskCancelled(taskInformation: task),
      'Ongoing': TaskOngoing(taskInformation: task, role: user?.user.role),
      'Review': TaskReview(taskInformation: task),
      'Declined': TaskDeclined(taskInformation: task),
      'Rejected': TaskRejected(taskInformation: task),
    };

    final page = statusPages[task.taskStatus];
    if (page != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      ).then((_) {
        _loadMethod();
      });
    }
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
                      await controller.updateTaskStatus(
                          context, task.id, 'Archived');
                      setState(() {
                        final index = clientTasks.indexOf(task);
                        if (index != -1) {
                          final updatedTask = TaskFetch(
                            id: task.id,
                            taskStatus: 'Archived',
                            taskDetails: task.taskDetails,
                            taskTakenId: task.taskTakenId,
                            createdAt: task.createdAt,
                            updatedAt: DateTime.now(),
                          );
                          clientTasks[index] = updatedTask;
                          _filterTasks();
                        }
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
                      await controller.updateTaskStatus(
                          context, task.id, 'Deleted');
                      setState(() {
                        final index = clientTasks.indexOf(task);
                        if (index != -1) {
                          final updatedTask = TaskFetch(
                            id: task.id,
                            taskStatus: 'Deleted',
                            taskDetails: task.taskDetails,
                            taskTakenId: task.taskTakenId,
                            createdAt: task.createdAt,
                            updatedAt: DateTime.now(),
                          );
                          clientTasks[index] = updatedTask;
                          _filterTasks();
                        }
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

  Widget _buildTaskCard(TaskFetch task) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _navigateToTaskStatusPage(task);
        },
        // onLongPress: () {
        //   _showSelectorModal(context, task);
        // },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTaskRecieved(task),
                  _buildTaskStatusColor(task),
                ],
              ),
              SizedBox(height: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTaskTaskInfo(task),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTaskInfo(TaskFetch task, {double size = 40.0}) {
    final String? imageUrl = task.taskDetails!.client?.user?.image;
    final bool hasValidImage =
        imageUrl != null && imageUrl.isNotEmpty && imageUrl != "Unknown";

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
            ),
            child: hasValidImage
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFB71A4A),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 24,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: Colors.grey,
                    size: 24,
                  ),
          ),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.taskDetails!.title != null
                  ? task.taskDetails!.title.length > 25
                      ? '${task.taskDetails!.title.substring(0, 25)}...'
                      : task.taskDetails!.title
                  : 'Untitled Task',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              "${task.taskDetails!.client?.user?.firstName ?? 'Unknown'} ${task.taskDetails!.client?.user?.lastName ?? 'Unknown'}",
              style:
                  GoogleFonts.poppins(color: Color(0xFFB71A4A), fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskRecieved(TaskFetch task) {
    debugPrint('task.createdAt: ${task.createdAt}');
    debugPrint('task.updatedAt: ${task.updatedAt}');
    DateTime createdDateTime = DateTime.parse(task.createdAt.toString());

    String formattedDate = DateFormat('MMM d, yyyy').format(createdDateTime);

    DateTime now = DateTime.now().toUtc();
    Duration difference = now.difference(createdDateTime);

    String timeAgo;
    if (difference.inMinutes < 60) {
      int minutesAgo = difference.inMinutes;
      timeAgo = '$minutesAgo ${minutesAgo == 1 ? 'min' : 'mins'} ago';
    } else {
      int hoursAgo = difference.inHours;
      timeAgo = '$hoursAgo ${hoursAgo == 1 ? 'hour' : 'hours'} ago';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formattedDate, style: const TextStyle(fontSize: 14)),
        Text(
          timeAgo,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTaskStatusColor(TaskFetch task) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: task.taskStatus == 'Pending'
                ? Colors.grey[500]
                : task.taskStatus == 'Completed'
                    ? Colors.green
                    : task.taskStatus == 'Confirmed'
                        ? Colors.green
                        : task.taskStatus == 'Dispute Settled'
                            ? Colors.green
                            : task.taskStatus == 'Ongoing'
                                ? Colors.blue
                                : task.taskStatus == 'Interested'
                                    ? Colors.blue
                                    : task.taskStatus == 'Review'
                                        ? Colors.yellow
                                        : task.taskStatus == 'Disputed'
                                            ? Colors.orange
                                            : task.taskStatus == 'Rejected'
                                                ? Colors.red
                                                : task.taskStatus == 'Declined'
                                                    ? Colors.red
                                                    : task.taskStatus ==
                                                            'Cancelled'
                                                        ? Colors.red
                                                        : Colors.red,
          ),
          child: Text(
            task.taskStatus,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
