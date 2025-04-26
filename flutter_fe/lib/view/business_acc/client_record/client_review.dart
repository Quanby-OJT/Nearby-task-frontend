import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fe/view/business_acc/client_record/client_ongoing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/client_request.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/business_acc/client_record/client_finish.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:async';

import 'package:image_picker/image_picker.dart';

class _DisputeBottomSheet extends StatefulWidget {
  final Function(String reasonForDispute, String raisedBy, File? imageEvidence)
      onDisputeSubmit;

  const _DisputeBottomSheet({required this.onDisputeSubmit});

  @override
  __DisputeBottomSheetState createState() => __DisputeBottomSheetState();
}

class __DisputeBottomSheetState extends State<_DisputeBottomSheet> {
  final TextEditingController _disputeTypeController = TextEditingController();
  final TextEditingController _disputeDetailsController =
      TextEditingController();
  File? _imageEvidence;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _disputeTypeController.dispose();
    _disputeDetailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _imageEvidence = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            SizedBox(height: 16),
            Text(
              'Reason for Dispute',
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
                'Tasker is Unavailable',
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
            // Dispute Field
            Text(
              'Details of the Dispute',
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
            Text('Provide some Evidence',
                style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF03045E))),
            SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageEvidence != null
                    ? Image.file(_imageEvidence!, fit: BoxFit.cover)
                    : Icon(Icons.add_photo_alternate,
                        size: 40, color: Colors.grey[400]),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onDisputeSubmit(_disputeTypeController.text,
                      _disputeTypeController.text, _imageEvidence);
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
}

class ClientReview extends StatefulWidget {
  final int? requestID;
  final String? role;
  const ClientReview({super.key, this.requestID, this.role});

  @override
  State<ClientReview> createState() => _ClientReviewState();
}

class _ClientReviewState extends State<ClientReview> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController taskController = TaskController();
  final ProfileController _profileController = ProfileController();
  TaskModel? _taskInformation;
  ClientRequestModel? _requestInformation;
  bool _isLoading = true;
  final storage = GetStorage();
  AuthenticatedUser? client;
  Duration? _timeRemaining;
  Timer? _timer;
  String _requestStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTaskerDetails(int userId) async {
    try {
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      setState(() {
        client = user;
      });
    } catch (e) {
      debugPrint("Error fetching client details: $e");
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
        _requestStatus = _requestInformation?.task_status ?? 'Unknown';
      });

      debugPrint("Fetched request status of this task: $_requestStatus");
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
        _taskInformation = response?.task;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching task details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleFinishTask() async {
    debugPrint("_requestInformation: $_requestInformation");

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
      builder: (context) => _FeedbackBottomSheet(
        onFeedbackSubmit: (int rating, String feedback, String? report) async {
          setState(() {
            _isLoading = true;
          });
          try {
            bool result = await taskController.acceptRequest(
              _requestInformation?.task_taken_id ?? 0,
              'Finish',
              widget.role ?? '',
            );

            bool result2 = await taskController.rateTheTasker(
                _requestInformation?.task_taken_id ?? 0,
                _requestInformation?.tasker_id ?? 0,
                rating,
                feedback);
            if (result && result2) {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClientFinish(
                    finishID: _requestInformation?.task_taken_id ?? 0,
                    role: widget.role,
                  ),
                ),
              );
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to finish task')),
              );
            }
          } catch (e, stackTrace) {
            debugPrint("Error finishing task: $e.");
            debugPrintStack(stackTrace: stackTrace);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error occurred')),
              );
            }
          } finally {
            setState(() {
              _isLoading = false;
            });
          }
        },
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
          'Review Task',
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
                        // Timer Section
                        if (_requestStatus == 'Review') _buildReviewSection(),
                        SizedBox(height: 16),
                        // Task Card
                        _buildTaskCard(),
                        SizedBox(height: 16),
                        // Client Profile Card
                        _buildProfileCard(),
                        SizedBox(height: 24),
                        // Action Button
                        _buildFinishActionButton(context),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildReviewSection() {
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
            'Make You Review',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Make sure to review the task before clicking the button below.",
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
            SizedBox(height: 16),
            _buildTaskInfoRow(
              icon: Icons.location_pin,
              label: 'Location',
              value: _taskInformation?.location ?? 'Not specified',
            ),
            SizedBox(height: 12),
            _buildTaskInfoRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: _taskInformation?.period ?? 'Not specified',
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
                'Name', client?.user.firstName ?? 'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow(
                'Email', client?.user.email ?? 'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow(
                'Phone', client?.user.contact ?? 'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow(
                'Status', client?.user.accStatus ?? 'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow('Account', 'Verified', isVerified: true),
          ],
        ),
      ),
    );
  }

  void _showActionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
                  _requestInformation?.task_status != 'Disputed'
                      ? 'Finish Task and Release Payment'
                      : 'Settle Dispute and Release Payment',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_requestInformation?.task_status != 'Disputed')
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
              SizedBox(height: 16), // Extra padding at the bottom
            ],
          ),
        );
      },
    );
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
      builder: (context) => _DisputeBottomSheet(
        onDisputeSubmit: (String reasonForDispute, String raisedBy,
            File? imageEvidence) async {
          setState(() {
            _isLoading = true;
          });
          try {
            bool result = await taskController.acceptRequest(
              _requestInformation?.task_taken_id ?? 0,
              'Finish',
              widget.role ?? '',
            );

            if (result) {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClientFinish(
                    finishID: _requestInformation?.task_taken_id ?? 0,
                    role: widget.role,
                  ),
                ),
              );
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to finish task')),
              );
            }
          } catch (e, stackTrace) {
            debugPrint("Error finishing task: $e.");
            debugPrintStack(stackTrace: stackTrace);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error occurred')),
              );
            }
          } finally {
            setState(() {
              _isLoading = false;
            });
          }
        },
      ),
    );
  }

  Widget _buildFinishActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showActionBottomSheet(context),
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

//Finish Task and Release Payment
class _FeedbackBottomSheet extends StatefulWidget {
  final Function(int rating, String feedback, String? report) onFeedbackSubmit;

  const _FeedbackBottomSheet({required this.onFeedbackSubmit});

  @override
  __FeedbackBottomSheetState createState() => __FeedbackBottomSheetState();
}

class __FeedbackBottomSheetState extends State<_FeedbackBottomSheet> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _reportController = TextEditingController();
  bool _isSatisfied = true;

  @override
  void dispose() {
    _feedbackController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              style: GoogleFonts.montserrat(
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
              style: GoogleFonts.montserrat(
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
            if (!_isSatisfied) ...[
              SizedBox(height: 16),
              Text(
                'Report Issue',
                style: GoogleFonts.montserrat(
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
                    borderSide: BorderSide(color: Colors.red[700]!),
                  ),
                ),
                style: GoogleFonts.montserrat(fontSize: 14),
              ),
            ],
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_rating == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please provide a rating')),
                    );
                    return;
                  }
                  widget.onFeedbackSubmit(
                    _rating,
                    _feedbackController.text,
                    _isSatisfied ? null : _reportController.text,
                  );
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
}
