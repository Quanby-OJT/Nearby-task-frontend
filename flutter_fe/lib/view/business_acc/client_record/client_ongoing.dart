import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/client_request.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/business_acc/client_record/client_finish.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

class ClientOngoing extends StatefulWidget {
  final int? ongoingID;
  final String? role;
  const ClientOngoing({super.key, this.ongoingID, this.role});

  @override
  State<ClientOngoing> createState() => _ClientOngoingState();
}

class _ClientOngoingState extends State<ClientOngoing> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController taskController = TaskController();
  final ProfileController _profileController = ProfileController();
  TaskModel? _taskInformation;
  ClientRequestModel? _requestInformation;
  bool _isLoading = true;
  final storage = GetStorage();
  AuthenticatedUser? tasker;
  Duration? _timeRemaining;
  Timer? _timer;
  String _requestStatus = 'Unknown';



  // Dispute Bottom Sheet State
  final TextEditingController _disputeTypeController = TextEditingController();
  final TextEditingController _disputeDetailsController =
      TextEditingController();
  final List<File> _imageEvidence = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disputeTypeController.dispose();
    _disputeDetailsController.dispose();
    super.dispose();
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
          await _jobPostService.fetchRequestInformation(widget.ongoingID ?? 0);
      debugPrint("Task Status: ${response.task_status}");
      setState(() {
        _requestInformation = response;
        _requestStatus = _requestInformation?.task_status ?? 'Unknown';
      });
      await _fetchTaskDetails();
      await _fetchTaskerDetails(_requestInformation!.tasker_id as int);
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
      // _startCountdownTimer();
    } catch (e) {
      debugPrint("Error fetching task details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleFinishTask() async {
    if (_requestInformation == null ||
        _requestInformation!.task_taken_id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task information not available')),
      );
      return;
    }

    final result = await taskController.updateRequest(
      _requestInformation?.task_taken_id ?? 0,
      'Finish',
      widget.role ?? '',
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'Time’s up!';
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    return '${days}d ${hours}h ${minutes}m';
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickMultiImage(
      imageQuality: 100,
      maxWidth: 1000,
      maxHeight: 1000,
    );

    List<XFile> xFilePick = pickedFile;

    if (xFilePick.isNotEmpty) {
      for (int i = 0; i < xFilePick.length; i++) {
        setState(() {
          _imageEvidence.add(File(xFilePick[i].path));
        });
      }
    }
  }

  Future<void> _handleTaskDispute() async {
    if (_requestInformation == null ||
        _requestInformation!.task_taken_id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task information not available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (childContext) => _buildDisputeBottomSheet(),
    );
  }

  Widget _buildDisputeBottomSheet() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'File a Dispute',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF03045E),
                ),
              ),
            ),
            Center(
              child: Text(
                '* Required Fields',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD43D4D),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Reason for Dispute *',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF03045E),
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _disputeTypeController.text.isEmpty
                  ? '--Select Reason of Dispute--'
                  : _disputeTypeController.text,
              items: <String>[
                '--Select Reason of Dispute--',
                'Poor Quality of Work',
                'Breach of Contract',
                'Task Still Not Completed',
                'Tasker Did Not Finish what\'s Required',
                'Others (Provide Details)'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child:
                      Text(value, style: GoogleFonts.montserrat(fontSize: 14)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _disputeTypeController.text = newValue ?? '';
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Details of the Dispute *',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF03045E),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _disputeDetailsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Provide Details About the Dispute',
                hintStyle: GoogleFonts.montserrat(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF03045E)),
                ),
              ),
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Provide some Evidence',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF03045E),
              ),
            ),
            SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageEvidence.isNotEmpty
                    ? SizedBox(
                        width: 300.0,
                        child: GridView.builder(
                          itemCount: _imageEvidence.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            return Center(
                              child: kIsWeb
                                  ? Image.network(_imageEvidence[index].path)
                                  : Image.file(_imageEvidence[index]),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FontAwesomeIcons.fileImage,
                                size: 40, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'Upload Photos (Screenshots, Actual Work)',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                    _fetchRequestDetails();
                  });
                  Navigator.pop(context);
                  try {
                    bool result = await taskController.raiseADispute(
                      _requestInformation?.task_taken_id ?? 0,
                      'Disputed',
                      widget.role ?? '',
                      _disputeTypeController.text,
                      _disputeDetailsController.text,
                      _imageEvidence,
                    );

                    if (result) {
                      if (!mounted) return;
                      setState(() {
                        _requestStatus = 'Disputed';
                      });
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => DisplayListRecordOngoing(),
                      //   ),
                      // );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Failed to raise dispute. Please Try Again.'),
                        ),
                      );
                    }
                  } catch (e, stackTrace) {
                    debugPrint("Error raising dispute: $e.");
                    debugPrintStack(stackTrace: stackTrace);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error occurred')),
                    );
                  } finally {
                    setState(() {
                      _isLoading = false;
                      _fetchRequestDetails();
                    });
                  }
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
                  'Open a Dispute',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
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
          'Ongoing Task',
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
                        if (_requestStatus == 'Ongoing') _buildTimerSection(),
                        if (_requestStatus == 'Disputed')
                          _buildDisputeSection(),
                        if (_requestStatus == 'Completed')
                          _buildCompletionSection(),
                        SizedBox(height: 16),
                        _buildTaskCard(),
                        SizedBox(height: 16),
                        _buildProfileCard(),
                        SizedBox(height: 24),
                        if (_requestStatus != 'Completed' &&
                            _requestStatus != 'Disputed')
                          _buildActionButton(),
                        if (_requestStatus == 'Completed' ||
                            _requestStatus == 'Disputed')
                          _buildBackButton(),
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
            'Task Completed!',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Congratulations on successfully completing this task!',
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

  Widget _buildBackButton() {
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

  Widget _buildTimerSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF03045E), Color(0xFF0A2472)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.timer,
              color: Colors.white,
              size: 40,
            ),
            SizedBox(height: 12),
            Text(
              'Time Remaining',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _timeRemaining != null
                  ? _formatDuration(_timeRemaining!)
                  : 'Calculating...',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
              value: _requestInformation?.task_status ?? 'Ongoing',
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
                      'Tasker Profile',
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
    return Column(
      children: [
        if(_requestInformation?.task_status != 'Completed')...[
          ElevatedButton(
            onPressed: _handleFinishTask,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: Color(0xFF3E9B52),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              'Mark Task as Finished',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          )
        ],
        SizedBox(height: 16),
        if (_requestInformation?.task_status != 'Disputed')
          ElevatedButton(
            onPressed: _handleTaskDispute,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFA73140),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              minimumSize: Size(double.infinity, 50),
            ),
            child: Text(
              'File a Dispute',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
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
