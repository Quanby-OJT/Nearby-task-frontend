import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/chat/ind_chat_screen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskInformation extends StatefulWidget {
  final int? taskID;
  const TaskInformation({super.key, this.taskID});

  @override
  State<TaskInformation> createState() => _TaskInformationState();
}

class _TaskInformationState extends State<TaskInformation> {
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
      final response =
          await _jobPostService.fetchTaskInformation(widget.taskID ?? 0);
      setState(() {
        _taskInformation = response?.task;
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
      appBar: AppBar(title: const Text('Task Information')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _taskInformation == null
              ? const Center(child: Text('No task information available'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInfoRow(
                              "Title", _taskInformation!.title ?? "N/A"),
                          _buildInfoRow("Description",
                              _taskInformation!.description ?? "N/A"),
                          _buildInfoRow(
                              "Location", _taskInformation!.location ?? "N/A"),
                          _buildInfoRow(
                              "Urgency", _taskInformation!.urgency ?? "N/A"),
                          _buildInfoRow("Duration",
                              _taskInformation!.duration?.toString() ?? "N/A"),
                          _buildInfoRow(
                              "Status", _taskInformation!.status ?? "N/A"),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xFF03045E),
                            ),
                            child: TextButton(
                              onPressed: () {
                                int userId = storage.read('user_id') ?? 0;
                                if (_taskInformation != null) {
                                  taskController.assignTask(
                                    widget.taskID ?? 0,
                                    _taskInformation!.clientId ?? 0,
                                    userId,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          IndividualChatScreen(taskId: 0, taskTakenId: 0, taskTitle: _taskInformation!.title),
                                    ),
                                  );
                                }
                              },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                "Apply for this job".toUpperCase(),
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value, softWrap: true),
          ),
        ],
      ),
    );
  }
}
