import 'package:flutter/material.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/task_information.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskDetails extends StatefulWidget {
  final int userID;

  const TaskDetails({super.key, required this.userID});

  @override
  State<TaskDetails> createState() => _TaskDetailsState();
}

class _TaskDetailsState extends State<TaskDetails> {
  final TaskDetailsService _taskDetailsService = TaskDetailsService();
  TaskModel? task;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
  }

  Future<void> _fetchTaskDetails() async {
    try {
      final fetchedTask =
          await _taskDetailsService.fetchTaskDetails(widget.userID);

      setState(() {
        task = fetchedTask;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to fetch task";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Task Details'.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: const Color(0xFF03045E),
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task?.title ?? "No Title",
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text("Description: ${task?.description ?? "N/A"}"),
                      SizedBox(height: 10),
                      Text("Location: ${task?.location ?? "N/A"}"),
                      SizedBox(height: 10),
                      Text("Status: ${task?.status ?? "N/A"}"),
                    ],
                  ),
                ),
    );
  }
}
