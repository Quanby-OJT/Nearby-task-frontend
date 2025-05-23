import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class JobPostPage extends StatefulWidget {
  const JobPostPage({super.key});

  @override
  State<JobPostPage> createState() => _JobPostPageState();
}

class _JobPostPageState extends State<JobPostPage>
    with SingleTickerProviderStateMixin {
  final TaskController controller = TaskController();
  final JobPostService jobPostService = JobPostService();
  final ClientServices _clientServices = ClientServices();
  final ProfileController _profileController = ProfileController();
  final EscrowManagementController _escrowManagementController =
      EscrowManagementController();
  final GetStorage storage = GetStorage();
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  TabController?
      _tabController; // Changed to nullable to avoid late initialization issues

  List<TaskModel?> clientTasks = [];
  List<TaskModel?> _filteredTasks = [];
  String? _currentFilter = 'Pending';
  bool _isLoading = true;
  bool _showButton = false;
  bool _isUploadDialogShown = false;
  bool _documentValid = false;
  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;
  AuthenticatedUser? _user;
  List<String> specialization = [];

  @override
  void initState() {
    super.initState();
    // Initialize TabController safely
    _tabController = TabController(length: 2, vsync: this);
    _tabController?.addListener(() {
      if (_tabController != null && !_tabController!.indexIsChanging) {
        _pageController.animateToPage(
          _tabController!.index,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
    fetchSpecialization();
    _fetchUserIDImage();
    fetchCreatedTasks();
    _searchController.addListener(_filterTasks);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchSpecialization() async {
    try {
      List<SpecializationModel> fetchedSpecializations =
          await jobPostService.getSpecializations();
      setState(() {
        specialization =
            fetchedSpecializations.map((spec) => spec.specialization).toList();
      });
    } catch (error) {
      debugPrint('Error fetching specializations: $error');
    }
  }

  Future<void> fetchCreatedTasks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userId = storage.read('user_id');
      if (userId != null) {
        final tasks = await controller.getJobsforClient(context, userId);
        setState(() {
          clientTasks = tasks ?? [];
          _filteredTasks = List.from(clientTasks);
          _filterTasks();
        });
      } else {
        setState(() {
          clientTasks = [];
          _filteredTasks = [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching tasks: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load tasks. Please try again."),
          backgroundColor: Color(0xFFB71A4A),
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: fetchCreatedTasks,
            textColor: Colors.white,
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserIDImage() async {
    try {
      final userId = storage.read('user_id');
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      int parsedUserId = int.parse(userId.toString());
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, parsedUserId);
      final response = await _clientServices.fetchUserIDImage(parsedUserId);
      if (response['success'] == true) {
        setState(() {
          _user = user;
          _existingProfileImageUrl = user?.user.image;
          _existingIDImageUrl = response['url'];
          _documentValid = response['status'] ?? false;
          _showButton = _existingProfileImageUrl != null &&
              _existingIDImageUrl != null &&
              _documentValid;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching ID image: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterTasks() {
    String query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredTasks = clientTasks.where((task) {
        if (task == null) return false;
        bool matchesSearch =
            (task.title?.toLowerCase().contains(query) ?? false) ||
                (task.description?.toLowerCase().contains(query) ?? false);
        bool matchesStatus = _currentFilter == null ||
            task.getEffectiveStatus() == _currentFilter;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _navigateToTaskDetail(TaskModel task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BusinessTaskDetail(task: task)),
    );
    if (result == true) {
      await fetchCreatedTasks();
    }
  }

  void _showWarningDialog() {
    if (_isUploadDialogShown) return;
    setState(() {
      _isUploadDialogShown = true;
    });
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
            color: Color(0xFFB71A4A),
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
              setState(() {
                _isUploadDialogShown = false;
              });
            },
            child: Text(
              'Cancel',
              style:
                  GoogleFonts.poppins(fontSize: 14, color: Color(0xFFB71A4A)),
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
                setState(() {
                  _isLoading = true;
                });
                await _fetchUserIDImage();
              }
              setState(() {
                _isUploadDialogShown = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE23670),
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

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
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
              Text(
                'Filter Tasks',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB71A4A),
                ),
              ),
              SizedBox(height: 16),
              ...[
                'Pending',
                'Available',
                'Confirmed',
                'Ongoing',
                'Review',
                'Completed',
                'Cancelled',
                'Disputed',
                'Rejected',
                'Closed'
              ]
                  .map((status) => RadioListTile<String>(
                        title: Text(status,
                            style: GoogleFonts.poppins(fontSize: 14)),
                        value: status,
                        groupValue: _currentFilter,
                        activeColor: Color(0xFFE23670),
                        onChanged: (value) {
                          setState(() {
                            _currentFilter = value;
                            _filterTasks();
                          });
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskManagementView() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            controller: _searchController,
            cursorColor: Color(0xFFB71A4A),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search tasks...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Color(0xFFB71A4A)),
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
                borderSide: BorderSide(color: Color(0xFFE23670), width: 2),
              ),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredTasks.length} tasks',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              TextButton.icon(
                onPressed: _showFilterModal,
                icon: Icon(Icons.filter_list, color: Color(0xFFB71A4A)),
                label: Text('Filter',
                    style: GoogleFonts.poppins(color: Color(0xFFB71A4A))),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: Color(0xFFE23670)))
              : _filteredTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.task_alt,
                              size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No tasks found',
                            style: GoogleFonts.poppins(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                          Text(
                            'Create a new task to get started!',
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchCreatedTasks,
                      color: Color(0xFFE23670),
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = _filteredTasks[index];
                          if (task == null) return SizedBox.shrink();
                          return _buildTaskCard(task);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildTaskStatusView() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            controller: _searchController,
            cursorColor: Color(0xFFB71A4A),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search tasks by status...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Color(0xFFB71A4A)),
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
                borderSide: BorderSide(color: Color(0xFFE23670), width: 2),
              ),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredTasks.length} ${_currentFilter ?? "All"} tasks',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              TextButton.icon(
                onPressed: _showFilterModal,
                icon: Icon(Icons.filter_list, color: Color(0xFFB71A4A)),
                label: Text('Filter',
                    style: GoogleFonts.poppins(color: Color(0xFFB71A4A))),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: Color(0xFFE23670)))
              : _filteredTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.task_alt,
                              size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No tasks found',
                            style: GoogleFonts.poppins(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                          Text(
                            'Check task status here',
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchCreatedTasks,
                      color: Color(0xFFE23670),
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = _filteredTasks[index];
                          if (task == null) return SizedBox.shrink();
                          return _buildTaskCard(task);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    String priceDisplay = "${task.contactPrice ?? 0} Credits";
    final status = task.getEffectiveStatus() ?? 'Unknown';
    final statusColor = status == 'Pending'
        ? Colors.grey[500]
        : status == 'Completed' ||
                status == 'Confirmed' ||
                status == 'Dispute Settled'
            ? Colors.green
            : status == 'Ongoing' ||
                    status == 'Interested' ||
                    status == 'Already Taken'
                ? Colors.blue
                : status == 'Review'
                    ? Colors.yellow
                    : status == 'Disputed'
                        ? Colors.orange
                        : Colors.red;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToTaskDetail(task),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              SizedBox(height: 8),
              Text(
                task.title ?? 'Untitled Task',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE23670),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.locationPin,
                      size: 16, color: Colors.red[400]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${task.address?.city ?? 'N/A'}, ${task.address?.province ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey[800]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.coins,
                      size: 16, color: Colors.green[400]),
                  SizedBox(width: 8),
                  Text(
                    priceDisplay,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey[800]),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.screwdriverWrench,
                      size: 16, color: Color(0xFFE23670)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.specialization ?? 'N/A',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey[800]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (_tabController != null && _tabController!.index == 0) ...[
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Color(0xFFE23670)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddTask()),
                        ).then((value) => fetchCreatedTasks());
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Color(0xFFB71A4A)),
                      onPressed: () async {
                        final confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: Text(
                              'Delete Task',
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB71A4A)),
                            ),
                            content: Text(
                              'Are you sure you want to delete this task?',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.grey[600]),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14, color: Color(0xFFB71A4A)),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFE23670),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  'Delete',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          // Implement task deletion logic here
                          await controller.deleteTask(task.id);
                          fetchCreatedTasks();
                        }
                      },
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
            color: Color(0xFFB71A4A),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[100],
        elevation: 0,
        bottom: _tabController == null
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Color(0xFFE23670),
                indicatorWeight: 3,
                labelColor: Color(0xFFB71A4A),
                unselectedLabelColor: Colors.grey[600],
                labelStyle: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
                tabs: [
                  Tab(text: 'Manage Tasks'),
                  Tab(text: 'Task Status'),
                ],
              ),
      ),
      body: _tabController == null
          ? Center(child: CircularProgressIndicator(color: Color(0xFFE23670)))
          : PageView(
              controller: _pageController,
              onPageChanged: (index) {
                _tabController?.animateTo(index);
              },
              children: [
                _buildTaskManagementView(),
                _buildTaskStatusView(),
              ],
            ),
      floatingActionButton: _tabController != null && _tabController!.index == 0
          ? FloatingActionButton(
              onPressed: _showButton
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddTask()),
                      ).then((value) => fetchCreatedTasks())
                  : _showWarningDialog,
              backgroundColor: Color(0xFFE23670),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
