import 'dart:io';

import 'package:flutter/material.dart';
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
      setState(() {
        _requestInformation = response;
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
        _taskInformation = response?.task;
        _isLoading = false;
      });
      _startCountdownTimer();
    } catch (e) {
      debugPrint("Error fetching task details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startCountdownTimer() {
    if (_taskInformation?.duration != null &&
        _taskInformation?.period != null) {
      int durationInDays = int.parse(_taskInformation!.duration);
      String period = _taskInformation!.period.toLowerCase();

      if (period.contains('week')) {
        durationInDays *= 7;
      } else if (period.contains('month')) {
        durationInDays *= 30;
      }

      DateTime endDate = DateTime.now().add(Duration(days: durationInDays));
      _timeRemaining = endDate.difference(DateTime.now());

      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _timeRemaining = endDate.difference(DateTime.now());
          if (_timeRemaining!.isNegative) {
            _timeRemaining = Duration.zero;
            timer.cancel();
          }
        });
      });
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'Time’s up!';
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    return '${days}d ${hours}h ${minutes}m';
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to finish task')),
              );
            }
          } catch (e, stackTrace) {
            debugPrint("Error finishing task: $e.");
            debugPrintStack(stackTrace: stackTrace);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error occurred')),
            );
          } finally {
            setState(() {
              _isLoading = false;
            });
          }
        },
      ),
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
        onDisputeSubmit: (String reasonForDispute, String raisedBy, File? imageEvidence) async {
          setState(() {
            _isLoading = true;
          });
          try {
            bool result = await taskController.raiseADispute(
              _requestInformation?.task_taken_id ?? 0,
              'Disputed',
              widget.role ?? '',
              imageEvidence ?? File(''),
            );

            if (result) {
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to raise dispute. Please Try Again.')),
              );
            }
          } catch (e, stackTrace) {
            debugPrint("Error finishing task: $e.");
            debugPrintStack(stackTrace: stackTrace);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error occurred')),
            );
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
                        _buildTimerSection(),
                        SizedBox(height: 16),
                        _buildTaskCard(),
                        SizedBox(height: 16),
                        _buildProfileCard(),
                        SizedBox(height: 24),
                        _buildActionButton(),
                      ],
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
    return Column(children: [
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
    ]);
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

  // void _disputeAlertDialog(BuildContext parentContext) {
  //   showDialog(
  //       context: context,
  //       builder: (BuildContext childContext) {
  //         return AlertDialog(
  //             title: Text('File a Dispute'),
  //             content: Text(
  //                 'Do you had dispute/s with your tasker when it comes to: \n 1. Quality of their Work? \n 2. Their availability? \n 3. Others?'),
  //             actions: [
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //                 child: Text('Cancel',
  //                     style: TextStyle(
  //                       color: Color(0XFFD43D4D),
  //                     )),
  //               ),
  //               TextButton(
  //                   onPressed: () async {
  //                     setState(() {
  //                       _isLoading = true;
  //                     });
  //                     try {
  //                       bool result = await taskController.acceptRequest(
  //                         _requestInformation?.task_taken_id ?? 0,
  //                         'Disputed',
  //                         widget.role ?? '',
  //                       );
  //
  //                       if (result) {
  //                         Navigator.pop(context);
  //                         showDialog(
  //                             context: context,
  //                             builder: (BuildContext context) {
  //                               return AlertDialog(
  //                                   title: Text(
  //                                       "Your Task is Now Open to Dispute"),
  //                                   actions: [
  //                                     TextButton(
  //                                         onPressed: () {
  //                                           Navigator.of(context).pop();
  //                                         },
  //                                         child: Text("Okay"))
  //                                   ]);
  //                             });
  //                       } else {
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                           SnackBar(content: Text('Failed to finish task')),
  //                         );
  //                       }
  //                     } catch (e, stackTrace) {
  //                       debugPrint("Error finishing task: $e.");
  //                       debugPrintStack(stackTrace: stackTrace);
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         SnackBar(content: Text('Error occurred')),
  //                       );
  //                     } finally {
  //                       setState(() {
  //                         _isLoading = false;
  //                       });
  //                     }
  //                   },
  //                   child: Text("Yes",
  //                       style: TextStyle(
  //                         color: Color(0XFF4DBF66),
  //                       )))
  //             ]);
  //       });
  // }
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

//Finish Task and Release Payment
class _DisputeBottomSheet extends StatefulWidget {
  final Function(String reasonForDispute, String raisedBy, File? imageEvidence) onDisputeSubmit;

  const _DisputeBottomSheet({required this.onDisputeSubmit});

  @override
  __DisputeBottomSheetState createState() => __DisputeBottomSheetState();
}

class __DisputeBottomSheetState extends State<_DisputeBottomSheet> {
  final TextEditingController _disputeTypeController = TextEditingController();
  final TextEditingController _disputeDetailsController = TextEditingController();
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
              value: _disputeTypeController.text.isEmpty ? '--Select Reason of Dispute--' : _disputeTypeController.text,
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
                  child: Text(value, style: GoogleFonts.montserrat(fontSize: 14)),
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
                  borderSide: BorderSide(color: Colors.grey[300]!
                  ),
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
            Text(
              'Provide some Evidence',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF03045E)
              )
            ),
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
                    : Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[400]),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onDisputeSubmit(
                    _disputeTypeController.text,
                    _disputeTypeController.text,
                    _imageEvidence
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
