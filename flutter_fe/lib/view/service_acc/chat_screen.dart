import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/view/chat/ind_chat_screen.dart';
import 'package:get_storage/get_storage.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<TaskAssignment>? taskAssignments; // This is already correctly typed
  final GetStorage storage = GetStorage();
  final TaskController _taskController = TaskController();

  @override
  void initState() {
    super.initState();
    _fetchTaskAssignments();
  }

  Future<void> _fetchTaskAssignments() async {
    int userId = storage.read('user_id');

    // Get the list of task assignments
    List<TaskAssignment>? fetchedAssignments =
        await _taskController.getAllAssignedTasks(context, userId);

    setState(() {
      taskAssignments = fetchedAssignments; // Assign the list directly
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Center(
          child: Text(
            "NearByTask Conversation",
            style: TextStyle(
              color: Color(0xFF0272B1),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      ),
      body: (taskAssignments == null || taskAssignments!.isEmpty)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message,
                    size: 100,
                    color: Color(0xFF0272B1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "You Don't Have Messages Yet, You can Start a Conversation By 'Right-Swiping' Your Favorite Task in hand.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: taskAssignments?.length ?? 0,
              itemBuilder: (context, index) {
                final assignment = taskAssignments![index];
                return ListTile(
                  title: Text(
                    assignment.task.title ?? "Unknown Task",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Row(children: [
                    Icon(
                      Icons.cases,
                      size: 20,
                    ),
                    Text(
                      "${assignment.tasker.user?.firstName ?? ''} ${assignment.tasker.user?.middleName ?? ''} ${assignment.tasker.user?.lastName ?? ''}",
                      style: TextStyle(fontSize: 14),
                    )
                  ]),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                  onTap: () {
                    // Open Chat History
                    debugPrint("Task Id: ${assignment.taskTakenId}");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => IndividualChatScreen(
                              taskTitle: assignment.task.title,
                              taskTakenId: assignment.task.id ?? 0)),
                    );
                  },
                );
              },
            ),
    );
  }
}
