import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/task_request_controller.dart';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../service_acc/legal_terms_and_conditions.dart';

class TaskDetailsScreen extends StatefulWidget {
  final TaskAssignment taskAssignment;

  const TaskDetailsScreen({super.key, required this.taskAssignment});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

//Main Application Page
class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final TaskController taskController = TaskController();
  final TaskRequestController taskRequestController = TaskRequestController();
  final bool _isLoading = true;
  String role = "";
  final storage = GetStorage();
  List<String> skills = [];
  String address = "";
  bool agreed = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      agreed = false;
    });
  }

  // Future<void> _fetchTaskDetails() async {
  //   role = await storage.read('role');
  //   debugPrint(widget.taskTakenId.toString());
  //   try {
  //     final response = await _jobPostService
  //         .fetchAssignedTaskInformation(widget.taskTakenId);
  //     debugPrint("Response: $response");
  //     setState(() {
  //       taskAssignment = response;
  //       selectedTaskStatus = taskStatus();
  //       skills = taskAssignment?.tasker?.skills.split(',') ?? [];
  //       _isLoading = false;
  //
  //       // Check if address exists and format it
  //       if (taskAssignment?.tasker?.address != null) {
  //         final addressMap = taskAssignment?.tasker?.address!;
  //
  //         // Format the address string using map key access
  //         address = [
  //           addressMap?["street"] ?? "",
  //           addressMap?["barangay"] ?? "",
  //           addressMap?["city"] ?? "",
  //           addressMap?["province"] ?? "",
  //           addressMap?["country"] ?? "",
  //           addressMap?["postal_code"] ?? ""
  //         ].where((element) => element.isNotEmpty).join(", ");
  //       } else {
  //         address = "N/A";
  //       }
  //     });
  //   } catch (e) {
  //     debugPrint("Error fetching task details: $e");
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  // String taskStatus() {
  //   switch (taskAssignment?.taskStatus) {
  //     case "Rejected":
  //       return "Reject the Tasker";
  //     case "Cancelled":
  //       return "Cancel the Task";
  //     case "Confirmed":
  //       return "Confirm Tasker";
  //     case "Ongoing":
  //       return "Ongoing";
  //     case "Completed":
  //       return "Completed";
  //     case "Pending":
  //       return "Waiting for Client";
  //     default:
  //       return "Unknown";
  //   }
  // }

  //Main Application
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'About the Task',
            style: GoogleFonts.poppins(
                color: Color(0xFFE23670), fontWeight: FontWeight.bold),
          ),
          iconTheme: IconThemeData(color: Color(0xFFE23670)),
        ),
        body: SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    buildTaskInformation(),
                    SizedBox(height: 16),
                    buildUserInformation(),
                    SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all<Color>(Color(0XFFE23670)),
                          foregroundColor:
                              WidgetStateProperty.all<Color>(Colors.white),
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                              EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 24.0)),
                        ),
                        child: Text(
                          "Back to Messages",
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ))
                  ],
                ))));
  }

  Widget buildTaskInformation() {
    return Card(
        elevation: 4,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              buildCardTitle(FontAwesomeIcons.screwdriverWrench,
                  widget.taskAssignment.task?.title ?? "Unknown Task"),
              SizedBox(height: 10),
              Text(
                "Description: ",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                widget.taskAssignment.task?.description ??
                    "No description available",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              SizedBox(height: 8),
              buildInfoRow(
                  "Address",
                  Icons.location_pin,
                  Color(0XFFD43D4D),
                  widget.taskAssignment.task?.address?.city ??
                      "Unknown Location"),
              SizedBox(height: 8),
              buildInfoRow(
                  "Required Specialization",
                  FontAwesomeIcons.gears,
                  Color(0XFF4A4A68),
                  widget.taskAssignment.task?.specialization ?? ""),
              SizedBox(height: 8),
              Row(children: [
                Text(
                  "Status: ",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: badgeColor(widget.taskAssignment.taskStatus),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.taskAssignment.taskStatus.toUpperCase(),
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: Colors.white),
                    )),
              ])
            ])));
  }

  Widget buildUserInformation() {
    String role = GetStorage().read('role');
    bool verified = role == "Client"
        ? widget.taskAssignment.tasker?.user?.verified ?? false
        : widget.taskAssignment.client?.user?.verified ?? false;

    return Card(
        elevation: 4,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              role == "Client"
                  ? buildCardTitle(
                      role == "Client"
                          ? FontAwesomeIcons.userGear
                          : FontAwesomeIcons.userTie,
                      widget.taskAssignment.tasker?.user != null
                          ? "${widget.taskAssignment.tasker?.user?.firstName ?? ""} ${widget.taskAssignment.tasker?.user?.middleName ?? ""} ${widget.taskAssignment.tasker?.user?.lastName ?? ""}"
                          : "Unknown User")
                  : buildCardTitle(
                      FontAwesomeIcons.userGear,
                      widget.taskAssignment.client?.user != null
                          ? "${widget.taskAssignment.client?.user?.firstName ?? ""} ${widget.taskAssignment.client?.user?.middleName ?? ""} ${widget.taskAssignment.client?.user?.lastName ?? ""}"
                          : "Unknown User"),
              SizedBox(height: 10),
              buildInfoRow(
                  null,
                  verified
                      ? FontAwesomeIcons.solidCircleCheck
                      : FontAwesomeIcons.circleCheck,
                  verified ? Colors.green : Colors.grey,
                  verified
                      ? "This user is Verified"
                      : "This user is not verified."),
              if (role == "Client") ...[
                SizedBox(height: 8),
                buildInfoRow(
                    "Specialization",
                    FontAwesomeIcons.screwdriverWrench,
                    Colors.black12,
                    widget.taskAssignment.tasker?.specialization ?? "N/A"),
                SizedBox(height: 8),
                buildInfoRow("Relevant Skills", FontAwesomeIcons.helmetSafety,
                    Colors.amber, widget.taskAssignment.tasker?.skills ?? "N/A")
              ]
            ])));
  }

  Widget buildInfoRow(
      String? label, IconData? icon, Color color, String value) {
    return Row(children: [
      if (icon != null) ...[
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        SizedBox(width: 10)
      ],
      if (label != null)
        Text("$label: ",
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
      Text(value, style: GoogleFonts.poppins(fontSize: 16))
    ]);
  }

  Widget buildCardTitle(IconData icon, String title) {
    return Row(children: [
      Icon(
        icon,
        color: Color(0xFFE23670),
        size: 30,
      ),
      SizedBox(width: 16),
      Text(title,
          style:
              GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20)),
    ]);
  }

  Color badgeColor(String status) {
    if (status == "Pending" || status == "Disputed") {
      return Color(0XFFD6932A);
    } else if (status == "Rejected" ||
        status == "Cancelled" ||
        status == "Expired" ||
        status == "Declined")
      return Color(0XFFD43D4D);
    else if (status == "Review" ||
        status == "Confirmed" ||
        status == "Ongoing" ||
        status == "Reworking")
      return Color(0XFF3E9FE5);
    else if (status == "Completed")
      return Color(0XFF4A4A68);
    else
      return Color(0XFF4A4A68);
  }
}
