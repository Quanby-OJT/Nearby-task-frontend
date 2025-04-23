import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
  }

  Future<void> _fetchTaskDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response =
          await _jobPostService.fetchTaskInformation(widget.taskID ?? 0);
      if (response == null) {
        throw Exception('No task information available');
      }
      setState(() {
        _taskInformation = response.task;
        _isLoading = false;
        _fetchClientDetails(_taskInformation!.clientId);
      });
      await _fetchIfTaskIsAssigned();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _fetchClientDetails(userId) async {
    try {
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      debugPrint(user.toString());
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
    if (_taskInformation == null) return;

    try {
      final response = await taskController.fetchIsApplied(
        widget.taskID ?? 0,
        _taskInformation!.clientId,
        storage.read('user_id') ?? 0,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Information',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF03045E),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
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
          _buildTaskCard(constraints),
          const SizedBox(height: 16),
          _buildClientCard(constraints),
          const SizedBox(height: 16),
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BoxConstraints constraints) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _taskInformation!.title ?? 'Untitled Task',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF03045E),
              ),
            ),
            const SizedBox(height: 8),
            if (_taskInformation!.status != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor(_taskInformation!.status!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _taskInformation!.status!,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: FontAwesomeIcons.briefcase,
              label: 'Required Tasker',
              value: _taskInformation!.workType ?? 'N/A',
            ),
            _buildInfoRow(
              icon: FontAwesomeIcons.screwdriverWrench,
              label: 'Specialization',
              value: _taskInformation!.specialization ?? 'N/A',
            ),
            _buildInfoRow(
              icon: FontAwesomeIcons.locationPin,
              label: 'Location',
              value: _taskInformation!.location ?? 'Not specified',
            ),
            _buildInfoRow(
              icon: FontAwesomeIcons.pesoSign,
              label: 'Contract Price',
              value: _taskInformation!.contactPrice?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              icon: FontAwesomeIcons.fileAlt,
              label: 'Description',
              value:
                  _taskInformation!.description ?? 'No description available',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(BoxConstraints constraints) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFF5F9FF),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client Information',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF03045E),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: FontAwesomeIcons.user,
              label: 'Name',
              value: (_client?.user?.firstName ?? '') +
                      ' ' +
                      (_client?.user?.middleName ?? '') +
                      ' ' +
                      (_client?.user?.lastName ?? '') ??
                  'N/A',
            ),
            _buildInfoRow(
              icon: FontAwesomeIcons.checkCircle,
              label: 'Account Status',
              value: _client?.user?.accStatus ?? 'Verified',
            ),
            _buildInfoRow(
              icon: FontAwesomeIcons.envelope,
              label: 'Email',
              value: _client?.user?.email ?? 'N/A',
            ),
            _buildInfoRow(
              icon: FontAwesomeIcons.phone,
              label: 'Phone',
              value: _client?.user?.contact ?? 'N/A',
            ),
            _buildInfoRow(
              icon: FontAwesomeIcons.solidStar,
              label: 'Rating',
              value: _client?.client?.rating.toString() ?? 'N/A',
            ),
          ],
        ),
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
          FaIcon(icon, size: 18, color: const Color(0xFF03045E)),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isApplying || _taskInformation == null
            ? null
            : () async {
                setState(() {
                  _isLoading = true;
                });
                try {
                  final result = await taskController.assignTask(
                    widget.taskID ?? 0,
                    _taskInformation!.clientId,
                    storage.read('user_id') ?? 0,
                    widget.role,
                  );
                  if (result == 'A New Conversation Has been Opened.') {
                    setState(() {
                      _isApplying = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Successfully applied for task')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error applying for task: $e')),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: _isApplying ? Colors.grey : const Color(0xFF03045E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isApplying ? 'Applied' : 'Apply Now',
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
