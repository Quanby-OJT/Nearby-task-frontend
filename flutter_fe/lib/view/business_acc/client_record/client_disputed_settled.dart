import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/task_request_controller.dart';
import 'package:flutter_fe/model/disputes.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/client_request.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:get_storage/get_storage.dart';

class ClientDisputedSettled extends StatefulWidget {
  final int? finishID;
  final String? role;
  const ClientDisputedSettled({super.key, this.finishID, this.role});

  @override
  State<ClientDisputedSettled> createState() => _ClientDisputedSettledState();
}

class _ClientDisputedSettledState extends State<ClientDisputedSettled> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController taskController = TaskController();
  final ProfileController _profileController = ProfileController();
  final TaskRequestController _taskRequestController = TaskRequestController();
  Disputes? dispute;
  ClientRequestModel? _requestInformation;
  bool _isLoading = true;
  final storage = GetStorage();
  String? _role;
  AuthenticatedUser? tasker;

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
    _fetchUserData();

    debugPrint("Task ID from the widget: ${widget.finishID}");
  }

  Future<void> _fetchUserData() async {
    try {
      int userId = storage.read("user_id");
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      debugPrint(user.toString());
      setState(() {
        _role = user?.user.role;
      });
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTaskerDetails(int userId) async {
    try {
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      debugPrint(user.toString());
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
          await _jobPostService.fetchRequestInformation(widget.finishID ?? 0);
      debugPrint("Fetched request details: $response");
      setState(() {
        _requestInformation = response;
      });
      await _fetchTaskDetails();
      if (widget.role == "Client") {
        await _fetchTaskerDetails(_requestInformation!.tasker_id as int);
      } else {
        await _fetchTaskerDetails(_requestInformation!.client_id as int);
      }
    } catch (e) {
      debugPrint("Error fetching task details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTaskDetails() async {
    try {
      final response =
          await _taskRequestController.getDispute(widget.finishID ?? 0);
      setState(() {
        dispute = response;
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
          'Settled Dispute Tasks',
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
          : dispute == null
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
                        _buildCompletionSection(),
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

  Widget _buildCompletionSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
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
          SizedBox(height: 12),
          Text(
            'Disputed Task Settled.',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Our Team had Successfully Settled this task. You can now rate the tasker.',
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
                    dispute?.taskAssignment?.task?.title ?? 'Task',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF03045E),
                    ),
                  ),
                ),
              ],
            ),
            _buildTaskInfoRow(
              icon: Icons.info,
              label: 'Dispute Reason',
              value: dispute?.disputeReason ?? 'Not Available',
            ),
            SizedBox(height: 12),
            _buildTaskInfoRow(
              icon: Icons.info,
              label: 'Dispute Details',
              value: "",
            ),
            SizedBox(height: 12),
            Text(dispute?.disputeDetails ?? 'Not available',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF03045E),
                )),
            SizedBox(height: 12),
            _buildTaskInfoRow(
              icon: Icons.info,
              label: 'Status',
              value: _requestInformation?.task_status ??
                  'Dispute has been Settled',
            ),
            SizedBox(height: 12),
            _buildTaskInfoRow(
              icon: Icons.info,
              label: 'Moderator Action',
              value: '',
            ),
            SizedBox(height: 8),
            Text(dispute?.moderatorAction ?? 'Not available',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF03045E),
                )),
            SizedBox(height: 8),
            _buildTaskInfoRow(
                icon: FontAwesomeIcons.noteSticky,
                label: "Moderator Notes",
                value: ""),
            SizedBox(height: 8),
            Text(dispute?.moderatorNotes ?? 'Not available',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ))
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
                      widget.role! == "Client"
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
