import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_fe/view/business_acc/edit_task_page.dart';

class BusinessTaskDetail extends StatefulWidget {
  final int taskID;
  final TaskModel? task; // Optional task model if already loaded

  const BusinessTaskDetail({
    super.key,
    required this.taskID,
    this.task,
  });

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
        _taskInformation = response?.task;
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

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Task'),
        content: Text(
            'Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final result = await _taskController.deleteTask(widget.taskID);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task deleted successfully')),
        );
        Navigator.pop(
            context, true); // Return true to indicate task was deleted
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to delete task: ${result['error'] ?? "Unknown error"}')),
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

  @override
  Widget build(BuildContext context) {
    TaskModel? taskToDisplay = widget.task ?? _taskInformation;

    // Format the price safely
    String priceDisplay = "N/A";
    if (taskToDisplay?.contactPrice != null) {
      try {
        priceDisplay = NumberFormat("#,##0.00", "en_US")
            .format(taskToDisplay!.contactPrice.roundToDouble());
      } catch (e) {
        priceDisplay = taskToDisplay!.contactPrice.toString();
      }
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Task Details',
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
        iconTheme: IconThemeData(color: Color(0xFFB71A4A)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: taskToDisplay == null
                ? null
                : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditTaskPage(task: taskToDisplay),
                      ),
                    );
                    if (result == true) {
                      // Task was updated, refresh the page
                      Navigator.pop(context, true);
                    }
                  },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : taskToDisplay == null
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
                              taskToDisplay.title ?? "Untitled Task",
                              style: GoogleFonts.montserrat(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE23670),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Divider(height: 30),
                          _buildInfoRow(
                              "Location", taskToDisplay.location ?? "N/A"),
                          _buildInfoRow("Specialization",
                              taskToDisplay.specialization ?? "N/A"),
                          _buildInfoRow("Description",
                              taskToDisplay.description ?? "N/A"),
                          _buildInfoRow("Contract Price", "₱ $priceDisplay"),
                          _buildInfoRow("Duration",
                              taskToDisplay.duration.toString() ?? "N/A"),
                          _buildInfoRow(
                              "Period", taskToDisplay.period ?? "N/A"),
                          _buildInfoRow(
                              "Urgency", taskToDisplay.urgency ?? "N/A"),
                          _buildInfoRow(
                              "Work Type", taskToDisplay.workType ?? "N/A"),
                          _buildInfoRow("Start Date",
                              taskToDisplay.taskBeginDate ?? "N/A"),
                          _buildInfoRow(
                              "Status", taskToDisplay.status ?? "Active"),
                          _buildInfoRow(
                              "Remarks", taskToDisplay.remarks ?? "N/A"),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _isDeleting ? null : _deleteTask,
                            icon: _isDeleting
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.delete_outlined),
                            label: Text(
                                _isDeleting ? "Deleting..." : "Delete Task"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              minimumSize: Size(double.infinity, 50),
                            ),
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
