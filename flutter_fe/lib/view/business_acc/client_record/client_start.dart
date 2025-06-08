import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/client_request.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/business_acc/client_record/client_ongoing.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

String cancellationReason = '';

class ClientStart extends StatefulWidget {
  final int? requestID;

  const ClientStart({super.key, this.requestID});

  @override
  State<ClientStart> createState() => _ClientStartState();
}

class _ClientStartState extends State<ClientStart> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController taskController = TaskController();
  final ProfileController _profileController = ProfileController();
  final storage = GetStorage();

  TaskModel? _taskInformation;
  ClientRequestModel? _requestInformation;
  AuthenticatedUser? _user;
  AuthenticatedUser? _tasker;
  String? _role;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      if (widget.requestID == null) throw Exception('Invalid request ID');
      await Future.wait([
        _fetchUserData(),
        _fetchRequestDetails(),
      ]);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final int userId = storage.read('user_id') ?? 0;
      if (userId == 0) throw Exception('User ID not found');
      final user =
          await _profileController.getAuthenticatedUser(context, userId);
      setState(() {
        _user = user;
        _role = user?.user.role;
      });
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<void> _fetchRequestDetails() async {
    try {
      final response =
          await _jobPostService.fetchRequestInformation(widget.requestID!);
      setState(() {
        _requestInformation = response;
      });
      await Future.wait([
        _fetchTaskDetails(),
        _fetchTaskerDetails(response.tasker_id as int),
      ]);
    } catch (e) {
      throw Exception('Failed to fetch request details: $e');
    }
  }

  Future<void> _fetchTaskDetails() async {
    try {
      if (_requestInformation?.task_id == null) {
        throw Exception('Invalid task ID');
      }
      final response = await _jobPostService
          .fetchTaskInformation(_requestInformation!.task_id as int);
      setState(() {
        _taskInformation = response.task;
        _isLoading = false;
      });
    } catch (e) {
      throw Exception('Failed to fetch task details: $e');
    }
  }

  Future<void> _fetchTaskerDetails(int taskerId) async {
    try {
      final user =
          await _profileController.getAuthenticatedUser(context, taskerId);
      setState(() {
        _tasker = user;
      });
    } catch (e) {
      throw Exception('Failed to fetch tasker details: $e');
    }
  }

  Future<void> _handleStartTask() async {
    if (_requestInformation == null || _role == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final result = await taskController.updateRequest(
        _requestInformation!.task_taken_id!,
        'Start',
        _role!,
      );
      if (result.containsKey('message') && result['message']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ClientOngoing(ongoingID: _requestInformation!.task_taken_id!),
          ),
        );
        await _fetchRequestDetails();
      } else {
        throw Exception('Failed to start task');
      }
    } catch (e, stacktrace) {
      debugPrint("Error starting task: $e");
      debugPrintStack(stackTrace: stacktrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting task. Please Try Again')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCancelTask() async {
    // final bool? confirm = await showDialog<bool>(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: Text(
    //       'Cancel Task',
    //       style: GoogleFonts.poppins(
    //         fontWeight: FontWeight.w600
    //       )
    //     ),
    //     content: SizedBox(
    //       width: double.maxFinite, // Use double.maxFinite for AlertDialog content
    //       height: MediaQuery.of(context).size.height * 0.3,
    //       child: StatefulBuilder( // Use StatefulBuilder for AlertDialog content that needs to update
    //         builder: (BuildContext context, StateSetter setStateDialog) {
    //           return Column(
    //             children: [
    //               Text(
    //                 'Why would you want to cancel this task?',
    //                 style: GoogleFonts.poppins(),
    //               ),
    //               const SizedBox(height: 16),
    //               Expanded(
    //                 child: ListView(
    //                   shrinkWrap: true,
    //                   children: [
    //                     DropdownButtonFormField<String>(
    //                       decoration: InputDecoration(
    //                         labelText: 'Reason for Cancellation',
    //                         border: OutlineInputBorder(
    //                           borderRadius: BorderRadius.circular(8),
    //                         ),
    //                       ),
    //                       value: _selectedCancellationReason,
    //                       hint: const Text('Select a reason'),
    //                       items: _cancellationReasons.map((String reason) {
    //                         return DropdownMenuItem<String>(
    //                           value: reason,
    //                           child: Text(reason),
    //                         );
    //                       }).toList(),
    //                       onChanged: (String? newValue) {
    //                         // Use setStateDialog to update AlertDialog's content
    //                         setStateDialog(() => _selectedCancellationReason = newValue);
    //                         // Also update the main widget's state if needed
    //                         setState(() => _selectedCancellationReason = newValue);
    //                       },
    //                     ),
    //                   ],
    //                 ),
    //               )
    //             ],
    //           );
    //         },
    //       )
    //     ),
    //     actions: [
    //       TextButton(
    //         onPressed: () => Navigator.pop(context, false),
    //         child:
    //             Text('No', style: GoogleFonts.montserrat(color: Colors.grey)),
    //       ),
    //       TextButton(
    //         onPressed: () => Navigator.pop(context, true),
    //         child:
    //             Text('Yes', style: GoogleFonts.montserrat(color: Colors.red)),
    //       ),
    //     ],
    //   ),
    // );

    cancellationReason = await showModalBottomSheet(
        context: context, builder: (context) => CancellationBottomSheet());
    debugPrint('Selected cancellation reason: $cancellationReason');

    if (_requestInformation != null &&
        _role != null &&
        cancellationReason != '') {
      setState(() {
        _isLoading = true;
      });
      try {
        final result = await taskController.updateRequest(
          _requestInformation!.task_taken_id!,
          'Cancel',
          _role!,
          rejectionReason: cancellationReason,
        );
        if (result.containsKey('message')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'You had cancelled your task. The tasker will be informed.')),
          );
          await _fetchRequestDetails();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'])),
          );
        }
      } catch (e, stackTrace) {
        debugPrint("Error cancelling task: $e");
        debugPrintStack(stackTrace: stackTrace);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling task. Please try again.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Something went wrong while cancelling your task. Please Try again.')),
      );
    }
  }

  Future<void> _handleRescheduleTask() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF03045E),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null && _requestInformation != null && _role != null) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Reschedule',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
          content: Text(
            'Request to reschedule task for ${DateFormat('MMM dd, yyyy').format(selectedDate)}?',
            style: GoogleFonts.montserrat(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: GoogleFonts.montserrat(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Confirm',
                  style:
                      GoogleFonts.montserrat(color: const Color(0xFF03045E))),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() {
          _isLoading = true;
        });
        try {
          // TODO: Implement actual reschedule API call
          // Example: await taskController.rescheduleTask(_requestInformation!.task_taken_id, selectedDate);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Reschedule requested for ${DateFormat('MMM dd, yyyy').format(selectedDate)}')),
          );
          await _fetchRequestDetails();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error requesting reschedule: $e')),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleFinishTask() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Finish Task',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to mark this task as finished?',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('No', style: GoogleFonts.montserrat(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes',
                style: GoogleFonts.montserrat(color: const Color(0xFF03045E))),
          ),
        ],
      ),
    );

    if (confirm == true && _requestInformation != null && _role != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        final result = await taskController.updateRequest(
          _requestInformation!.task_taken_id!,
          'Finish',
          _role!,
        );
        if (result.containsKey('message')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task marked as finished')),
          );
          await _fetchRequestDetails();
        } else {
          throw Exception('Failed to finish task');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finishing task: $e')),
        );
      } finally {
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF03045E)),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Text(
          'Task Information',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF03045E),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              onRefresh: _fetchData,
              child: _buildBody(constraints),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BoxConstraints constraints) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF03045E)));
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_errorMessage',
              style: GoogleFonts.montserrat(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF03045E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Retry',
                  style: GoogleFonts.montserrat(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_taskInformation == null || _requestInformation == null) {
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
          _buildStatusSection(),
          const SizedBox(height: 16),
          _buildTaskCard(constraints),
          const SizedBox(height: 16),
          _buildTaskerCard(constraints),
          const SizedBox(height: 24),
          if (_requestInformation!.task_status == 'Confirmed')
            _buildConfirmedActionButtons()
          else if (_requestInformation!.task_status == 'Ongoing' ||
              _requestInformation!.task_status == 'Cancelled' ||
              _requestInformation!.task_status == 'Finished')
            _buildOngoingActionButtons()
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    final status = _requestInformation!.task_status ?? 'Unknown';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor(status).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            statusIcon(status),
            color: statusColor(status),
            size: 40,
            semanticLabel: 'Task Status',
          ),
          const SizedBox(height: 12),
          Text(
            status,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: statusColor(status),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusMessage(status),
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

  Widget _buildTaskCard(BoxConstraints constraints) {
    return Card(
      elevation: 4,
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
                    _taskInformation!.title ?? 'Task',
                    style: GoogleFonts.montserrat(
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
              icon: FontAwesomeIcons.briefcase,
              label: 'Work Type',
              value: _taskInformation!.workType ?? 'N/A',
            ),
            _buildTaskInfoRow(
              icon: FontAwesomeIcons.star,
              label: 'Specialization',
              value: _taskInformation!.tasker?.specialization.specialization ?? 'N/A',
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
          ],
        ),
      ),
    );
  }

  Widget _buildTaskerCard(BoxConstraints constraints) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF5F9FF),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _tasker?.user.image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CachedNetworkImage(
                          imageUrl: _tasker!.user.image!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person, size: 48),
                        ),
                      )
                    : const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFF03045E),
                        child:
                            Icon(Icons.person, color: Colors.white, size: 28),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasker Profile',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF03045E),
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProfileInfoRow(
              label: 'Name',
              value: _tasker != null
                  ? '${_tasker!.user.firstName} ${_tasker!.user.lastName}'
                      .trim()
                  : 'Not available',
            ),
            _buildProfileInfoRow(
              label: 'Email',
              value: _tasker?.user.email ?? 'Not available',
            ),
            _buildProfileInfoRow(
              label: 'Phone',
              value: _tasker?.user.contact ?? 'Not available',
            ),
            _buildProfileInfoRow(
              label: 'Status',
              value: _tasker?.user.accStatus ?? 'Not available',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmedActionButtons() {
    return Column(
      children: [
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleStartTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF03045E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text(
                  'Start Task',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _handleCancelTask,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Cancel Task',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Expanded(
            //   child: ElevatedButton(
            //     onPressed: _handleRescheduleTask,
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.yellow[700],
            //       padding: const EdgeInsets.symmetric(vertical: 16),
            //       shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12)),
            //       elevation: 2,
            //     ),
            //     child: Text(
            //       'Reschedule',
            //       style: GoogleFonts.montserrat(
            //         fontSize: 14,
            //         fontWeight: FontWeight.w600,
            //         color: Colors.black,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
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

  Widget _buildOngoingActionButtons() {
    final status = _requestInformation!.task_status;
    String label;
    VoidCallback? onPressed;
    Color backgroundColor;

    if (status == 'Ongoing') {
      label = 'Back to Task';
      onPressed = () => Navigator.pop(context);
      backgroundColor = const Color(0xFF03045E);
    } else if (status == 'Cancelled' || status == 'Finished') {
      label = 'Back to Tasks';
      onPressed = () => Navigator.pop(context);
      backgroundColor = const Color(0xFF03045E);
    } else {
      return const SizedBox.shrink(); // Hide button for unknown statuses
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: ValueKey('${label.toLowerCase().replaceAll(' ', '_')}_button'),
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          FaIcon(icon, size: 18, color: const Color(0xFF03045E)),
          const SizedBox(width: 12),
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
                color: const Color(0xFF03045E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow({
    required String label,
    required String value,
    bool isVerified = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
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
                      color: const Color(0xFF03045E),
                    ),
                  ),
                ),
                if (isVerified)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.verified,
                      color: Colors.green,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF2E763E);
      case 'ongoing':
        return const Color(0xFF0288D1);
      case 'cancelled':
        return const Color(0xFFD43D4D);
      case 'finished':
        return const Color(0xFF7B1FA2);
      default:
        return Colors.grey;
    }
  }

  IconData statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'ongoing':
        return Icons.hourglass_empty;
      case 'cancelled':
        return Icons.cancel;
      case 'finished':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  String statusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'The task is confirmed and ready to start.';
      case 'ongoing':
        return 'The task is in progress.';
      case 'cancelled':
        return 'The task has been cancelled.';
      case 'finished':
        return 'The task has been completed.';
      default:
        return 'Task status is unknown.';
    }
  }
}

class CancellationBottomSheet extends StatefulWidget {
  const CancellationBottomSheet({super.key});

  @override
  State<CancellationBottomSheet> createState() =>
      _CancellationBottomSheetState();
}

class _CancellationBottomSheetState extends State<CancellationBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedReason;
  bool isConfirmed = false;
  final TaskController taskController = TaskController();

  final List<String> _cancellationReasons = [
    'I had conflicts with my other schedule.',
    'We cannot find a middle ground on this task.',
    'Tasker cannot be reached.',
    'There\'s a problem with the task itself.',
    'Others'
  ];

  @override
  Widget build(BuildContext bottomSheetContext) {
    return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Form(
            key: _formKey,
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    "Cancel Task",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE23670),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "You are going to cancel your task. The amount that will be refunded will be deducted to your account upon cancellation.",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF4A4A68),
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Reason for Cancellation',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFF0272B1), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide:
                            BorderSide(color: Colors.red[400]!, width: 1),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide:
                            BorderSide(color: Colors.red[600]!, width: 2),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide:
                            BorderSide(color: Colors.grey[400]!, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    value: _selectedReason,
                    hint: const Text('Select a reason'),
                    items: _cancellationReasons.map((String reason) {
                      return DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedReason = newValue;
                      });
                    },
                    validator: (value) => value == null &&
                            _selectedReason == "Others"
                        ? 'Please input your other reason why you cancelled your task..'
                        : null,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: taskController.rejectionOthersController,
                    enabled: _selectedReason == "Others",
                    decoration: InputDecoration(
                      labelText: 'Others (please specify)',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFF0272B1), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.red[400]!, width: 1),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.red[600]!, width: 2),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.grey[400]!, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: isConfirmed,
                        checkColor: Colors.white,
                        activeColor: Color(0XFFE23670),
                        onChanged: (bool? value) {
                          // Handle checkbox state change
                          setState(() {
                            isConfirmed = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          "I understand that 30% will be deducted from the task payment upon cancellation.",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF4A4A68),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isConfirmed
                        ? () {
                            debugPrint("Selected reason: $_selectedReason");
                            if (_selectedReason == "Others") {
                              _selectedReason =
                                  taskController.rejectionOthersController.text;
                            }
                            Navigator.pop(context, _selectedReason);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text('Confirm Cancellation',
                        style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ]))));
  }
}
