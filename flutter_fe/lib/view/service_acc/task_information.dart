import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/generate_pdf_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/client_request.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/custom_loading/file_indicators.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';

// StatusConfig class for dynamic status properties
class StatusConfig {
  final IconData icon;
  final String title;
  final String description;
  final Color backgroundColor;
  final Color iconColor;
  final Color titleColor;
  final Color descriptionColor;

  StatusConfig({
    required this.icon,
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.iconColor,
    required this.titleColor,
    required this.descriptionColor,
  });
}

// Map of status configurations
final Map<String, StatusConfig> statusConfigs = {
  'Pending': StatusConfig(
    icon: Icons.hourglass_empty,
    title: 'Pending Confirmation',
    description: 'The task is awaiting confirmation from the client.',
    backgroundColor: Colors.blue[50]!,
    iconColor: Colors.blue[600]!,
    titleColor: Colors.blue[800]!,
    descriptionColor: Colors.grey[600]!,
  ),
  'Rejected': StatusConfig(
    icon: Icons.cancel,
    title: 'Task Rejected',
    description: 'The task was rejected by the client or tasker.',
    backgroundColor: Colors.red[50]!,
    iconColor: Colors.red[600]!,
    titleColor: Colors.red[800]!,
    descriptionColor: Colors.grey[600]!,
  ),
  'Confirmed': StatusConfig(
    icon: Icons.check_circle,
    title: 'Task Confirmed',
    description: 'The task has been confirmed and is ready to start.',
    backgroundColor: Colors.green[50]!,
    iconColor: Colors.green[600]!,
    titleColor: Colors.green[800]!,
    descriptionColor: Colors.grey[600]!,
  ),
  'Ongoing': StatusConfig(
    icon: Icons.work,
    title: 'Task Ongoing',
    description: 'The task is currently in progress.',
    backgroundColor: Colors.orange[50]!,
    iconColor: Colors.orange[600]!,
    titleColor: Colors.orange[800]!,
    descriptionColor: Colors.grey[600]!,
  ),
  'Completed': StatusConfig(
    icon: Icons.done_all,
    title: 'Task Completed',
    description: 'The task has been successfully completed.',
    backgroundColor: Colors.teal[50]!,
    iconColor: Colors.teal[600]!,
    titleColor: Colors.teal[800]!,
    descriptionColor: Colors.grey[600]!,
  ),
  'Cancelled': StatusConfig(
    icon: Icons.block,
    title: 'Task Cancelled',
    description: 'The task was cancelled by the client or tasker.',
    backgroundColor: Colors.grey[50]!,
    iconColor: Colors.grey[600]!,
    titleColor: Colors.grey[800]!,
    descriptionColor: Colors.grey[600]!,
  ),
  'Disputed': StatusConfig(
    icon: Icons.warning,
    title: 'Task Disputed',
    description: 'The task is under dispute and requires resolution.',
    backgroundColor: Colors.purple[50]!,
    iconColor: Colors.purple[600]!,
    titleColor: Colors.purple[800]!,
    descriptionColor: Colors.grey[600]!,
  ),
};

class TaskInformation extends StatefulWidget {
  final int? taskID;
  final String role;

  const TaskInformation({super.key, this.taskID, required this.role});

  @override
  State<TaskInformation> createState() => _TaskInformationState();
}

