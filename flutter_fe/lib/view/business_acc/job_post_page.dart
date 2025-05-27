import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fe/model/client_task_model.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:flutter_fe/view/service_acc/tasker_record/tasker_pending.dart';
import 'package:flutter_fe/view/task/task_cancelled.dart';
import 'package:flutter_fe/view/task/task_confirmed.dart';
import 'package:flutter_fe/view/task/task_finished.dart';
import 'package:flutter_fe/view/task/task_ongoing.dart';
import 'package:flutter_fe/view/task/task_pending.dart';
import 'package:flutter_fe/view/task/task_review.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/view/business_acc/business_task_detail.dart';
import 'package:flutter_fe/view/business_acc/task_creation/add_task.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:intl/intl.dart';

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
  final EscrowManagementController _escrowController =
      EscrowManagementController();
  final GetStorage _storage = GetStorage();
  final TextEditingController _searchController = TextEditingController();
  late final PageController _pageController;
  late final TabController _tabController;

  // Data
  List<TaskModel> _clientTasks = [];
  List<TaskModel> _filteredTasksManagement = [];
  List<TaskFetch> _clientTasksTasker = [];
  List<TaskFetch> _filteredTasksStatus = [];
  List<String> _specializations = [];
  String? _currentFilterManagement = 'Available';
  String? _currentFilterStatus = 'Pending';
  AuthenticatedUser? _user;
  String? _profileImageUrl;
  String? _idImageUrl;
  bool _isDocumentValid = false;
  bool _isLoading = true;
  bool _showButton = false;
  bool _isUploadDialogShown = false;

  // Task management and status filters
  static const List<String> _taskManagementFilters = [
    'Available',
    'Already Taken',
    'On Hold',
    'Closed',
  ];

  static const List<String> _taskStatusFilters = [
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
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(_filterTasks);
    _initializeData();
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
      await Future.wait([
        _fetchUserIDImage(),
        _fetchSpecializations(),
        _fetchTasksManagement(),
        _fetchTasksStatus(),
      ]);
    } catch (e) {
      _showErrorSnackBar('Failed to initialize data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Fetch user ID image and profile data
  Future<void> _fetchUserIDImage() async {
    final userId = _storage.read('user_id');
    if (userId == null) return;

    try {
      final parsedUserId = int.parse(userId.toString());
      final user =
          await _profileController.getAuthenticatedUser(context, parsedUserId);
      final response = await _clientServices.fetchUserIDImage(parsedUserId);
      if (response['success'] == true) {
        setState(() {
          _user = user;
          _profileImageUrl = user?.user.image;
          _idImageUrl = response['url'];
          _isDocumentValid = response['status'] ?? false;
          // Allow task posting if documents exist and are either approved or under review
          _showButton = _profileImageUrl != null &&
              _idImageUrl != null &&
              (_isDocumentValid || user?.user.accStatus == 'Review');
        });
      } else {
        // Handle API error gracefully
        debugPrint('Failed to fetch user ID image: ${response['message']}');
        setState(() {
          _user = user;
          _profileImageUrl = user?.user.image;
          _idImageUrl = null;
          _isDocumentValid = false;
          // Still allow task posting if user has profile image and status is Review
          _showButton =
              _profileImageUrl != null && user?.user.accStatus == 'Review';
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error fetching user data: $e');
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

      debugPrint('Fetched ${tasks.length} tasks for status view ito');
      setState(() {
        _clientTasksTasker = tasks as List<TaskFetch>;
        _filteredTasksStatus = List.from(_clientTasksTasker);
        _filterTasks();
      });

      debugPrint(
          'Fetched ${_clientTasksTasker.length} tasks for status view po');
    } catch (e, stackTrace) {
      debugPrint('Error while rendering tasks for status view: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showErrorSnackBar(
          'An error occurred while displaying your tasks. Please Try Again.');
    }
  }

  // Filter tasks based on search query and selected filters
  void _filterTasks() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      // Filter management tasks
      _filteredTasksManagement = _clientTasks.where((task) {
        if (task == null) return false;
        final matchesSearch = task.title?.toLowerCase().contains(query) ??
            false || task.description!.toLowerCase().contains(query) ??
            false;
        final matchesStatus = _currentFilterManagement == null ||
            task.status == _currentFilterManagement;
        return matchesSearch && matchesStatus;
      }).toList();

      // Filter status tasks
      _filteredTasksStatus = _clientTasksTasker.where((task) {
        if (task == null) return false;
        final matchesSearch =
            task.post_task!.title?.toLowerCase().contains(query) ??
                false ||
                    task.post_task!.description.toLowerCase().contains(query) ??
                false;
        final matchesStatus = _currentFilterStatus == null ||
            task.taskStatus == _currentFilterStatus;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  // Show error snackbar with retry option
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB71A4A),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _initializeData,
          textColor: Colors.white,
        ),
      ),
    );
  }

  // Navigate to task detail and refresh tasks if needed
  Future<void> _navigateToTaskDetail(TaskModel task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BusinessTaskDetail(task: task)),
    );
    if (result == true) {
      await _fetchTasksManagement();
    }
  }

  // Show warning dialog for incomplete profile
  void _showWarningDialog() {
    if (_isUploadDialogShown) return;
    setState(() => _isUploadDialogShown = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Complete Your Profile',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB71A4A),
          ),
        ),
        content: Text(
          'Please upload your profile and ID images to post tasks.',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
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
                  fontSize: 14, color: const Color(0xFFB71A4A)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FillUpClient()),
              );
              if (result == true) {
                await _fetchUserIDImage();
              }
              setState(() => _isUploadDialogShown = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE23670),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Verify Now',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Show filter modal for task management
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

  // Show filter modal for task status
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

  // Generic filter modal for reusability
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

  // Build task management view
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
            onRefresh: _fetchTasksManagement,
            buildTaskCard: _buildTaskManagementViewCard,
          ),
        ),
      ],
    );
  }

  // Build task status view
  Widget _buildTaskStatusView() {
    return Column(
      children: [
        _buildSearchBar(hint: 'Search tasks by status...'),
        _buildFilterBar(
          count: _filteredTasksStatus.length,
          filterLabel: _currentFilterStatus ?? 'Pending',
          onFilterPressed: _showFilterModalStatus,
        ),
        Expanded(
          child: _buildTaskList(
            isLoading: _isLoading,
            tasks: _filteredTasksStatus,
            onRefresh: _fetchTasksStatus,
            buildTaskCard: (task) => _buildTaskStatusViewCard(task),
          ),
        ),
      ],
    );
  }

  // Reusable search bar widget
  Widget _buildSearchBar({String hint = 'Search tasks...'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: _searchController,
        cursorColor: const Color(0xFFB71A4A),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFB71A4A)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE23670), width: 2),
          ),
        ),
        style: GoogleFonts.poppins(fontSize: 14),
      ),
    );
  }

  // Reusable filter bar widget
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
            Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              const SizedBox(height: 8),
              Text(
                task.title ?? 'Untitled Task',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE23670),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _buildTaskInfoRow(
                icon: FontAwesomeIcons.locationPin,
                iconColor: Colors.red[400],
                text:
                    '${task.address?.city ?? 'N/A'}, ${task.address?.province ?? 'N/A'}',
              ),
              const SizedBox(height: 8),
              _buildTaskInfoRow(
                icon: FontAwesomeIcons.coins,
                iconColor: Colors.green[400],
                text: '${task.contactPrice ?? 0} Credits',
              ),
              const SizedBox(height: 8),
              _buildTaskInfoRow(
                icon: FontAwesomeIcons.screwdriverWrench,
                iconColor: const Color(0xFFE23670),
                text: task.specialization ?? 'N/A',
              ),
              if (_tabController.index == 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFFE23670)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddTask()),
                        ).then((value) => _fetchTasksManagement());
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFFB71A4A)),
                      onPressed: () => _confirmDeleteTask(task.id),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Build task card for status view
  Widget _buildTaskStatusViewCard(TaskFetch task) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToTaskStatusPage(task),
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

  // Navigate to appropriate task status page
  void _navigateToTaskStatusPage(TaskFetch task) {
    final statusPages = {
      'Completed': TaskFinished(taskInformation: task),
      'Pending': TaskPending(taskInformation: task),
      'Confirmed': TaskConfirmed(taskInformation: task),
      'Cancelled': TaskCancelled(taskInformation: task),
      'Ongoing': TaskOngoing(taskInformation: task, role: _user?.user.role),
      'Review': TaskReview(taskInformation: task),
    };

    final page = statusPages[task.taskStatus];
    if (page != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      ).then((value) {
        if (value != null) {
          _initializeData();
        }
      });
    }
  }

  // Build task status color indicator
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
    final createdDateTime = DateTime.parse(task.createdAt.toString());
    final formattedDate = DateFormat('MMM d, yyyy').format(createdDateTime);
    final difference = DateTime.now().toUtc().difference(createdDateTime);
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

  // Build task info with user avatar
  Widget _buildTaskInfo(TaskFetch task, {double size = 40.0}) {
    final imageUrl = task.tasker?.user?.image ?? 'Unknown';
    final hasValidImage =
        imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'Unknown';

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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 24,
                    ),
                  )
                : const Icon(Icons.person, color: Colors.grey, size: 24),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.post_task?.title ?? 'Untitled Task',
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

  // Reusable task info row
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

  // Confirm and delete task
  Future<void> _confirmDeleteTask(int taskId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Task',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB71A4A),
          ),
        ),
        content: Text(
          'Are you sure you want to delete this task?',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE23670),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
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
        centerTitle: true,
        backgroundColor: Colors.grey[100],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE23670),
          indicatorWeight: 3,
          labelColor: const Color(0xFFB71A4A),
          unselectedLabelColor: Colors.grey[600],
          labelStyle:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
          tabs: const [
            Tab(text: 'Manage Tasks'),
            Tab(text: 'Task Status'),
          ],
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
              onPressed: _showButton
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddTask()),
                      ).then((value) => _fetchTasksManagement())
                  : _showWarningDialog,
              backgroundColor: const Color(0xFFE23670),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
