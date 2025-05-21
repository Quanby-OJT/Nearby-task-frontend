import 'package:flutter/material.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/view/custom_loading/custom_loading.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskAssignmentScreen extends StatefulWidget {
  const TaskAssignmentScreen({super.key, required this.tasker});

  final TaskerModel tasker;

  @override
  State<TaskAssignmentScreen> createState() => _TaskAssignmentScreenState();
}

class _TaskAssignmentScreenState extends State<TaskAssignmentScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Task Assignment',
              style: GoogleFonts.poppins(
                color: const Color(0xFFB71A4A),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFB71A4A),
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(child: Text('Task Assignment ${widget.tasker.id}')),
    );
  }
}
