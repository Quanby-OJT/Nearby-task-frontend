import 'package:flutter/material.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/client_request.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

class TaskCancelled extends StatefulWidget {
  final TaskFetch? taskInformation;
  const TaskCancelled({super.key, this.taskInformation});

  @override
  State<TaskCancelled> createState() => _TaskCancelledState();
}

class _TaskCancelledState extends State<TaskCancelled> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController taskController = TaskController();
  final ProfileController _profileController = ProfileController();
  TaskModel? _taskInformation;
  ClientRequestModel? _requestInformation;
  bool _isLoading = true;
  final storage = GetStorage();
  AuthenticatedUser? tasker;
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    Future.wait([
      _fetchRequestDetails(),
      _updateNotif(),
      _fetchUserDetails(),
    ]);
  }

  Future<void> _updateNotif() async {
    try {
      final int userId = storage.read("user_id");
      final response = await taskController.updateNotif(
        widget.taskInformation?.taskTakenId ?? 0,
        userId,
      );
      if (!response) debugPrint("Failed to update notification");
    } catch (e) {
      debugPrint("Error updating notification: $e");
    }
  }

  Future<void> _fetchUserDetails() async {
    try {
      int userId = storage.read("user_id") ?? 0;
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);

      setState(() {
        tasker = user;
        _userRole = user?.user.role ?? 'Unknown';
      });

      debugPrint("Fetched user details: $_userRole");
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    }
  }

  Future<void> _fetchRequestDetails() async {
    try {
      final response = await _jobPostService
          .fetchRequestInformation(widget.taskInformation?.taskTakenId ?? 0);
      setState(() {
        _requestInformation = response;
      });
      await _fetchTaskDetails();
    } catch (e) {
      debugPrint("Error fetching task details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTaskDetails() async {
    try {
      final response = await _jobPostService
          .fetchTaskInformation(_requestInformation!.task_id as int);
      setState(() {
        _taskInformation = response.task;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching task details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Task Information',
          style: GoogleFonts.poppins(
            color: const Color(0xFFB71A4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFB71A4A),
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF03045E)))
          : _taskInformation == null
              ? Center(
                  child: Text(
                    'No task information available',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusSection(),
                            SizedBox(height: 16),
                            _buildTaskCard(constraints),
                            if (_userRole == "Tasker")
                              _buildClientProfileCard(),
                            if (_userRole == "Client")
                              _buildTaskerProfileCard(),
                            SizedBox(height: 16),
                            _buildActionButton(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildClientProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF03045E).withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: Color(0xFF03045E),
                    size: 28,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.taskInformation?.taskDetails?.client?.user?.role ==
                              "Tasker"
                          ? "Tasker Profile"
                          : "Client Profile",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF03045E),
                      ),
                    ),
                    Text(
                      'Details',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildProfileInfoRow(
              'Name',
              (widget.taskInformation?.taskDetails?.client?.user != null)
                  ? '${widget.taskInformation!.taskDetails!.client!.user!.firstName ?? ''} ${widget.taskInformation!.taskDetails!.client!.user!.lastName ?? ''}'
                      .trim()
                  : 'Not available',
            ),
            SizedBox(height: 8),
            _buildProfileInfoRow(
                'Email',
                widget.taskInformation?.taskDetails?.client?.user?.email ??
                    'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow(
                'Phone',
                widget.taskInformation?.taskDetails?.client?.user?.contact ??
                    'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow(
                'Status',
                widget.taskInformation?.taskDetails?.client?.user?.accStatus ??
                    'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow('Account', 'Verified', isVerified: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskerProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF03045E).withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: Color(0xFF03045E),
                    size: 28,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.taskInformation?.taskDetails?.client?.user?.role ==
                              "Client"
                          ? "Client Profile"
                          : "Tasker Profile",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF03045E),
                      ),
                    ),
                    Text(
                      'Details',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildProfileInfoRow(
              'Name',
              (widget.taskInformation?.tasker?.user != null)
                  ? '${widget.taskInformation!.tasker!.user!.firstName ?? ''} ${widget.taskInformation!.tasker!.user!.lastName ?? ''}'
                      .trim()
                  : 'Not available',
            ),
            SizedBox(height: 8),
            _buildProfileInfoRow('Email',
                widget.taskInformation?.tasker?.user?.email ?? 'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow(
                'Phone',
                widget.taskInformation?.tasker?.user?.contact ??
                    'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow(
                'Status',
                widget.taskInformation?.tasker?.user?.accStatus ??
                    'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow('Account', 'Verified', isVerified: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BoxConstraints constraints) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.task,
                      color: Theme.of(context).colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _taskInformation!.title ?? 'Task',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTaskInfoRow(
              icon: FontAwesomeIcons.locationDot,
              label: 'Description',
              value: _taskInformation!.description ?? 'N/A',
            ),
            const SizedBox(height: 16),
            _buildTaskInfoRow(
              icon: FontAwesomeIcons.briefcase,
              label: 'Work Type',
              value: _taskInformation!.workType ?? 'N/A',
            ),
            _buildTaskInfoRow(
              icon: FontAwesomeIcons.star,
              label: 'Specialization',
              value: _taskInformation!.taskerSpecialization?.specialization ??
                  'N/A',
            ),
            _buildTaskInfoRow(
              icon: FontAwesomeIcons.dollarSign,
              label: 'Contract Price',
              value: _taskInformation!.contactPrice.toString() ?? 'N/A',
            ),
            _buildTaskInfoRow(
              icon: FontAwesomeIcons.info,
              label: 'Status',
              value: _requestInformation!.task_status ?? 'Confirmed',
            ),
            _buildTaskInfoRow(
              icon: FontAwesomeIcons.calendar,
              label: 'Start Date',
              value: _requestInformation?.task?.taskBeginDate != null
                  ? DateFormat('MMM dd, yyyy HH:mm a').format(DateTime.parse(
                      _requestInformation?.task?.taskBeginDate ?? ''))
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          FaIcon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cancel,
            color: Colors.red[400],
            size: 40,
          ),
          SizedBox(height: 12),
          Text(
            'Task Cancelled',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This task has been cancelled. Please contact support for more information.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF03045E),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          'Back to Tasks',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value,
      {bool isVerified = false}) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF03045E),
                  ),
                ),
              ),
              if (isVerified)
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.verified,
                    color: Colors.green[400],
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
