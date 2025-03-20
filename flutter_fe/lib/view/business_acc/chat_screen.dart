import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/report_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/view/chat/ind_chat_screen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<TaskAssignment>? taskAssignments;
  final GetStorage storage = GetStorage();
  final TaskController _taskController = TaskController();
  final ReportController reportController = ReportController();
  bool isLoading = true;

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

    // Check if the widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        taskAssignments = fetchedAssignments;
        isLoading = false;
      });
    }
  }

  void _showReportModal() {
    showModalBottomSheet(
      enableDrag: true,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: "Report User" and Subtitle
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 40, right: 40, top: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Report User",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                    fontSize: 24,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Please fill in the details below",
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: Colors.indigo,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Report Description Text Field
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 40, right: 40, top: 20),
                            child: TextField(
                              controller: reportController.reasonController,
                              maxLines: 5,
                              cursorColor: Color(0xFF0272B1),
                              decoration: InputDecoration(
                                label: Text('Report Description *'),
                                labelStyle: TextStyle(color: Color(0xFF0272B1)),
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: Color(0xFFF1F4FF),
                                hintText: 'Enter description...',
                                hintStyle: TextStyle(color: Colors.grey),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.transparent,
                                    width: 0,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: Color(0xFF0272B1), width: 2),
                                ),
                                errorText: reportController.errors['reason'],
                              ),
                            ),
                          ),
                          // Proof (Upload Images) Section
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 40, right: 40, top: 20, bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upload Proof (Limited to 5 images only)',
                                  style: TextStyle(
                                    color: Color(0xFF0272B1),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await reportController
                                          .pickImages(context);
                                      setModalState(() {});
                                    },
                                    icon: Icon(Icons.upload_file,
                                        color: Colors.white),
                                    label: Text(
                                      'Upload Images',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF0272B1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding:
                                          EdgeInsets.only(left: 16, right: 16),
                                      alignment: Alignment.centerLeft,
                                      minimumSize: Size(150, 50),
                                    ),
                                  ),
                                ),
                                if (reportController
                                    .selectedImages.isNotEmpty) ...[
                                  SizedBox(height: 10),
                                  SizedBox(
                                    height: 140,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: reportController
                                          .selectedImages.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 10),
                                          child: Column(
                                            children: [
                                              Stack(
                                                children: [
                                                  // Use FutureBuilder to load the image bytes
                                                  FutureBuilder<Uint8List>(
                                                    future: reportController
                                                        .selectedImages[index]
                                                        .readAsBytes(),
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return SizedBox(
                                                          height: 100,
                                                          width: 100,
                                                          child: Center(
                                                              child:
                                                                  CircularProgressIndicator()),
                                                        );
                                                      }
                                                      if (snapshot.hasError) {
                                                        return SizedBox(
                                                          height: 100,
                                                          width: 100,
                                                          child: Center(
                                                              child: Text(
                                                                  'Error loading image')),
                                                        );
                                                      }
                                                      return Image.memory(
                                                        snapshot.data!,
                                                        height: 100,
                                                        width: 100,
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  ),
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setModalState(() {
                                                          reportController
                                                              .removeImage(
                                                                  index);
                                                        });
                                                      },
                                                      child: Container(
                                                        color: Colors.red,
                                                        child: Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Text(
                                                'Image ${index + 1}',
                                                style: TextStyle(
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Fixed buttons at the bottom
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 40, right: 40, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            reportController.clearForm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            reportController.validateAndSubmit(
                                context, setModalState);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0272B1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                          ),
                          child: Text(
                            'Submit',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    // Clean up controllers or any resources
    reportController.reasonController.dispose();
    super.dispose();
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
      floatingActionButton:
          (taskAssignments != null && taskAssignments!.isNotEmpty)
              ? FloatingActionButton(
                  onPressed: _showReportModal,
                  backgroundColor:
                      Colors.redAccent, // Use a warning color for reporting
                  elevation: 6, // Add shadow for depth
                  child: Icon(
                    Icons.flag, // Use a flag icon to represent reporting
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: 'Report User', // Add tooltip for accessibility
                )
              : null, // Show FAB only when there are task assignments
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : (taskAssignments == null || taskAssignments!.isEmpty)
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.end, // Align button to the right
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors
                                  .redAccent, // Use a warning color for reporting
                              shape: CircleBorder(),
                              child: InkWell(
                                onTap: _showReportModal,
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    Icons
                                        .flag, // Use a flag icon to represent reporting
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
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
                        debugPrint(
                            "Task Id: " + assignment.taskTakenId.toString());
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
