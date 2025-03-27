import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  List<String> taskTaskerStatus = ['Interested', 'Confirmed', 'Rejected', 'Ongoing', 'Completed', 'Canceled', 'Pending'];//For Tasker Only
  List<String> taskClientStatus = ['In Negotiation', 'Confirmed', 'Rejected', 'Canceled', 'Pending'];//For Tasker Only
  List<String> rejectionReasons = [
    'Tasker is not available',
    'I had other concerns that needed more attention',
    'Tasker is not willing to work with me',
    'Tasker does not have the required skills',
    'Others (please specify)'
  ];
  bool rejectFormField = false;
  bool depositPayment = false;
  final rejectTasker = GlobalKey<FormState>();



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
          : SizedBox(
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      taskAssignment?.task?.title ?? "Untitled Task",
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0272B1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Divider(height: 30),
                  //About the Task
                  Text(
                    "About the Task",
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0272B1)
                    ),
                  ),
                  Text(
                    taskAssignment?.task?.description ?? "N/A",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                    softWrap: true,
                    textAlign: TextAlign.justify,
                  ),
                  _buildInfoRow(
                      FontAwesomeIcons.locationPin, Colors.red, taskAssignment?.task?.location ?? "N/A"),
                  _buildInfoRow(FontAwesomeIcons.toolbox, Colors.blue, taskAssignment?.task?.specialization ?? "N/A"),
                  _buildInfoRow(
                    FontAwesomeIcons.moneyBill,
                    Colors.green,
                    "₱ ${
                      NumberFormat(
                        "#,##0.00", "en_PH").format(
                        taskAssignment?.task?.contactPrice?.roundToDouble() ?? 0.00
                        )
                    }"
                  ),
                  Divider(height: 30),
                  _buildInfoRow(FontAwesomeIcons.calendar, Colors.red, "${taskAssignment?.task?.duration} ${taskAssignment?.task?.period}"),
                  _buildInfoRow(FontAwesomeIcons.clock, Colors.redAccent, taskAssignment?.task?.urgency ?? "N/A"),
                  _buildInfoRow(FontAwesomeIcons.userGroup, Colors.black45, taskAssignment?.task?.workType ?? "N/A"),
                  _buildInfoRow(FontAwesomeIcons.calendarDay, Colors.red, taskAssignment?.task?.taskBeginDate ?? "N/A"),
                  if(role == "Tasker") ...[
                    _buildInfoRow(
                        FontAwesomeIcons.chargingStation, Colors.black, taskAssignment?.task?.status ?? "Unknown Status"),
                  ],
                  _buildInfoRow(
                      FontAwesomeIcons.paperclip, Colors.brown, taskAssignment?.task?.remarks ?? "N/A"),
                  Divider(height: 30),
                  // _buildInfoRow(
                  //     "Tasker Status", taskAssignment?.taskStatus ?? "Unknown Status"),
                  Row(
                    children: [
                      Text(
                        "Tasker Status",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(width: 50),
                      Container(
                        width: 200, // Adjust width as needed
                        child: DropdownButtonFormField(
                          value: taskAssignment?.taskStatus, // Set an initial value if possible
                          items: taskTaskerStatus.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              //taskAssignment?.taskStatus = value.toString();
                              switch (value) {
                                case "Rejected":
                                  depositPayment = false;
                                  break;
                                case "Canceled":
                                  depositPayment = false;
                                  break;
                                case "Confirmed":
                                  depositPayment = true;
                                  break;
                                case "Completed":
                                  depositPayment = false;
                                  break;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInfoRow(IconData label, Color color, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(
            label,
            size: 24,
            color: color,
          ),
          SizedBox(width: 30),
          Expanded(
            child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                softWrap: true
            ),
          ),
        ],
      ),
    );
  }
}
