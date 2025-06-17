import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/task_request_controller.dart';
import 'package:flutter_fe/model/disputes.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:flutter_fe/view/task_user/user_feedback.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/client_request.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class TaskFinished extends StatefulWidget {
  final TaskFetch? taskInformation;

  const TaskFinished({super.key, this.taskInformation});

  @override
  State<TaskFinished> createState() => _TaskFinishedState();
}

class _TaskFinishedState extends State<TaskFinished> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController taskController = TaskController();
  final ProfileController _profileController = ProfileController();
  final TaskRequestController taskRequestController = TaskRequestController();
  TaskModel? _taskInformation;
  Disputes? disputes;
  ClientRequestModel? _requestInformation;
  bool _isLoading = true;
  final storage = GetStorage();
  AuthenticatedUser? tasker;
  String _role = 'Unknown';

  @override
  void initState() {
    super.initState();
    _loadMethod();
    _role = GetStorage().read("role") ?? 'Unknown';
  }

  Future<void> _loadMethod() async {
    setState(() {
      _isLoading = true;
    });
    await Future(() async {
      await _fetchRequestDetails();
      await _fetchTaskDispute();
      // await _updateNotif();
    });
    setState(() {
      _isLoading = false;
    });
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
    }
  }

  Future<void> _fetchRequestDetails() async {
    try {
      final response = await _jobPostService
          .fetchRequestInformation(widget.taskInformation?.taskTakenId ?? 0);
      setState(() {
        _requestInformation = response;
      });
      if (widget.taskInformation?.taskDetails!.client?.user?.role == "Tasker") {
        await _fetchTaskerDetails(_requestInformation!.tasker_id as int);
      } else {
        await _fetchTaskerDetails(_requestInformation!.client_id as int);
      }
    } catch (e) {
      debugPrint("Error fetching task details: $e");
    }
  }

  Future<void> _fetchTaskDispute() async {
    try {
      final disputeData = await taskRequestController
          .getDispute(widget.taskInformation?.taskTakenId ?? 0);
      final taskInformation = widget.taskInformation?.post_task;
      setState(() {
        disputes = disputeData;
        _taskInformation = taskInformation;
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
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusSection(),
                            const SizedBox(height: 16),
                            _buildTaskCard(constraints),
                            const SizedBox(height: 16),
                            if (disputes != null) ...[
                              completedWithDispute(),
                              const SizedBox(height: 16)
                            ],
                            if (_role == "Tasker") _buildClientProfileCard(),
                            if (_role == "Client") _buildTaskerProfileCard(),
                            const SizedBox(height: 16),
                            _buildActionButton(
                              'Back to Tasks',
                              Color(0XFFE23670),
                              () {
                                Navigator.pop(context);
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildActionButton(
                                "Rate Tasker (Optional)",
                                Color(0XFF4DBF66),
                                () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => UserFeedback()));
                                }
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildTaskCard(BoxConstraints constraints) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.surfaceContainer,
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
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.task,
                      color: Theme.of(context).colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _taskInformation!.title ?? 'Task',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTaskInfoRow(
              icon: FontAwesomeIcons.locationDot,
              label: 'Description',
              value: _taskInformation!.description ?? 'N/A',
            ),
            const SizedBox(height: 16),
            _buildTaskInfoRow(
              icon: FontAwesomeIcons.briefcase,
              label: 'Work Type',
              value: _taskInformation!.workType ?? 'N/A',
            ),
            _buildTaskInfoRow(
              icon: FontAwesomeIcons.star,
              label: 'Specialization',
              value: _taskInformation!.taskerSpecialization?.specialization ??
                  'N/A',
            ),
            _buildTaskInfoRow(
              icon: FontAwesomeIcons.dollarSign,
              label: 'Contract Price',
              value: _taskInformation!.contactPrice.toString() ?? 'N/A',
            ),
            _buildTaskInfoRow(
              icon: FontAwesomeIcons.info,
              label: 'Status',
              value: _requestInformation!.task_status ?? 'Confirmed',
            ),
            _buildTaskInfoRow(
              icon: FontAwesomeIcons.calendar,
              label: 'Start Date',
              value: _requestInformation?.task?.taskBeginDate != null
                  ? DateFormat('MMM dd, yyyy HH:mm a').format(DateTime.parse(
                      _requestInformation?.task?.taskBeginDate ?? ''))
                  : 'N/A',
            ),
            _buildTaskInfoRow(
              icon: Icons.calendar_today,
              label: 'Finish Date',
              value: _requestInformation!.end_date != null
                  ? DateFormat('MMM dd, yyyy HH:mm a')
                      .format(_requestInformation!.end_date!.toLocal())
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskInfoRow(
      {required IconData? icon, required String label, required String value}) {
    return Row(
      children: [
        if (icon != null) ...[
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

  Widget buildTextSection(String info) {
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

  Widget completedWithDispute() {
    return SizedBox(
      width: double.infinity, // Occupy entire screen width
      child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align text to start
                children: [
                  Text(
                    "This is a Disputed Task",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0XFFD43D4D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildProfileInfoRow(
                      "Raised By",
                      disputes?.raisedBy != null
                          ? "${disputes?.raisedBy?.firstName} ${disputes?.raisedBy?.middleName} ${disputes?.raisedBy?.lastName} (${disputes?.raisedBy?.role})"
                          : "N/A"),
                  buildDisputeInfo(
                      "Dispute Reason", disputes?.disputeReason ?? "N/A"),
                  buildDisputeInfo(
                      "Dispute Details", disputes?.disputeDetails ?? "N/A"),
                  buildDisputeInfo(
                      "Resolution", disputes?.moderatorAction ?? "N/A"),
                  buildDisputeInfo(
                      "Resolution Details", disputes?.moderatorNotes ?? "N/A"),
                ],
              ))),
    );
  }

  Widget buildDisputeInfo(String title, String description) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 10),
      Text(title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          )),
      const SizedBox(height: 4),
      Text(
        description,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF170A66),
        ),
        textAlign: TextAlign.justify,
      )
    ]);
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
                      widget.taskInformation?.taskDetails?.client?.user?.role ==
                              "Tasker"
                          ? "Tasker Profile"
                          : "Client Profile",
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
              (widget.taskInformation?.taskDetails?.client?.user != null)
                  ? '${widget.taskInformation!.taskDetails!.client!.user!.firstName ?? ''} ${widget.taskInformation!.taskDetails!.client!.user!.lastName ?? ''}'
                      .trim()
                  : 'Not available',
            ),
            SizedBox(height: 8),
            _buildProfileInfoRow(
                'Status',
                widget.taskInformation?.taskDetails?.client?.user?.accStatus ??
                    'Not available'),
            SizedBox(height: 8),
            _buildProfileInfoRow('Account', 'Verified', isVerified: true),
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
                      widget.taskInformation?.taskDetails?.client?.user?.role ==
                              "Client"
                          ? "Client Profile"
                          : "Tasker Profile",
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

  Widget _buildStatusSection() {
    final status = _requestInformation?.task_status ?? 'Unknown';
    final isConfirmed = status.toLowerCase() == 'confirmed';

    if (_requestInformation?.end_date == null) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Icon(
              statusIcon(status),
              color: statusColor(status),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: statusColor(status),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusMessage(status),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Date Not Set',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[100]!.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[100]!.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon(status),
              color: statusColor(status),
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: statusColor(status),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusMessage(status),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, Function() function) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: function,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
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
                    color: Colors.black,
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

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return Colors.green;
    case 'confirmed':
      return Colors.blue;
    default:
      return Colors.grey;
  }
}

IconData statusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return Icons.check_circle;
    case 'confirmed':
      return Icons.check;
    default:
      return Icons.info;
  }
}

String statusMessage(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return 'The task is completed.';
    case 'confirmed':
      return 'The task has been confirmed.';
    default:
      return 'Task status is unknown.';
  }
}