class _TaskInformationState extends State<TaskInformation> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController taskController = TaskController();
  final ProfileController _profileController = ProfileController();
  AuthenticatedUser? _client;
  TaskModel? _taskInformation;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final storage = GetStorage();
  bool _isApplying = false;
  bool _isTaskTaken = false;
  ClientRequestModel? _requestInformation;
  ClientRequestModel? _requestTaskStatus;
  String _requestStatus = 'Unknown';
  bool _isTaskCardExpanded = false;
  bool _isClientCardExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
    _fetchRequestDetails();
  }

  Future<void> _fetchTaskDetails() async {
    if (widget.taskID == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Invalid task ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response =
          await _jobPostService.fetchTaskInformation(widget.taskID!);
      if (response.task == null) {
        throw Exception('No task information available');
      }

      debugPrint("Task information: ${response.task?.clientId}");

      debugPrint("Task ID: ${widget.taskID}");
      setState(() {
        _taskInformation = response.task;
        _isTaskTaken = response.task!.status == 'Already Taken';
        _isLoading = false;
      });
      await _fetchClientDetails(response.task?.clientId);
      await _fetchIfTaskIsAssigned();
      await _fetchIfTaskIsAssignedID();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _fetchIfTaskIsAssignedID() async {
    if (_taskInformation == null || widget.taskID == null) return;

    final userId = storage.read('user_id');
    if (userId == null) {
      setState(() {
        _isApplying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error in _fetchIfTaskIsAssignedID: User ID not found",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      final response = await taskController.fetchIsAppliedID(
        widget.taskID!,
        _taskInformation!.clientId,
        userId,
      );

      debugPrint("Is applying response ID: $response");
      await _fetchTaskStatus(response);
    } catch (e) {
      setState(() {
        _isApplying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error in _fetchTaskDetails: $e",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _fetchTaskStatus(String response) async {
    try {
      final responseResponse =
          await _jobPostService.fetchRequestInformation(int.parse(response));
      setState(() {
        _requestTaskStatus = responseResponse;
        _requestStatus = _requestTaskStatus?.task_status ?? 'Unknown';
      });

      debugPrint("Fetched request status: $_requestStatus");
    } catch (e) {
      debugPrint("Error fetching request details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchClientDetails(userId) async {
    try {
      debugPrint("User ID of the client: $userId");

      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUserclient(context, userId);
      debugPrint('This is client date $user');
      setState(() {
        _client = user;
      });
    } catch (e) {
      debugPrint("Error fetching client details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchIfTaskIsAssigned() async {
    if (_taskInformation == null || widget.taskID == null) return;

    final userId = storage.read('user_id');
    if (userId == null) {
      setState(() {
        _isApplying = false;
      });
      return;
    }

    try {
      final response = await taskController.fetchIsApplied(
        widget.taskID!,
        _taskInformation!.clientId,
        userId,
      );

      setState(() {
        _isApplying = response == 'True';
      });
    } catch (e) {
      setState(() {
        _isApplying = false;
      });
    }
  }

  Future<void> _fetchRequestDetails() async {
    if (widget.taskID == null) return;

    try {
      final response =
          await _jobPostService.fetchRequestInformation(widget.taskID!);
      setState(() {
        _requestInformation = response;
      });
      debugPrint(
          "Fetched request details: ${_requestInformation?.requested_from ?? 'Unknown'}");
      debugPrint(
          "Fetched request status: ${_requestInformation?.task_status ?? 'Unknown'}");
    } catch (e) {
      debugPrint("Error fetching request details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              onRefresh: _fetchTaskDetails,
              child: _buildBody(constraints),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BoxConstraints constraints) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_errorMessage',
              style: GoogleFonts.montserrat(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTaskDetails,
              child: Text('Retry', style: GoogleFonts.montserrat()),
            ),
          ],
        ),
      );
    }

    if (_taskInformation == null) {
      return Center(
        child: Text(
          'No task information available',
          style: GoogleFonts.montserrat(fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_requestStatus != 'Unknown' &&
              statusConfigs.containsKey(_requestStatus))
            _buildStatusSection(),
          const SizedBox(height: 16),
          _buildTaskCard(constraints),
          const SizedBox(height: 16),
          _buildClientCard(constraints),
          const SizedBox(height: 16),
          _buildApplyButton(),
        ],
      ),
    );
  }

  //For PCIC Only
  void downloadFile(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (BuildContext childContext) {
        return PopScope(
          child: AlertDialog(
            content: DownloadFileIndicator(),
            contentPadding: const EdgeInsets.all(24),
          )
        );
      }
    );
  }

  Widget _buildStatusSection() {
    final config = statusConfigs[_requestStatus] ??
        StatusConfig(
          icon: Icons.help_outline,
          title: 'Unknown Status',
          description: 'The task status is not recognized.',
          backgroundColor: Colors.grey[50]!,
          iconColor: Colors.grey[600]!,
          titleColor: Colors.grey[800]!,
          descriptionColor: Colors.grey[600]!,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.backgroundColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(
            config.icon,
            color: config.iconColor,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            config.title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: config.titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            config.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: config.descriptionColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BoxConstraints constraints) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isTaskCardExpanded = !_isTaskCardExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _taskInformation!.title ?? 'Untitled Task',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB71A4A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor(_taskInformation!.status ?? ""),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _taskInformation!.status ?? "",
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isTaskCardExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFFB71A4A),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Container(height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: FontAwesomeIcons.briefcase,
                    label: 'Required Tasker',
                    value: _taskInformation?.workType ?? 'N/A',
                  ),
                  _buildInfoRow(
                    icon: FontAwesomeIcons.screwdriverWrench,
                    label: 'Specialization',
                    value: _taskInformation!
                            .taskerSpecialization?.specialization ??
                        'N/A',
                  ),
                  _buildInfoRow(
                    icon: FontAwesomeIcons.pesoSign,
                    label: 'Contract Price',
                    value: _taskInformation?.contactPrice.toString() ?? 'N/A',
                  ),
                  _buildInfoRow(
                    icon: FontAwesomeIcons.fileAlt,
                    label: 'Description',
                    value: _taskInformation?.description ??
                        'No description available',
                  ),
                ],
              ),
            ),
            crossFadeState: _isTaskCardExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(BoxConstraints constraints) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFF5F9FF),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isClientCardExpanded = !_isClientCardExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Client Information',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB71A4A),
                    ),
                  ),
                  Icon(
                    _isClientCardExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFFB71A4A),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Container(height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: FontAwesomeIcons.user,
                    label: 'Name',
                    value:
                        '${_client?.user.firstName} ${_client?.user.middleName} ${_client?.user.lastName}',
                  ),
                  _buildInfoRow(

                    icon: FontAwesomeIcons.checkCircle,
                    label: 'Verification',
                    value: _client?.user.verified == true
                        ? 'Verified'
                        : 'Unverified',

                    icon: FontAwesomeIcons.solidCircleCheck,
                    label: 'Account Status',
                    value: _client?.user.accStatus ?? 'Verified',
                  ),
                  _buildInfoRow(
                    icon: FontAwesomeIcons.info,
                    label: 'About the Client',
                    value: _client?.client?.bio ?? 'N/A',

                  ),
               
                ],
              ),
            ),
            crossFadeState: _isClientCardExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 18, color: const Color(0xFFB71A4A)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    final buttonText = _isApplying
        ? _isTaskTaken
            ? 'Back to Task'
            : _requestStatus == 'Pending'
                ? 'Back to Task'
                : _requestStatus == 'Unknown'
                    ? 'Apply Now'
                    : _requestStatus != 'Pending'
                        ? 'Back to Task'
                        : 'Applied'
        : _isTaskTaken
            ? 'Back to Task'
            : 'Apply Now';

    final isBackToTask = buttonText == 'Back to Task';
    final isDisabled = _isApplying && !isBackToTask || _taskInformation == null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled
            ? null
            : isBackToTask
                ? () {
                    Navigator.pop(context);
                  }
                : () async {
                    setState(() {
                      _isLoading = true;
                    });
                    try {
                      downloadFile(context);
                      final pdf = await generatePdf();
                      await Printing.layoutPdf(onLayout: (_) => pdf);
                      final result = await taskController.assignTask(
                        widget.taskID ?? 0,
                        _taskInformation!.clientId,
                        storage.read('user_id') ?? 0,
                        widget.role,
                      );
                      if (result == 'A New Conversation Has been Opened.') {
                        setState(() {
                          _isApplying = true;
                          _requestStatus = 'Pending';
                        });
                        await _fetchTaskDetails();
                        if(mounted) Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "You have downloaded the task information from our server. Please read it very carefully.",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e, stackTrace) {
                      debugPrint("Error in _fetchTaskDetails: $e");
                      debugPrintStack(stackTrace: stackTrace);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "An error occurred while processing your application. Please Try Again.",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          margin: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: isDisabled ? Colors.grey : const Color(0xFFB71A4A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          buttonText,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color statusColor(String taskStatus) {
    switch (taskStatus.toLowerCase()) {
      case 'available':
        return const Color(0xFF2E763E);
      case 'already taken':
        return const Color(0xFFD6932A);
      case 'closed':
        return const Color(0xFFD43D4D);
      case 'on hold':
        return const Color(0xFF2C648C);
      case 'reported':
        return const Color(0xFF7A2532);
      default:
        return Colors.grey;
    }
  }
}
