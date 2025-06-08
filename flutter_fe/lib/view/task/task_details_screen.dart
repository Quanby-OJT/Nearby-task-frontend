import 'package:flutter/material.dart';
import 'dart:core';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
class TaskDetailsScreen extends StatefulWidget {
  final TaskAssignment taskAssignment;
  final String taskStatus;
  final DateTime transactionDate;

  const TaskDetailsScreen({super.key, required this.taskAssignment, required this.taskStatus, required this.transactionDate});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

//Main Application Page
class _TaskDetailsScreenState extends State<TaskDetailsScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Information',
          style: GoogleFonts.poppins(
            color: Color(0xFFB71A4A),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          )
        )
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            _buildTaskSection(),
            _buildUserSection(),
          ]
        )
      )
    );
  }

  Widget _buildTaskSection() {
    return SizedBox(
      width: double.infinity, // Maximize the width of the SizedBox
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Card(
          elevation: 4,
          shadowColor: Color(0XFFB71A4A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTitleSection("About the Task", FontAwesomeIcons.wrench),
                _buildInfoRow("Title", widget.taskAssignment.task?.title ?? "N/A"),
                _buildInfoColumn("Description", widget.taskAssignment.task?.description ?? "N/A"),
                _buildInfoRow("Specialization", widget.taskAssignment.task?.specialization ?? "N/A"),
                _buildInfoRow("Work Type", widget.taskAssignment.task?.workType ?? "N/A"),
                _buildInfoRow("Scope", widget.taskAssignment.task?.scope ?? "N/A"),
                _buildInfoRow("Contact Price", widget.taskAssignment.task?.contactPrice.toString() ?? "N/A"),
                _buildInfoRow("Urgency", widget.taskAssignment.task?.urgency ?? "N/A"),
                _buildInfoRow("Remarks", widget.taskAssignment.task?.remarks ?? "N/A"),
                _buildInfoRow("Status", widget.taskStatus),
                _buildInfoColumn("Date of Transaction", DateFormat('yyyy-MM-dd hh:mm a').format(widget.transactionDate)), // Display formatted date and time),
              ]
            )
          )
        )
      )
    );
  }

  Widget buildTitleSection(String title, IconData icon){
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12), // Optional padding for the square
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999), // Make the border curved
            color: Color(0XFFEAE7FC)
          ),
          child: Icon(icon, color: Color(0XFF170A66)),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0XFFB71A4A)
          )
        )
      ]
    );
  }

  Widget _buildUserSection() {
    String role = GetStorage().read('role');
    bool isTasker = role == "Tasker";
    String name = isTasker ? "${widget.taskAssignment.tasker?.user?.firstName} ${widget.taskAssignment.tasker?.user?.middleName} ${widget.taskAssignment.tasker?.user?.lastName}" : "${widget.taskAssignment.client?.user?.firstName} ${widget.taskAssignment.client?.user?.middleName} ${widget.taskAssignment.client?.user?.lastName}";
    return SizedBox(
      width: double.infinity, // Maximize the width of the SizedBox
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Card(
          elevation: 4,
          shadowColor: Color(0XFFB71A4A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTitleSection(isTasker ? "About the Client" : "About the Tasker", isTasker ? FontAwesomeIcons.userTie : FontAwesomeIcons.userGear),
                _buildInfoRow("Name: ",  name),
                if(!isTasker)...[
                  _buildInfoRow("Specialization", widget.taskAssignment.tasker?.specialization.specialization ?? "N/A"),
                  _buildInfoRow("Related Skills", widget.taskAssignment.tasker?.skills ?? "N/A"),
                ]
              ]
            )
          )
        )
      )
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 14),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16), softWrap: true),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 14),
          ),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16), softWrap: true),
        ],
      ),
    );
  }
}
