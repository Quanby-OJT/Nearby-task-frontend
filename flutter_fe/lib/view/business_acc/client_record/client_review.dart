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
import 'dart:async';

import 'package:image_picker/image_picker.dart';

import '../../components/modals/dispute_bottom_sheet.dart';
import 'display_list_ongoing.dart';

// class _DisputeBottomSheet extends StatefulWidget {
//   final Function(
//           String reasonForDispute, String raisedBy, List<File> imageEvidence)
//       onDisputeSubmit;
//
//   const _DisputeBottomSheet({required this.onDisputeSubmit});
//
//   @override
//   __DisputeBottomSheetState createState() => __DisputeBottomSheetState();
// }
//
// class __DisputeBottomSheetState extends State<_DisputeBottomSheet> {
//   final TextEditingController _disputeTypeController = TextEditingController();
//   final TextEditingController _disputeDetailsController =
//       TextEditingController();
//   final TaskController taskController = TaskController();
//   ClientRequestModel? _requestInformation;
//   final List<File> _imageEvidence = [];
//   final bool _isLoading = false;
//   final String _requestStatus = "";
//
//   final ImagePicker _picker = ImagePicker();
//
//   @override
//   void dispose() {
//     _disputeTypeController.dispose();
//     _disputeDetailsController.dispose();
//     super.dispose();
//   }
//
//   Future _pickImage() async {
//     final pickedFile = await _picker.pickMultiImage(
//       imageQuality: 100,
//       maxWidth: 1000,
//       maxHeight: 1000,
//     );
//
//     List<XFile> xFilePick = pickedFile;
//
//     if (xFilePick.isNotEmpty) {
//       for (int i = 0; i < xFilePick.length; i++) {
//         setState(() {
//           _imageEvidence.add(File(xFilePick[i].path));
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(
//         bottom: MediaQuery.of(context).viewInsets.bottom,
//         left: 16,
//         right: 16,
//         top: 16,
//       ),
//       child: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: Text(
//                 'File a Dispute',
//                 style: GoogleFonts.montserrat(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF03045E),
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Reason for Dispute',
//               style: GoogleFonts.montserrat(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF03045E),
//               ),
//             ),
//             SizedBox(height: 8),
//             DropdownButtonFormField<String>(
//               value: _disputeTypeController.text.isEmpty
//                   ? '--Select Reason of Dispute--'
//                   : _disputeTypeController.text,
//               items: <String>[
//                 '--Select Reason of Dispute--',
//                 'Poor Quality of Work',
//                 'Breach of Contract',
//                 'Task Still Not Completed',
//                 'Tasker Did Not Finish what\'s Required',
//                 'Others (Provide Details)'
//               ].map<DropdownMenuItem<String>>((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child:
//                       Text(value, style: GoogleFonts.montserrat(fontSize: 14)),
//                 );
//               }).toList(),
//               onChanged: (String? newValue) {
//                 setState(() {
//                   _disputeTypeController.text = newValue ?? '';
//                 });
//               },
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: Colors.grey[300]!),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: Colors.grey[300]!),
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//             // Dispute Field
//             Text(
//               'Details of the Dispute',
//               style: GoogleFonts.montserrat(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF03045E),
//               ),
//             ),
//             SizedBox(height: 8),
//             TextField(
//               controller: _disputeDetailsController,
//               maxLines: 3,
//               decoration: InputDecoration(
//                 hintText: 'Provide Details About the Dispute',
//                 hintStyle: GoogleFonts.montserrat(color: Colors.grey[400]),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: Colors.grey[300]!),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: Colors.grey[300]!),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: Color(0xFF03045E)),
//                 ),
//               ),
//               style: GoogleFonts.montserrat(fontSize: 14),
//             ),
//             SizedBox(height: 16),
//             Text('Provide some Evidence',
//                 style: GoogleFonts.montserrat(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Color(0xFF03045E))),
//             SizedBox(height: 8),
//             GestureDetector(
//               onTap: _pickImage,
//               child: Container(
//                 height: 120,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey[300]!),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: _imageEvidence != null
//                     ? SizedBox(
//                         width: 300.0, // To show images in particular area only
//                         child: _imageEvidence
//                                 .isEmpty // If no images is selected
//                             ? const Center(
//                                 child: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                     Icon(FontAwesomeIcons.fileImage,
//                                         size: 40, color: Colors.grey),
//                                     SizedBox(width: 8),
//                                     Text(
//                                         'Upload Photos (Screenshots, Actual Work)',
//                                         style: TextStyle(
//                                             fontSize: 16, color: Colors.grey))
//                                   ]))
//                             // If atleast 1 images is selected
//                             : GridView.builder(
//                                 itemCount: _imageEvidence.length,
//                                 gridDelegate:
//                                     const SliverGridDelegateWithFixedCrossAxisCount(
//                                         crossAxisCount: 3
//                                         // Horizontally only 3 images will show
//                                         ),
//                                 itemBuilder: (BuildContext context, int index) {
//                                   // TO show selected file
//                                   return Center(
//                                       child: kIsWeb
//                                           ? Image.network(
//                                               _imageEvidence[index].path)
//                                           : Image.file(_imageEvidence[index]));
//                                   // If you are making the web app then you have to
//                                   // use image provider as network image or in
//                                   // android or iOS it will as file only
//                                 },
//                               ),
//                       )
//                     : Icon(Icons.add_photo_alternate,
//                         size: 40, color: Colors.grey[400]),
//               ),
//             ),
//             SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   widget.onDisputeSubmit(_disputeTypeController.text,
//                       _disputeDetailsController.text, _imageEvidence);
//                   Navigator.pop(context);
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Color(0xFF03045E),
//                   padding: EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 2,
//                 ),
//                 child: Text(
//                   'Open a Dispute',
//                   style: GoogleFonts.montserrat(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//           ],
//         ),
//       ),
//     );
//   }
// }

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

  Future<bool> _handleFinishTask() async {
    if (_requestInformation == null ||
        _requestInformation!.task_taken_id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task information not available')),
      );
      return false;
    }

    final BuildContext outerContext = context;
    return await showModalBottomSheet<bool>(
      context: outerContext,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) => _FeedbackBottomSheet(
        onFeedbackSubmit: (int rating, String feedback, String? report,
            Function(bool) onComplete) async {
          setState(() {
            _isLoading = true;
          });
          try {
            final result = await taskController.updateRequest(
              _requestInformation?.task_taken_id ?? 0,
              'Finish',
              widget.role ?? '',
            );

            //This is moved when the task is completed.
            // bool result2 = await taskController.rateTheTasker(
            //   _requestInformation?.task_taken_id ?? 0,
            //   _requestInformation?.tasker_id ?? 0,
            //   rating,
            //   feedback,
            // );

            final bool success = result['success'];

            if (!mounted) {
              Navigator.pop(bottomSheetContext, success);
              return;
            }

            setState(() {
              _isLoading = false;
              if (success) {
                _requestStatus = 'Completed';
              }
            });

            Navigator.pop(bottomSheetContext, success);

            if (success) {
              final int finishId = _requestInformation?.task_taken_id ?? 0;
              final String? role = widget.role;

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FinishTask(
                    finishID: finishId,
                    role: role,
                  ),
                ),
              );

              if (!mounted) return;
              await _fetchRequestDetails();
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    SnackBar(content: Text('Failed to finish task')),
                  );
                }
              });
            }
          } catch (e, stackTrace) {
            debugPrint("Error finishing task: $e.");
            debugPrintStack(stackTrace: stackTrace);

            if (mounted) {
              setState(() {
                _isLoading = false;
              });

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    SnackBar(content: Text('Error occurred')),
                  );
                }
              });

              Navigator.pop(bottomSheetContext, false);
            }
          }
        },
      ),
    ).then((value) => value ?? false);
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
      builder: (childContext) => DisputeBottomSheet(
        taskInformation: _taskInformation!,
        requestInformation: _requestInformation!,
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
              fontWeight: FontWeight.w600),
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
                        fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_requestStatus == 'Review') _buildReviewSection(),
                        if (_requestStatus == "Disputed")
                          _buildDisputeSection(),
                        if (_requestStatus == 'Completed')
                          _buildCompletionSection(),
                        SizedBox(height: 16),
                        _buildTaskCard(),
                        SizedBox(height: 16),
                        _buildProfileCard(),
                        SizedBox(height: 24),
                        _showActionBottomSheet(),
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
            'Make Your Review',
            style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[800]),
          ),
          SizedBox(height: 8),
          Text(
            "Make sure to review the task before clicking the button below.",
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
                color: Colors.green[800]),
          ),
          SizedBox(height: 8),
          Text(
            'Congratulations on successfully completing this task!',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
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
                    _taskInformation!.title ?? 'Task',
                    style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF03045E)),
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
                      'Client Profile',
                      style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF03045E)),
                    ),
                    Text(
                      'Details',
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: Colors.grey[600]),
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

  Widget _showActionBottomSheet() {
    return Column(children: [
      if (_requestStatus != 'Disputed') ...[
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
        ),
      ],
      SizedBox(height: 16),
      if (_requestStatus != 'Disputed')
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

  Widget _buildFinishActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _requestStatus == 'Completed'
            ? Navigator.pop(context)
            : _showActionBottomSheet(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF03045E),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: Text(
          _requestStatus == 'Completed' ? 'Back to Task' : 'Finish Task',
          style: GoogleFonts.montserrat(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
              color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF03045E)),
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
              color: Colors.grey[600]),
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
                      color: Color(0xFF03045E)),
                ),
              ),
              if (isVerified)
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child:
                      Icon(Icons.verified, color: Colors.green[400], size: 18),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedbackBottomSheet extends StatefulWidget {
  final Function(int rating, String feedback, String? report,
      Function(bool) onComplete) onFeedbackSubmit;

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
                  color: Color(0xFF03045E)),
            ),
            SizedBox(height: 16),
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
            Text(
              'Feedback',
              style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF03045E)),
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
                    color: Colors.red[700]),
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
                    (bool success) {
                      if (success) {
                        Navigator.pop(context,
                            true); // Pop feedback bottom sheet with true
                      } else {
                        Navigator.pop(context,
                            false); // Pop feedback bottom sheet with false
                      }
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF03045E),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text(
                  'Submit Feedback & Release Payment',
                  style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
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
