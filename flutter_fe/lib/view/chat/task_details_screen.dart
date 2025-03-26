import 'package:flutter/material.dart';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskDetailsScreen extends StatefulWidget{
  final int taskTakenId;

  const TaskDetailsScreen({super.key, required this.taskTakenId});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

//Main Application Page
class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController taskController = TaskController();
  TaskAssignment? taskAssignment;
  bool _isLoading = true;
  String role = "";
  final storage = GetStorage();
  List<String> taskClientStatus = ['Available', 'Already Taken', 'Closed', 'On Hold', 'Reported'];//For Client Only
  List<String> taskTaskerStatus = ['In Negotiation', 'Interested', 'Confirmed', 'Rejected', 'Ongoing', 'Completed', 'Canceled', 'Pending'];//For Tasker Only


  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
  }

  Future<void> _fetchTaskDetails() async {
    role = await storage.read('role');
    debugPrint(widget.taskTakenId.toString());
    try {
      final response = await _jobPostService.fetchAssignedTaskInformation(widget.taskTakenId ?? 0);
      debugPrint("Response: $response");
      setState(() {
        taskAssignment = response;
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
          : taskAssignment == null
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
                    taskAssignment?.task.title ?? "Untitled Task",
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
                    "Location", taskAssignment?.task.location ?? "N/A"),
                _buildInfoRow("Specialization",
                    taskAssignment?.task.specialization ?? "N/A"),
                _buildInfoRow("Description",
                    taskAssignment?.task.description ?? "N/A"),
                _buildInfoRow("Contract Price", "₱ ${NumberFormat(
                    "#,##0.00", "en_PH").format(
                    taskAssignment?.task.contactPrice?.roundToDouble() ?? 0.00
                )}"),
                _buildInfoRow("Duration",
                    taskAssignment?.task.duration?.toString() ?? "N/A"),
                _buildInfoRow(
                    "Period", taskAssignment?.task.period ?? "N/A"),
                _buildInfoRow(
                    "Urgency", taskAssignment?.task.urgency ?? "N/A"),
                _buildInfoRow(
                    "Work Type", taskAssignment?.task.workType ?? "N/A"),
                _buildInfoRow("Start Date",
                    taskAssignment?.task.taskBeginDate ?? "N/A"),
                _buildInfoRow(
                    "Task Status", taskAssignment?.task.status ?? "Unknown Status"),
                _buildInfoRow(
                    "Tasker Status", taskAssignment?.taskStatus ?? "Unknown Status"),
                _buildInfoRow(
                    "Remarks", taskAssignment?.task.remarks ?? "N/A"),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
                fontWeight: FontWeight.bold,
              fontSize: 20
            ),
          ),
          Expanded(
            child: Text(
                value,
                style: TextStyle(
                  fontSize: 16
                ),
                softWrap: true
            ),
          ),
        ],
      ),
    );
  }
}
