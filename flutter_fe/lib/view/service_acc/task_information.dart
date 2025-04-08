import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/chat/ind_chat_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  ClientModel? clientModel;
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
        clientModel = response?.client;
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
              ? const Center(child: Text('Error while Loading Task Information. Please Try Again.'))
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
                          Text(_taskInformation!.title, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 20)),
                          // _buildInfoRow("Description",
                          //     _taskInformation!.description),
                          SizedBox(height: 15,),
                          _buildInfoRowIcon(FontAwesomeIcons.user, Color(0XFF4A4A68), "${clientModel?.user?.firstName} ${clientModel?.user?.middleName} ${clientModel?.user?.lastName}"),
                          SizedBox(height: 15,),
                          Text(_taskInformation!.description),
                          Divider(color: Colors.grey[300], height: 30,),
                          _buildInfoRowIcon(
                              FontAwesomeIcons.locationPin, Color(0XFFD43D4D), _taskInformation!.location),
                          _buildInfoRowIcon(FontAwesomeIcons.clock, Color(0XFF3C28CC),
                              "${_taskInformation!.duration} ${_taskInformation!.period}"),
                          _buildInfoRow(
                              "This task is ", _taskInformation!.urgency),
                          Badge(
                            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            backgroundColor: statusColor(_taskInformation!.status),
                            label: Text(
                              _taskInformation!.status.toUpperCase(),
                              style: GoogleFonts.openSans(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              )
                            )
                          ),
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
            label,
            style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(value, softWrap: true, style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowIcon(IconData icon, Color color, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16),
          )
        ],
      ),
    );
  }

  Color statusColor(String taskStatus){
    switch(taskStatus){
      case "Available":
        return Color(0XFF2E763E);
      case "Already Taken":
        return Color(0XFFD6932A);
      case "Closed":
        return Color(0XFFD43D4D);
      case "On Hold":
        return Color(0XFF2C648C);
      case "Reported":
        return Color(0XFF7A2532);
      default:
        return Color(0XFFD43D4D);
    }
  }
}
