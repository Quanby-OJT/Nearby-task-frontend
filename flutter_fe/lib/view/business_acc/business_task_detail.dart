import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BusinessTaskDetail extends StatefulWidget {
  final int taskID;
  final TaskModel? task; // Optional task model if already loaded

  const BusinessTaskDetail({
    Key? key,
    required this.taskID,
    this.task,
  }) : super(key: key);

  @override
  State<BusinessTaskDetail> createState() => _BusinessTaskDetailState();
}

class _BusinessTaskDetailState extends State<BusinessTaskDetail> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController _taskController = TaskController();
  TaskModel? _taskInformation;
  bool _isLoading = true;
  bool _isDeleting = false;
  final storage = GetStorage();

  @override
  void initState() {
    super.initState();

    // If task was passed, use it immediately
    if (widget.task != null) {
      _taskInformation = widget.task;
      _isLoading = false;
    } else {
      _fetchTaskDetails();
    }
  }

  Future<void> _fetchTaskDetails() async {
    try {
      final response =
          await _jobPostService.fetchTaskInformation(widget.taskID);
      setState(() {
        _taskInformation = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching task details: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load task details: ${e.toString()}')),
      );
    }
  }

  Future<void> _disableTask() async {
    // Show confirmation dialog
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Disable Task'),
            content: Text('Are you sure you want to disable this task?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Disable', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final result = await _taskController.disableTask(widget.taskID);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task disabled successfully')),
        );
        Navigator.pop(
            context, true); // Return true to indicate task was disabled
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to disable task: ${result['error'] ?? "Unknown error"}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  String _formatPrice(int? price) {
    if (price == null) return "N/A";
    try {
      return "₱ ${NumberFormat("#,##0.00", "en_US").format(price)}";
    } catch (e) {
      return "₱ $price";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Details',
          style:
              TextStyle(color: Color(0xFF0272B1), fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Color(0xFF0272B1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _taskInformation == null
              ? const Center(child: Text('No task information available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              _taskInformation!.title ?? "Untitled Task",
                              style: GoogleFonts.montserrat(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0272B1),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Divider(height: 30),
                          _buildInfoRow(
                              "Location", _taskInformation!.location ?? "N/A"),
                          _buildInfoRow("Specialization",
                              _taskInformation!.specialization ?? "N/A"),
                          _buildInfoRow("Description",
                              _taskInformation!.description ?? "N/A"),
                          _buildInfoRow("Contract Price",
                              _formatPrice(_taskInformation!.contactPrice)),
                          _buildInfoRow("Duration",
                              _taskInformation!.duration?.toString() ?? "N/A"),
                          _buildInfoRow(
                              "Period", _taskInformation!.period ?? "N/A"),
                          _buildInfoRow(
                              "Urgency", _taskInformation!.urgency ?? "N/A"),
                          _buildInfoRow(
                              "Work Type", _taskInformation!.workType ?? "N/A"),
                          _buildInfoRow("Start Date",
                              _taskInformation!.taskBeginDate ?? "N/A"),
                          _buildInfoRow(
                              "Status", _taskInformation!.status ?? "Active"),
                          _buildInfoRow(
                              "Remarks", _taskInformation!.remarks ?? "N/A"),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Implement edit functionality
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Edit functionality not implemented yet')));
                                  },
                                  icon: Icon(Icons.edit),
                                  label: Text("Edit Task"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isDeleting ? null : _disableTask,
                                  icon: _isDeleting
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          Icons.disabled_by_default_outlined),
                                  label: Text(_isDeleting
                                      ? "Disabling..."
                                      : "Disable Task"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Divider(height: 1),
        ],
      ),
    );
  }
}
