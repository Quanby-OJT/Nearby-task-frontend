import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/task_request_controller.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/client_request.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:get_storage/get_storage.dart';

import '../../../model/disputes.dart';

class TaskDisputed extends StatefulWidget {
  // final int? finishID;
  final String role;
  final TaskFetch taskInformation;
  const TaskDisputed({super.key, required this.taskInformation, required this.role});

  @override
  State<TaskDisputed> createState() => _TaskDisputedState();
}

class _TaskDisputedState extends State<TaskDisputed> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController taskController = TaskController();
  final TaskRequestController taskRequestController = TaskRequestController();
  final ProfileController _profileController = ProfileController();
  Disputes? disputes;
  ClientRequestModel? _requestInformation;
  bool _isLoading = true;
  final storage = GetStorage();
  String? _role;

  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
  }
  Future<void> _fetchTaskDetails() async {
    try {
      final response = await taskRequestController.getDispute(widget.taskInformation.taskTakenId);
      setState(() {
        disputes = response;
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF03045E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Task Information',
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
          : disputes == null
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
                        // Completion Status Section
                        _buildDisputeSection(),
                        SizedBox(height: 16),
                        // Task Card
                        _buildTaskCard(),
                        SizedBox(height: 16),
                        // Client/Tasker Profile Card
                        _buildProfileCard(),
                        SizedBox(height: 24),
                        // Action Button
                        _buildActionButton(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDisputeSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Column(
        children: [
          Icon(
            FontAwesomeIcons.gavel,
            color: Colors.yellow[600],
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'Dispute Raised to this Task!',
            style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.yellow[800]),
          ),
          SizedBox(height: 8),
          Text(
            'Please Wait for Our Team to review your dispute and file Appropriate Action.',
            textAlign: TextAlign.center,
            style:
            GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600]),
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
                    disputes?.taskAssignment?.task?.title ?? 'Task',
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
              icon: null,
              label: 'Description',
              value: '',
            ),
            SizedBox(height: 8),
            buildTextSection(widget.taskInformation.post_task?.description ?? 'N/A'),
            SizedBox(height: 8),
            _buildTaskInfoRow(
              icon: FontAwesomeIcons.gavel,
              label: "Reason for Dispute",
              value:  '',
            ),
            SizedBox(height: 8),
            buildTextSection(disputes?.disputeReason ?? 'Not available'),
            SizedBox(height: 8),
            _buildTaskInfoRow(
                icon: FontAwesomeIcons.noteSticky,
                label: "Dispute Details",
                value: ""
            ),
            SizedBox(height: 8),
            buildTextSection(disputes?.disputeDetails ?? 'Not available')
          ],
        ),
      ),
    );
  }

  Widget buildTextSection(String info){
    return Text(
      info,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF03045E),
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildProfileCard() {
    String role = GetStorage().read('role');
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
                     role == "Client"
                          ? "Tasker Profile"
                          : "Client Profile",
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
            role == "Client" ? _buildProfileInfoRow('Name', "${widget.taskInformation.post_task?.client?.user?.firstName} ${widget.taskInformation.post_task?.client?.user?.middleName ?? ""} ${widget.taskInformation.post_task?.client?.user?.lastName}") : _buildProfileInfoRow('Name', "${widget.taskInformation.tasker?.user?.firstName} ${widget.taskInformation.tasker?.user?.middleName ?? ""} ${widget.taskInformation.tasker?.user?.lastName}"),
            SizedBox(height: 8),
            if(role == "Client")...[
              _buildProfileInfoRow('Specialization', widget.taskInformation.tasker?.specialization ?? 'Not available'),
              SizedBox(height: 8),
              _buildProfileInfoRow('Related Specialization', widget.taskInformation.tasker?.skills ?? 'Not available'),
            ],
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
          Navigator.pop(context); // Return to previous screen
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

  Widget _buildTaskInfoRow(
      {required IconData? icon, required String label, required String value}) {
    return Row(
      children: [
        if(icon != null) ...[
          Icon(icon, color: Colors.grey[600], size: 20),
          SizedBox(width: 8)
        ],
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
