import 'package:flutter/material.dart';
import 'package:flutter_fe/model/messeges_assignment.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/controller/task_controller.dart';

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
  double rating = 0.0;
  String feedback = "";
  final TaskController taskController = TaskController();

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

      final response = await _jobPostService.taskerTaskInformation(widget.finishID ?? 0);
      final response2 = await taskController.getClientFeedback(widget.finishID ?? 0);
      debugPrint("Fetched feedback details: $response2");

      if (response.isNotEmpty && response2.isNotEmpty) {
        setState(() {
          _requestInformation = response.first;
          rating = response2['client_feedback']['rating'].toDouble();
          feedback = response2['client_feedback']['feedback'] ?? "";
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
    } catch (e, stackTrace) {
      debugPrint("Error fetching request details: $e");
      debugPrintStack(stackTrace: stackTrace);
      setState(() {
        _errorMessage = 'Error fetching task details. Please Try Again.';
      });
    }
  }

  Future<void> _fetchTaskDetails() async {
    try {
      if (_requestInformation == null) {
        debugPrint("No request information or task ID available");
        return;
      }
      final response =
          await _jobPostService.fetchTaskInformation(_requestInformation!.id);
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
            _role == "Tasker" ? 'Congratulations on successfully completing this task!' : 'You tasker has completed the task. You can rate their work by tapping "Rate the Tasker" button. This can help them improve their services.',
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
                    _requestInformation!.taskDetails!.title,
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
              value: _requestInformation!.taskDetails!.address?.city ?? '',
            ),
            const SizedBox(height: 12),
            _buildTaskInfoRow(
              icon: Icons.calendar_today,
              label: 'Duration',
              value: _requestInformation!.taskDetails!.address?.province ?? '',
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
              value: '',
            ),
            const SizedBox(height: 12),
            Text(
              _requestInformation?.taskDetails?.description ?? '',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF03045E),
              ),
            ),
            const SizedBox(height: 12),
            _buildTaskInfoRow(
              icon: FontAwesomeIcons.pesoSign,
              label: '',
              value: '${_requestInformation!.taskDetails?.contactPrice}',
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
                        color: Color(0xFF03045E),
                      ),
                    ),
                    //Changed from user Status to Specialization for relevance.
                    Text(
                      tasker?.tasker?.specialization ?? 'N/A',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating
                              ? FontAwesomeIcons.solidStar
                              : FontAwesomeIcons.star,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
                "Your Feedback",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF03045E),
                )
            ),
            SizedBox(height: 8),
            Text(
                feedback,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],)
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Column(
      children: [
        if(feedback.isEmpty) ...[
          buildButton(() => _handleFinishTask(widget.finishID ?? 0, tasker?.tasker?.id ?? 0), "Rate the Tasker (Optional)", 0xFF03045E),
          const SizedBox(height: 16),
        ],
        buildButton(null, "Back to Tasks", 0xFFB71A4A),
      ]
    );
  }

  Future<void> _handleFinishTask(int taskTakenId, int taskerId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FeedbackBottomSheet(
        taskTakenID: taskTakenId,
        taskerId: taskerId,
      ),
    );
  }

  Widget buildButton(void Function()? onPressed, String text, int color){
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed ?? () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(color),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      )
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

  Widget _buildProfileInfoRow(String label, String value, {bool isVerified = false}) {
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

//This is in order for the bottomModalSheet to work for the end user.
class FeedbackBottomSheet extends StatefulWidget {
  final int taskTakenID;
  final int taskerId;
  const FeedbackBottomSheet({
    super.key,
    required this.taskTakenID,
    required this.taskerId,
  });

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet> {
  TaskAssignment? taskAssignment;
  int _rating = 0;
  bool willReport = false;
  AuthenticatedUser? tasker;
  final TaskController taskController = TaskController();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _reportController = TextEditingController();
  final JobPostService jobPostController = JobPostService();

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
            inputTextField(_feedbackController, "Share your experience..."),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_rating == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please provide a rating')),
                    );
                    return;
                  }
                  try {
                    bool result = await taskController.rateTheTasker(
                        widget.taskTakenID,
                        widget.taskerId,
                        _rating,
                        _feedbackController.text);
                    if (result) {
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Your feedback has need successfully posted.')),
                      );
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('An error occurred while rating the tasker.')),
                      );
                    }
                  } catch (e, stackTrace) {
                    debugPrint("Error finishing task: $e.");
                    debugPrintStack(stackTrace: stackTrace);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('An error occurred while rating the tasker.')),
                      );
                    }
                  } finally {
                    Navigator.pop(context);
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
                  'Submit Feedback',
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

  Widget inputTextField(TextEditingController controller, String hintText) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.montserrat(color: Colors.grey[700]),
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
    );
  }
}