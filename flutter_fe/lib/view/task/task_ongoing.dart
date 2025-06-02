import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/view/custom_loading/custom_scaffold.dart';
import 'package:flutter_fe/view/task/task_finished.dart';
import 'package:flutter_fe/view/task/task_review.dart';
import 'package:flutter_fe/view/task_user/user_feedback.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/client_request.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

class TaskOngoing extends StatefulWidget {
  final TaskFetch? taskInformation;
  final String? role;
  const TaskOngoing({super.key, this.taskInformation, this.role});

  @override
  State<TaskOngoing> createState() => _TaskOngoingState();
}

class _TaskOngoingState extends State<TaskOngoing> {
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

  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _reportController = TextEditingController();
  bool _isSatisfied = true;

  final TextEditingController _disputeTypeController = TextEditingController();
  final TextEditingController _disputeDetailsController =
      TextEditingController();
  final List<File> _imageEvidence = [];
  final ImagePicker _picker = ImagePicker();
  String? selectedReason = 'Task is finished';
  String? _role;

  final List<String> finishReasons = [
    'Task is finished',
    'All requirements met',
    'Completed ahead of schedule',
    'Successfully collaborated with team',
    'No further action needed',
    'Task marked complete by supervisor',
    'Automated process completed it',
    'Duplicate of another completed task',
    'Task is no longer necessary',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackController.dispose();
    _reportController.dispose();
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
        _role = user?.user.role;
      });

      debugPrint("User Role: $_role");
    } catch (e) {
      debugPrint("Error fetching tasker details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRequestDetails() async {
    try {
      final response = await _jobPostService
          .fetchRequestInformation(widget.taskInformation?.taskTakenId ?? 0);
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
    } catch (e) {
      debugPrint("Error fetching task details: $e");
      setState(() {
        _isLoading = false;
      });
    }
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

  Future<void> _handleFinishTask() async {
    if (_requestInformation == null ||
        _requestInformation!.task_taken_id == null) {
      CustomScaffold(message: 'Task information not available', color: Colors.red);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFeedbackBottomSheet(),
    );
  }

  Future<void> _handleTaskDispute() async {
    if (_requestInformation == null ||
        _requestInformation!.task_taken_id == null) {
      CustomScaffold(message: 'Task information not available', color: Colors.red);
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

  Widget _buildFeedbackBottomSheet() {
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
            Text(
              'Rate & Review Tasker',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF03045E),
              ),
            ),
            SizedBox(height: 16),
            // Rating Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                      _isSatisfied = _rating > 2;
                    });
                  },
                );
              }),
            ),
            SizedBox(height: 16),
            // Feedback Field
            Text(
              'Feedback',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF03045E),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
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
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            if (!_isSatisfied) ...[
              SizedBox(height: 16),
              Text(
                'Report Issue',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[700],
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _reportController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe the issue for reporting...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
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
                    borderSide: BorderSide(color: Colors.red[700]!),
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_rating == 0) {
                    CustomScaffold(message: 'Please provide a rating', color: Colors.red);
                    return;
                  }
                  setState(() {
                    _isLoading = true;
                  });
                  try {
                    final result = await taskController.updateRequest(
                      _requestInformation?.task_taken_id ?? 0,
                      'Finish',
                      widget.taskInformation?.taskDetails!.client?.user?.role ??
                          '',
                    );

                    // bool result2 = await taskController.rateTheTasker(
                    //     _requestInformation?.task_taken_id ?? 0,
                    //     _requestInformation?.tasker_id ?? 0,
                    //     _rating,
                    //     _feedbackController.text);
                    if (result.containsKey('success') && result['success']) {
                      if (!mounted) return;

                      setState(() {
                        _requestStatus = 'Completed';
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskFinished(
                            taskInformation: widget.taskInformation,
                          ),
                        ),
                      );
                    } else {
                      if (!mounted) return;
                      CustomScaffold(message: 'Failed to finish task', color: Colors.red);
                    }
                  } catch (e, stackTrace) {
                    debugPrint("Error finishing task: $e.");
                    debugPrintStack(stackTrace: stackTrace);
                    if (mounted) {
                      CustomScaffold(message: 'Error occurred', color: Colors.red);
                    }
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
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
                  'Submit Feedback & Release Payment',
                  style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF03045E),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Reason for Dispute',
              style: GoogleFonts.poppins(
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
                  child: Text(value, style: GoogleFonts.poppins(fontSize: 14)),
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
              'Details of the Dispute',
              style: GoogleFonts.poppins(
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
                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
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
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Provide some Evidence',
              style: GoogleFonts.poppins(
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
                      widget.taskInformation?.taskDetails!.client?.user?.role ??
                          '',
                      _disputeTypeController.text,
                      _disputeDetailsController.text,
                      _imageEvidence,
                    );

                    if (result) {
                      if (!mounted) return;
                      setState(() {
                        _requestStatus = 'Disputed';
                      });
                    } else {
                      CustomScaffold(message: 'Failed to raise dispute. Please Try Again.', color: Colors.red);
                    }
                  } catch (e, stackTrace) {
                    debugPrint("Error raising dispute: $e.");
                    debugPrintStack(stackTrace: stackTrace);
                    CustomScaffold(message: 'Error occurred', color: Colors.red);
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
                  style: GoogleFonts.poppins(
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
                        if (_requestStatus == 'Ongoing' || _requestStatus == 'Reworking') _buildStatusSection(),
                        SizedBox(height: 16),
                        _buildTaskCard(),
                        if (widget.taskInformation?.tasker?.user == null)
                          _buildClientProfileCard(),
                           SizedBox(height: 16),
                        if (widget.taskInformation?.tasker?.user == null)
                          _buildtaskerActionButton(),
                           SizedBox(height: 16),
                        if (widget.taskInformation?.tasker?.user != null)
                          _buildTaskerProfileCard(),
                           SizedBox(height: 16),
                        if (widget.taskInformation?.tasker?.user != null)
                          _buildclientActionButton()
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusSection() {
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
            SizedBox(height: 8),
            Text(
              'Active Task',
              style: GoogleFonts.poppins(
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

  Future<void> _handleTaskerFinishTask(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: Center(
          child: Text(
            'Finish Task',
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
              'Are you sure you want to finish this task?',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Leave a review message:',
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
                items: finishReasons.map((String reason) {
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
                    setState(() {
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

                    final String value = 'Review';
                    final result = await taskController.updateRequest(
                      _requestInformation?.task_taken_id ?? 0,
                      value,
                      'Tasker',
                      rejectionReason: selectedReason,
                    );
                    if (result.containsKey('success') && result['success']) {
                      if (!mounted) return;
                      Navigator.pop(context, true);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskReview(
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
     CustomScaffold(message: 'Task finished successfully', color: Colors.green);
    }
  }

  Future<void> _handleClientFinishTask(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: Center(
          child: Text(
            'Finish Task',
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
              'Are you sure you want to finish this task?',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Leave a review message:',
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
                items: finishReasons.map((String reason) {
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
                    setState(() {
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

                    final String value = 'Finish';
                   final result = await taskController.updateRequest(
                      _requestInformation?.task_taken_id ?? 0,
                      value,
                      'Client',
                      rejectionReason: selectedReason,
                    );
                    if (result.containsKey('success') && result['success']) {
                      if (!mounted) return;
                      Navigator.pop(context, true);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserFeedback(
                            taskInformation: widget.taskInformation,
                          ),
                        ),
                      );
                    } else {
                      Navigator.pop(context, false);
                      setState(() {
                        _isLoading = false;
                      });
                      CustomScaffold(message: 'Failed to finish task', color: Colors.red);
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
      CustomScaffold(message: 'Task Finished', color: Colors.green);
    }
  }

  Widget _buildtaskerActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleTaskerFinishTask(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF03045E),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          'Finish Task',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
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
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF03045E),
                    ),
                  ),
                ),
              ],
            ),
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
                      "Tasker Profile",
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
                      "Client Profile",
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
              (widget.taskInformation?.taskDetails!.client?.user != null)
                  ? '${widget.taskInformation!.taskDetails!.client!.user!.firstName ?? ''} ${widget.taskInformation!.taskDetails!.client!.user!.lastName ?? ''}'
                      .trim()
                  : 'Not available',
            ),
            SizedBox(height: 8),
            _buildProfileInfoRow(
                'Email',
                widget.taskInformation?.taskDetails!.client?.user?.email ??
                    'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow(
                'Phone',
                widget.taskInformation?.taskDetails!.client?.user?.contact ??
                    'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow(
                'Status',
                widget.taskInformation?.taskDetails!.client?.user?.accStatus ??
                    'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow('Account', 'Verified', isVerified: true),
          ],
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

  Widget _buildclientActionButton() {
    return Column(
      children: [
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _handleClientFinishTask(context),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
            backgroundColor: Color(0xFFB71A4A),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(
            _requestInformation?.task_status != 'Dispute Settled'
                ? 'Finish Task'
                : 'Settle Dispute',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 16),
        if (_requestInformation?.task_status != 'Disputed')
          OutlinedButton(
            onPressed: () => _handleTaskDispute(),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              side: BorderSide(color: Colors.blue[600]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Dispute',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue[600],
              ),
            ),
          ),
      ],
    );
  }
}
