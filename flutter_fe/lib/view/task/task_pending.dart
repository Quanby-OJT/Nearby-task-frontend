import 'package:flutter/material.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:flutter_fe/view/chat/ind_chat_screen.dart';
import 'package:flutter_fe/view/custom_loading/custom_scaffold.dart';
import 'package:flutter_fe/view/task/task_cancelled.dart';
import 'package:flutter_fe/view/task/task_confirmed.dart';
import 'package:flutter_fe/view/task/task_expired.dart';
import 'package:flutter_fe/view/task/task_rejected.dart';
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

class TaskPending extends StatefulWidget {
  final TaskFetch? taskInformation;
  const TaskPending({super.key, this.taskInformation});

  @override
  State<TaskPending> createState() => _TaskPendingState();
}

class _TaskPendingState extends State<TaskPending> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController taskController = TaskController();
  final ProfileController _profileController = ProfileController();
  TaskModel? _taskInformation;
  ClientRequestModel? _requestInformation;
  bool _isLoading = true;
  final storage = GetStorage();
  AuthenticatedUser? tasker;
  String? _role;
  String? _userRole;
  String? selectedReason = 'Incomplete task details';
  final List<String> rejectionReasons = [
    'Incomplete task details',
    'Insufficient time',
    'Lack of resources',
    'Task not relevant',
    'Other'
  ];

  final String _needToConfirm =
      'The task is pending confirmation. Waiting for your confirmation.';
  final String _needToBeConfirmed = 'Awaiting confirmation.';

  @override
  void initState() {
    super.initState();
    _loadMethod();
  }

  void _loadMethod() async {
    setState(() {
      _isLoading = true;
    });
    await Future(() async {
      await _fetchRequestDetails();
      await _updateNotif();
      await _fetchUserDetails();
    });
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateNotif() async {
    try {
      final int userId = storage.read("user_id") ?? 0;
      final response = await taskController.updateNotif(
        widget.taskInformation?.taskTakenId ?? 0,
        userId,
      );
      debugPrint("Update notification response: ${response.toString()}");
      if (!response) {
        debugPrint("Failed to update notification");
      }
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

  Future<void> _fetchTaskerDetails() async {
    try {
      final int userId = storage.read("user_id") ?? 0;
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);

      setState(() {
        tasker = user;
        _role = user?.user.role ?? 'Unknown';
      });
    } catch (e) {
      debugPrint("Error fetching tasker details: $e");
    }
  }

  Future<void> _fetchRequestDetails() async {
    try {
      debugPrint(
          "Fetching request details for task ID: ${widget.taskInformation?.taskTakenId}");
      final response = await _jobPostService
          .fetchRequestInformation(widget.taskInformation?.taskTakenId ?? 0);
      setState(() {
        _requestInformation = response;
      });

      debugPrint("Fetched request details: $_requestInformation");

      await _fetchTaskDetails();
      if (widget.taskInformation?.taskDetails?.client?.user?.role == "Tasker") {
        await _fetchTaskerDetails();
      } else {
        await _fetchTaskerDetails();
      }
    } catch (e) {
      debugPrint("Error fetching request details: $e");
    }
  }

  Future<void> _fetchTaskDetails() async {
    try {
      final response = await _jobPostService
          .fetchTaskInformation(_requestInformation?.task_id ?? 0);
      setState(() {
        _taskInformation = response.task;
      });
    } catch (e) {
      debugPrint("Error fetching task details: $e");
    }
  }

  Future<void> _handleRejectTask(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: Center(
          child: Text(
            'Reject Task',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to reject this task? This action cannot be undone.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reason for rejection:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: DropdownButton<String>(
                    value: selectedReason,
                    isExpanded: true,
                    underline: SizedBox(),
                    items: rejectionReasons.map((String reason) {
                      return DropdownMenuItem<String>(
                        value: reason,
                        child: Text(
                          reason,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setDialogState(() {
                          selectedReason = newValue;
                        });
                        setState(() {
                          selectedReason = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB71A4A),
                  ),
                ),
                onPressed: () => Navigator.pop(context, false),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Color(0xFFB71A4A),
                ),
                child: TextButton(
                  child: Text(
                    'Confirm',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    final String value = 'Reject';
                    final result = await taskController.updateRequest(
                      _requestInformation?.task_taken_id ?? 0,
                      value,
                      _role ?? 'Unknown',
                      rejectionReason: selectedReason,
                    );
                    if (result.containsKey('success') && result['success']) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskRejected(
                            taskInformation: widget.taskInformation,
                          ),
                        ),
                      );
                    } else {
                      Navigator.pop(context, false);
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      CustomScaffold(
          message: 'Task rejection requested', color: Color(0xFFB71A4A));
    }
  }

  Future<void> _handleCancelTask(BuildContext context) async {
    setState(() {
      selectedReason = rejectionReasons[0];
    });

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          title: Center(
            child: Text(
              'Cancel Task',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to cancel this task? This action cannot be undone.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reason for cancellation:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: DropdownButton<String>(
                  value: selectedReason,
                  isExpanded: true,
                  underline: SizedBox(),
                  items: rejectionReasons.map((String reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(
                        reason,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setDialogState(() {
                        selectedReason = newValue;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFB71A4A),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Color(0xFFB71A4A),
                  ),
                  child: TextButton(
                    child: Text(
                      'Confirm',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });

                      final String value = 'Cancel';
                      final result = await taskController.updateRequest(
                        _requestInformation?.task_taken_id ?? 0,
                        value,
                        _role ?? 'Unknown',
                        rejectionReason: selectedReason,
                      );
                      if (result.containsKey('success') && result['success']) {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskCancelled(
                              taskInformation: widget.taskInformation,
                            ),
                          ),
                        );
                      } else {
                        Navigator.pop(context);
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      CustomScaffold(
          message: 'Task cancel requested', color: Color(0xFFB71A4A));
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
          : _taskInformation == null || _requestInformation == null
              ? Center(
                  child: Text(
                    'No task information available',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusSection(),
                        SizedBox(height: 16),
                        _buildTaskCard(),
                        SizedBox(height: 16),
                        if (_userRole == "Tasker") _buildClientProfileCard(),
                        if (_userRole == "Client") _buildTaskerProfileCard(),
                        if (_requestInformation?.task_status == "Pending") ...[
                          SizedBox(height: 24),
                          _buildActionButtons(
                              _requestInformation?.requested_from ?? 'Unknown'),
                        ],
                        if (_requestInformation?.task_status != "Pending") ...[
                          SizedBox(height: 16),
                          _buildActionButton(),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  _setExpire() async {
    setState(() {
      _isLoading = true;
    });

    final String value = 'Expired';
    final result = await taskController.updateRequest(
        _requestInformation?.task_taken_id ?? 0, value, _role ?? 'Unknown');
    if (result.containsKey('success') && result['success']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TaskExpired(
            taskInformation: widget.taskInformation,
          ),
        ),
      );
    } else {
      CustomScaffold(message: 'Failed to accept task', color: Colors.red);
    }
  }

  Widget _buildStatusSection() {
    // Handle null cases
    if (_requestInformation?.created_at == null ||
        _requestInformation?.time_request == null) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Icon(
              Icons.hourglass_empty,
              color: Colors.blue[600],
              size: 36,
            ),
            SizedBox(height: 12),
            Text(
              'Pending to Confirm',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _requestInformation?.requested_from != _userRole
                  ? _needToConfirm
                  : _needToBeConfirmed,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Deadline information unavailable',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red[600],
              ),
            ),
          ],
        ),
      );
    }

    final createdAt = _requestInformation!.created_at!;
    final daysToConfirm = _requestInformation!.time_request ?? 1;
    final deadline = createdAt.add(Duration(days: daysToConfirm));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[100]!.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[100]!.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_empty,
              color: Colors.blue[600],
              size: 36,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Pending to Confirm',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[900],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _requestInformation?.requested_from != _userRole
                ? _needToConfirm
                : _needToBeConfirmed,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          StreamBuilder(
            stream: Stream.periodic(Duration(seconds: 1)),
            builder: (context, snapshot) {
              final now = DateTime.now();
              final difference = deadline.difference(now);

              // Animation for timer text
              return AnimatedOpacity(
                opacity: difference.isNegative ? 1.0 : 0.9,
                duration: Duration(milliseconds: 500),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        'Time Remaining',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        difference.isNegative
                            ? 'Deadline Expired'
                            : _formatDuration(difference),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: difference.isNegative
                              ? Colors.red[700]
                              : Colors.blue[900],
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (difference.isNegative) _setExpire(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration difference) {
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    if (days > 0) {
      return '$days${days == 1 ? ' day' : ' days'} ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildTaskCard() {
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
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF03045E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.task, color: Color(0xFF03045E), size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _taskInformation?.title ?? 'Task',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF03045E),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildTaskInfoRow(
              icon: Icons.info,
              label: 'Status',
              value: _requestInformation?.task_status ?? 'Pending',
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
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(String requestedFrom) {
    return Column(
      children: [
        if (requestedFrom != _userRole)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                });
                debugPrint("Accept request role: $_role");
                final String value = 'Accept';
                final result = await taskController.updateRequest(
                    _requestInformation?.task_taken_id ?? 0,
                    value,
                    _role ?? 'Unknown');
                if (result.containsKey('success') && result['success']) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskConfirmed(
                        taskInformation: widget.taskInformation,
                      ),
                    ),
                  );
                } else {
                  CustomScaffold(
                      message: 'Failed to accept task', color: Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFB71A4A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                'Accept',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        Row(
          children: [
            if (requestedFrom != _userRole) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleRejectTask(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red[400]!),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Reject',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[400],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleMessage(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue[600]!),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Message',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[600],
                    ),
                  ),
                ),
              ),
            ],
            if (requestedFrom == _userRole)
              // Cancel button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleCancelTask(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red[400]!),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[400],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _handleMessage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IndividualChatScreen(
          taskTitle: _taskInformation?.title,
          taskTakenId: _requestInformation?.task_taken_id,
          taskId: _requestInformation?.task_id,
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

  Widget _buildProfileInfoRow(String label, String value,
      {bool isVerified = false}) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
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
