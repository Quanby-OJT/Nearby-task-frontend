import 'package:flutter/material.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:get_storage/get_storage.dart';
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
  TaskModel? _taskInformation;
  bool _isLoading = true;
  final storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
  }

  Future<void> _fetchTaskDetails() async {
    try {
      final response = await _jobPostService.fetchTaskInformation(widget.taskTakenId ?? 0);
      debugPrint("Response: $response");
      setState(() {
        _taskInformation = response;
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
      appBar: AppBar(title: Text('Task Information')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _taskInformation == null
          ? Center(child: Text('No task information available'))
          : () {
        final task = _taskInformation!; // Promote to non-nullable
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoRow("Title", task.title ?? "N/A"),
                  _buildInfoRow(
                      "Description", task.description ?? "N/A"),
                  _buildInfoRow("Location", task.location ?? "N/A"),
                  _buildInfoRow(
                      "Urgency",
                      // task.urgency ?? false
                      //     ? "My Task is Urgent"
                      //     : "My Task is Not Urgent"),
                      task.urgency.toString()
                  ),
                  _buildInfoRow(
                      "Duration", task.duration.toString()),
                  _buildInfoRow("Status", task.status ?? "N/A"),
                ],
              ),
            ),
          ),
        );
      }(),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value, softWrap: true),
          ),
        ],
      ),
    );
  }
}