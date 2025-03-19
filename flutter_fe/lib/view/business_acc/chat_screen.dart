import 'dart:io';
import 'package:flutter/material.dart';
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
  bool isLoading = true;
  File? _selectedImage; // To store the selected image for the report modal

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

    if (fetchedAssignments != null) {
      setState(() {
        taskAssignments = fetchedAssignments;
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  // Method to pick an image for the report modal
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
        source: ImageSource.gallery); // Use gallery as source
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path); // Store the selected image
      });
    }
  }

  void _showReportModal() {
    final TextEditingController userNameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showModalBottomSheet(
      enableDrag: true,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: "Report User" and Subtitle
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 40, right: 40, top: 20),
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
                    // Reported User Name Input Field
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 40, right: 40, top: 20),
                      child: TextField(
                        controller: userNameController,
                        cursorColor: Color(0xFF0272B1),
                        decoration: InputDecoration(
                          label: Text('Reported User Name *'),
                          labelStyle: TextStyle(color: Color(0xFF0272B1)),
                          filled: true,
                          fillColor: Color(0xFFF1F4FF),
                          hintText: 'Enter user name',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Color(0xFF0272B1), width: 2),
                          ),
                        ),
                      ),
                    ),
                    // Report Description Text Field
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 40, right: 40, top: 20),
                      child: TextField(
                        controller: descriptionController,
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
                            borderSide:
                                BorderSide(color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Color(0xFF0272B1), width: 2),
                          ),
                        ),
                      ),
                    ),
                    // Proof (Upload Image) Section
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 40, right: 40, top: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Proof (Upload Image)',
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
                                await _pickImage(); // Call the image picker
                                setModalState(
                                    () {}); // Update modal state to show selected image
                              },
                              icon:
                                  Icon(Icons.upload_file, color: Colors.white),
                              label: Text(
                                'Upload Image',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF0272B1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.only(left: 16, right: 16),
                                alignment: Alignment.centerLeft,
                                minimumSize: Size(150,
                                    50), // Ensure button has a reasonable size
                              ),
                            ),
                          ),
                          if (_selectedImage != null) ...[
                            SizedBox(height: 10),
                            Image.file(
                              _selectedImage!,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Selected: ${_selectedImage!.path.split('/').last}',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Submit and Cancel Buttons
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 40, right: 40, top: 20, bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
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
                              // Basic validation
                              if (userNameController.text.trim().isEmpty ||
                                  descriptionController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Please fill in all required fields'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                Navigator.pop(context); // Close the modal
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Report Submitted!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
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
              ),
            );
          },
        );
      },
    );
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : (taskAssignments == null || taskAssignments!.isEmpty)
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
                          "You Don't Have Messages Yet, You can Start a Conversation By 'Right-Swiping' Your Favorite Tasker.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _showReportModal, // Show report modal
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0272B1),
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                        ),
                        child: Text(
                          "Report User",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
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
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Row(children: [
                        Icon(Icons.person, size: 20),
                        Text(
                          "${assignment.tasker.user?.firstName ?? ''} ${assignment.tasker.user?.middleName ?? ''} ${assignment.tasker.user?.lastName ?? ''}",
                          style: TextStyle(fontSize: 14),
                        ),
                      ]),
                      trailing: Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                      onTap: () {
                        // Open Chat History
                        debugPrint("Task Taken ID: ${assignment.taskTakenId}");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => IndividualChatScreen(
                                  taskTitle: assignment.task.title,
                                  taskTakenId: assignment.taskTakenId)),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
