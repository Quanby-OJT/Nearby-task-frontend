import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/client_request.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/task/task_finished.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class UserFeedback extends StatefulWidget {
  final TaskFetch? taskInformation;
  final String? role;
  const UserFeedback({Key? key, this.taskInformation, this.role})
      : super(key: key);

  @override
  State<UserFeedback> createState() => _UserFeedbackState();
}

class _UserFeedbackState extends State<UserFeedback> {
  final TaskController taskController = TaskController();
  final JobPostService _jobPostService = JobPostService();
  TaskModel? _taskInformation;
  ClientRequestModel? _requestInformation;
  bool _isLoading = true;
  final storage = GetStorage();
  AuthenticatedUser? tasker;

  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _issueController = TextEditingController();
  bool _isSatisfied = true;
  String? selectedReason;
  final List<File> _imageEvidence = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> positiveFeedbackReasons = [
    'Task completed exceptionally',
    'Great communication',
    'Exceeded expectations',
    'Professional and timely',
    'Other'
  ];

  final List<String> negativeFeedbackReasons = [
    'Task incomplete',
    'Poor communication',
    'Missed deadlines',
    'Quality issues',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _issueController.dispose();
    super.dispose();
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
      debugPrint("Error fetching request details: $e");
    } finally {
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
      });
    } catch (e) {
      debugPrint("Error fetching task details: $e");
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile.isNotEmpty) {
      setState(() {
        _imageEvidence.addAll(pickedFile.map((xFile) => File(xFile.path)));
      });
    }
  }

  String _getRatingDescription() {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Not Rated';
    }
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a rating')),
      );
      return;
    }
    if (selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a feedback reason')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool result = await taskController.rateTheTasker(
        _requestInformation?.task_taken_id ?? 0,
        widget.role == 'Tasker'
            ? _requestInformation?.client_id ?? 0
            : _requestInformation?.tasker_id ?? 0,
        _rating,
        _feedbackController.text.isNotEmpty
            ? '[$selectedReason] ${_feedbackController.text}'
            : selectedReason!,
      );

      if (result) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              'Feedback Submitted',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Thank you for your feedback!',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(color: Color(0xFF03045E)),
                ),
              ),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TaskFinished(taskInformation: widget.taskInformation),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit feedback')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("Error submitting feedback: $e");
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.role == 'Tasker' ? 'Rate Client' : 'Rate Tasker',
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
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF03045E)))
            : Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.role == 'Tasker'
                              ? 'Rate Your Client'
                              : 'Rate Your Tasker',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          semanticsLabel:
                              'Rate Your ${widget.role == 'Tasker' ? 'Client' : 'Tasker'}',
                        ),
                        SizedBox(height: 8),
                        Text(
                          _getRatingDescription(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 16),
                        // Rating Stars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < _rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 36,
                              ),
                              onPressed: () {
                                setState(() {
                                  _rating = index + 1;
                                  _isSatisfied = _rating > 2;
                                  selectedReason = null;
                                });
                              },
                            );
                          }),
                        ),
                        SizedBox(height: 16),
                        // Feedback Reason Dropdown
                        Text(
                          'Feedback Reason',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedReason,
                          hint: Text(
                            'Select a reason',
                            style: GoogleFonts.poppins(color: Colors.grey[400]),
                          ),
                          items: (_isSatisfied
                                  ? positiveFeedbackReasons
                                  : negativeFeedbackReasons)
                              .map((String reason) {
                            return DropdownMenuItem<String>(
                              value: reason,
                              child: Text(
                                reason,
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedReason = newValue;
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
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF03045E)),
                            ),
                          ),
                          isExpanded: true,
                        ),
                        SizedBox(height: 16),
                        // Feedback Details
                        Text(
                          _isSatisfied
                              ? 'Additional Feedback'
                              : 'Issue Details',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                _isSatisfied ? Colors.black : Colors.red[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _isSatisfied
                              ? _feedbackController
                              : _issueController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: _isSatisfied
                                ? 'Share your positive experience...'
                                : 'Describe the issue in detail...',
                            hintStyle:
                                GoogleFonts.poppins(color: Colors.grey[400]),
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
                              borderSide: BorderSide(
                                  color: _isSatisfied
                                      ? const Color(0xFF03045E)
                                      : const Color(0xFFFF0000),
                                  width: 2),
                            ),
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),

                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submitFeedback,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB71A4A),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  'Submit Feedback',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF03045E)),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
