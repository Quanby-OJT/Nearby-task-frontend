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
  final String role;
  const TaskInformation({super.key, this.taskID, required this.role});

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
  bool _isApplying = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();

    debugPrint("Task ID from the widget: ${widget.taskID}");
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
    // _fetchIfTaskIsAssigned();
  }

  // Future<void> _fetchIfTaskIsAssigned() async {
  //   debugPrint("Task Information from the widget: ${widget.taskID}");
  //   try {
  //     final String response = await taskController.fetchIsApplied(
  //       widget.taskID ?? 0,
  //       _taskInformation!.clientId,
  //       storage.read('user_id') ?? 0,
  //     );
  //     if (response == 'True') {
  //       setState(() {
  //         _isApplying = true;
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint("Error fetching task details: $e");
  //     setState(() {
  //       _isLoading = false;
  //       _isApplying = false; // Optionally reset on error
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        'Task Information',
        style: const TextStyle(
          color: Color(0xFF03045E),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      )),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _taskInformation == null
              ? const Center(child: Text('No task information available'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _taskInformation!.title ?? "N/A",
                                          style: GoogleFonts.montserrat(
                                            color: const Color(0xFF03045E),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Row(
                                          children: [
                                            if (_taskInformation!.status != null)
                                              Flexible(
                                                child: Text(
                                                  _taskInformation!.status!,
                                                  style: GoogleFonts.montserrat(
                                                    color: Color.fromARGB(
                                                        255, 57, 209, 11),
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              _buildInfoRow("Required Tasker",
                                  _taskInformation!.workType ?? "N/A"),
                              const SizedBox(height: 10),
                              _buildInfoRow("Specialization",
                                  _taskInformation!.specialization ?? "N/A"),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: Row(
                                  spacing: 5,
                                  children: [
                                    Icon(
                                      Icons.location_pin,
                                      size: 20,
                                    ),
                                    Text(
                                      _taskInformation!.location ?? "Location",
                                      style: GoogleFonts.openSans(),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildInfoRow("Contact Price",
                                  _taskInformation!.contactPrice.toString()),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // about the client profile
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        color: Color.fromARGB(255, 239, 254, 255),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Client Profile",
                                          style: GoogleFonts.montserrat(
                                            color: const Color(0xFF03045E),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              _buildInfoRow("Name", "Mike Smith"),
                              const SizedBox(height: 10),
                              _buildInfoRow("Account", "Verified"),
                              const SizedBox(height: 10),
                              _buildInfoRow("Email", "mike.smith@example.com"),
                              const SizedBox(height: 10),
                              _buildInfoRow("Phone", "+1234567890"),
                              const SizedBox(height: 10),
                              _buildInfoRow("Status", "Active"),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 16),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: _isApplying
                              ? const Color.fromARGB(255, 203, 4, 4)
                              : const Color(0xFF03045E),
                        ),
                        child: TextButton(
                          onPressed: () async {
                            int userId = storage.read('user_id') ?? 0;
                            if (_taskInformation != null) {
                              String result = await taskController.assignTask(
                                widget.taskID ?? 0,
                                _taskInformation!.clientId,
                                userId,
                                // widget.role,
                              );

                              debugPrint("Assign task result: $result");

                              if (result ==
                                  'A New Conversation Has been Opened.') {
                                setState(() {
                                  _isApplying = !_isApplying;
                                });
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _isApplying ? "Cancel" : "Apply Now",
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style:
                GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16),
          )
        ],
      ),
    );
  }

  Color statusColor(String taskStatus) {
    switch (taskStatus) {
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
