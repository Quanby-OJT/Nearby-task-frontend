import 'package:flutter/material.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskDetailsScreen extends StatefulWidget {
  final int taskId;

  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

//Main Application Page
class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController taskController = TaskController();
  TaskModel? _taskInformation;
  bool _isLoading = true;
  bool _isAssigned = false;
  String role = "";
  final storage = GetStorage();
  List<String> taskClientStatus = [
    'In Negotiation',
    'Interested',
    'Confirmed',
    'Rejected',
    'Ongoing',
    'Completed',
    'Canceled',
    'Pending'
  ]; //For Client Only
  List<String> taskTaskerStatus = [
    'In Negotiation',
    'Interested',
    'Confirmed',
    'Rejected',
    'Ongoing',
    'Completed',
    'Canceled',
    'Pending'
  ]; //For Tasker Only

  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
  }

  Future<void> _fetchTaskDetails() async {
    role = await storage.read('role');
    debugPrint(role);
    try {
      final response =
          await _jobPostService.fetchTaskInformation(widget.taskId ?? 0);
      debugPrint("Response: $response");

      // Check if task is assigned
      if (response != null) {
        final isAssigned =
            await _jobPostService.isTaskAssigned(response.taskTakenId, widget.taskId);
        setState(() {
          _taskInformation = response.task;
          _isAssigned = isAssigned;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
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
              : _isAssigned
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'This task has already been assigned',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please select another task',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
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
                                //_buildInfoRow("Title", task.title ?? "N/A"),
                                Text(
                                  task.title ?? "Unable to Retrieve Your Task",
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                //_buildInfoRow("Description", task.description ?? "N/A"),
                                Text(
                                  "Task Description",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                    task.description ??
                                        "Unable to Retrieve Your Task",
                                    style: TextStyle(
                                      fontSize: 15,
                                    )),
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(children: [
                                        Icon(Icons.location_pin,
                                            color: Colors.red),
                                        Text(task.location ?? "N/A",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ))
                                      ]),
                                      // Text(
                                      //   " | ",
                                      //   style: TextStyle(
                                      //     fontSize: 14,
                                      //     fontWeight: FontWeight.bold,
                                      //   )
                                      // ),
                                      Text(
                                          "${task.duration} Needed ${task.period}")
                                    ]),
                                //buildInfoRow("Location", task.location ?? "N/A"),
                                _buildInfoRow("NOTE", task.urgency.toString()),
                                Row(
                                  children: [
                                    Text(
                                      "Current Task Status: ",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        task.status!.toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                Text(
                                  "Update TASK STATUS to:",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: DropdownButtonFormField(
                                    value: task.status,
                                    items: taskClientStatus.map((String item) {
                                      return DropdownMenuItem<String>(
                                        value: item,
                                        child: Text(item),
                                      );
                                    }).toList(),
                                    onChanged: (String? newStatus) {
                                      if (newStatus == null) {
                                        debugPrint("Status is NULL");
                                        return;
                                      }
                                      // Handle the status change here
                                      print('Status changed to: $newStatus');
                                      // Optionally, update the task's status in your controller/service
                                      taskController.updateTaskStatus(
                                          context, widget.taskId, newStatus);
                                    },
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 16), softWrap: true),
          ),
        ],
      ),
    );
  }
}
