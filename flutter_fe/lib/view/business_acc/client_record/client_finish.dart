import 'package:flutter/material.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:get_storage/get_storage.dart';

class FinishTask extends StatefulWidget {
  final int? finishID;
  final String? role;
  const FinishTask({super.key, this.finishID, this.role});

  @override
  State<FinishTask> createState() => _FinishTaskState();
}

class _FinishTaskState extends State<FinishTask> {
  final JobPostService _jobPostService = JobPostService();
  final ProfileController _profileController = ProfileController();
  TaskFetch? _requestInformation;
  bool _isLoading = true;
  final storage = GetStorage();
  String? _role;
  AuthenticatedUser? tasker;
  String? _errorMessage;

  // Status color mapping from previous questions
  final Map<String, Color> statusColors = {
    'Pending': Colors.grey[500]!,
    'Completed': Colors.green,
    'Ongoing': Colors.blue,
    'Disputed': Colors.orange,
    'Interested': Colors.blue,
    'Confirmed': Colors.green,
    'Rejected': Colors.red,
    'Declined': Colors.red,
    'Dispute Settled': Colors.green,
    'Cancelled': Colors.red,
    'Review': Colors.yellow,
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
    debugPrint("Task ID from the widget: ${widget.finishID}");
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch user data and request details concurrently
      await Future.wait([
        _fetchUserData(),
        _fetchRequestDetails(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load task details. Please try again.';
      });
    }
  }

  Future<void> _fetchUserData() async {
    try {
      int userId = storage.read("user_id") ?? 0;
      if (userId == 0) {
        debugPrint("No user_id found in storage");
        return;
      }
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      debugPrint("User data: $user");
      setState(() {
        _role = user?.user.role;
      });
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<void> _fetchRequestDetails() async {
    try {
      if (widget.finishID == null || widget.finishID == 0) {
        debugPrint("Invalid finishID: ${widget.finishID}");
        setState(() {
          _errorMessage = 'Invalid task ID provided.';
        });
        return;
      }

      final response =
          await _jobPostService.taskerTaskInformation(widget.finishID!);
      debugPrint("Fetched request details: $response");

      if (response.isNotEmpty) {
        setState(() {
          _requestInformation = response.first;
        });

        // Fetch task and tasker/client details
        await Future.wait([
          _fetchTaskDetails(),
          if (_requestInformation != null)
            _fetchTaskerDetails(
              widget.role == "Client"
                  ? _requestInformation!.taskerId ?? 0
                  : _requestInformation!.clientId ?? 0,
            ),
        ]);
      } else {
        debugPrint("No task data returned");
        setState(() {
          _errorMessage = 'No task information available.';
        });
      }
    } catch (e) {
      debugPrint("Error fetching request details: $e");
      setState(() {
        _errorMessage = 'Error fetching task details: $e';
      });
    }
  }

  Future<void> _fetchTaskDetails() async {
    try {
      if (_requestInformation == null || _requestInformation!.id == null) {
        debugPrint("No request information or task ID available");
        return;
      }
      final response =
          await _jobPostService.fetchTaskInformation(_requestInformation!.id!);
      debugPrint("Fetched task details: $response");
      setState(() {
        // Assuming fetchTaskInformation returns a TaskResponse with a TaskModel
        _requestInformation = _requestInformation;
      });
    } catch (e) {
      debugPrint("Error fetching task details: $e");
    }
  }

  Future<void> _fetchTaskerDetails(int userId) async {
    try {
      if (userId == 0) {
        debugPrint("Invalid userId for tasker/client: $userId");
        return;
      }
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      debugPrint("Tasker/Client data: $user");
      setState(() {
        tasker = user;
      });
    } catch (e) {
      debugPrint("Error fetching tasker details: $e");
    }
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
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFB71A4A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF03045E)))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.red[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF03045E),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _requestInformation == null
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
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCompletionSection(),
                            const SizedBox(height: 16),
                            _buildTaskCard(),
                            const SizedBox(height: 16),
                            _buildProfileCard(),
                            const SizedBox(height: 16),
                            _buildActionButton(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildCompletionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[600],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Task Completed!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Congratulations on successfully completing this task!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard() {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: const Color(0xFF03045E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.task,
                      color: Color(0xFF03045E), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _requestInformation!.taskDetails.title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF03045E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTaskInfoRow(
              icon: Icons.location_pin,
              label: 'Location',
              value: _requestInformation!.taskDetails.location,
            ),
            const SizedBox(height: 12),
            _buildTaskInfoRow(
              icon: Icons.calendar_today,
              label: 'Duration',
              value: _requestInformation!.taskDetails.duration,
            ),
            const SizedBox(height: 12),
            _buildTaskInfoRow(
              icon: Icons.info,
              label: 'Status',
              value: _requestInformation!.taskStatus,
              color:
                  statusColors[_requestInformation!.taskStatus] ?? Colors.red,
            ),
            const SizedBox(height: 12),
            _buildTaskInfoRow(
              icon: Icons.description,
              label: 'Description',
              value: _requestInformation!.taskDetails.description,
            ),
            const SizedBox(height: 12),
            _buildTaskInfoRow(
              icon: Icons.monetization_on,
              label: 'Price',
              value: '₱${_requestInformation!.taskDetails.proposedPrice}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF03045E).withOpacity(0.1),
                  backgroundImage: tasker?.user.image != null
                      ? NetworkImage(tasker!.user.image!)
                      : null,
                  child: tasker?.user.image == null
                      ? const Icon(
                          Icons.person,
                          color: Color(0xFF03045E),
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tasker!.user.firstName} ${tasker!.user.lastName}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF03045E),
                      ),
                    ),
                    Text(
                      tasker?.user.accStatus ?? 'Inactive',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // const SizedBox(height: 16),
            // _buildProfileInfoRow(
            //   'Name',
            //   tasker != null ? '' : 'Not available',
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB71A4A),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          'Back to Tasks',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? const Color(0xFF03045E),
            ),
          ),
        ),
      ],
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
                    color: const Color(0xFF03045E),
                  ),
                ),
              ),
              if (isVerified)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
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
