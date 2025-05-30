import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/client_request.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

class TaskerStart extends StatefulWidget {
  final int? requestID;
  const TaskerStart({super.key, this.requestID});

  @override
  State<TaskerStart> createState() => _TaskerStartState();
}

class _TaskerStartState extends State<TaskerStart> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController taskController = TaskController();
  final ProfileController _profileController = ProfileController();
  TaskModel? _taskInformation;
  ClientRequestModel? _requestInformation;
  bool _isLoading = true;
  final storage = GetStorage();
  AuthenticatedUser? tasker;

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
    _updateNotif();
  }

  Future<void> _updateNotif() async {
    try {
      final int userId = storage.read("user_id");
      final response = await taskController.updateNotif(
        widget.requestID ?? 0,
        userId,
      );
      if (!response) debugPrint("Failed to update notification");
    } catch (e) {
      debugPrint("Error updating notification: $e");
    }
  }

  Future<void> _fetchTaskerDetails(int userId) async {
    try {
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      setState(() {
        tasker = user;
      });
    } catch (e) {
      debugPrint("Error fetching tasker details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRequestDetails() async {
    try {
      final response =
          await _jobPostService.fetchRequestInformation(widget.requestID ?? 0);
      setState(() {
        _requestInformation = response;
      });
      await _fetchTaskDetails();
      await _fetchTaskerDetails(_requestInformation!.client_id as int);
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

  Future<void> _handleCancelTask(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Task',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to cancel this task? This action cannot be undone.',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('No', style: GoogleFonts.montserrat(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });

              final String value = 'Cancel';
              bool result = await taskController.acceptRequest(
                  _requestInformation?.task_taken_id ?? 0, value, 'Tasker');
              if (result) {
                Navigator.pop(context);
                setState(() {
                  _isLoading = true;
                });
                await _fetchRequestDetails();
                setState(() {
                  _isLoading = false;
                });
              } else {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child:
                Text('Yes', style: GoogleFonts.montserrat(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task cancellation requested')),
      );
    }
  }

  Future<void> _handleRescheduleTask() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF03045E),
              onPrimary: Colors.white,
              surface: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      // TODO: Implement actual reschedule API call
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reschedule requested for $formattedDate')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF03045E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Confirmed Task',
          style: GoogleFonts.montserrat(
            color: Color(0xFF03045E),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
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
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Section
                        _buildStatusSection(),
                        SizedBox(height: 16),
                        // Task Card
                        _buildTaskCard(),
                        SizedBox(height: 16),
                        // Client Profile Card
                        _buildProfileCard(),
                        if (_requestInformation!.task_status ==
                            "Confirmed") ...[
                          SizedBox(height: 24),
                          // Action Buttons
                          _buildActionButtons(),
                        ],
                        if (_requestInformation!.task_status !=
                            "Confirmed") ...[
                          SizedBox(height: 24),
                          // Action Buttons
                          _buildBackButtons(),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBackButtons() {
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

  Widget _buildStatusSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty,
            color: Colors.blue[600],
            size: 40,
          ),
          SizedBox(height: 12),
          Text(
            'Awaiting Client',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'The task is confirmed. Waiting for the client to start the task.',
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
                    _taskInformation!.title ?? 'Task',
                    style: GoogleFonts.montserrat(
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
              value: _requestInformation?.task_status ?? 'Confirmed',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
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
                      'Client Profile',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF03045E),
                      ),
                    ),
                    Text(
                      'Details',
                      style: GoogleFonts.montserrat(
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
                'Name', tasker?.user.firstName ?? 'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow(
                'Email', tasker?.user.email ?? 'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow(
                'Phone', tasker?.user.contact ?? 'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow(
                'Status', tasker?.user.accStatus ?? 'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow('Account', 'Verified', isVerified: true),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleCancelTask(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red[400]!),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel Task',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red[400],
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        // Expanded(
        //   child: ElevatedButton(
        //     onPressed: _handleRescheduleTask,
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: Colors.blue[600],
        //       padding: EdgeInsets.symmetric(vertical: 16),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(12),
        //       ),
        //       elevation: 2,
        //     ),
        //     child: Text(
        //       'Reschedule',
        //       style: GoogleFonts.montserrat(
        //         fontSize: 14,
        //         fontWeight: FontWeight.w600,
        //         color: Colors.white,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _buildTaskInfoRow(
      {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF03045E),
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
