import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/report_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/view/chat/ind_chat_screen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';

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
  bool _isModalOpen = false;
  String? _selectedReportCategory;

  @override
  void initState() {
    super.initState();
    _fetchTaskAssignments();
    _fetchClients();
  }

  Future<void> _fetchTaskAssignments() async {
    int userId = storage.read('user_id');
    List<TaskAssignment>? fetchedAssignments =
        await _taskController.getAllAssignedTasks(context, userId);

    if (mounted) {
      setState(() {
        taskAssignments = fetchedAssignments;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchClients() async {
    await reportController.fetchClients(); // Fetch clients instead of taskers
    debugPrint("Clients loaded in ChatScreen: ${reportController.clients}");
    setState(() {});
  }

  void _showReportModal() {
    setState(() {
      _isModalOpen = true;
    });

    showModalBottomSheet(
      enableDrag: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 40, right: 40, top: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Report Client",
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
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 40, right: 40, top: 20),
                            child: DropdownSearch<Map<String, dynamic>>(
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: 'Search clients...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              items: reportController
                                  .clients, // Use clients instead of taskers
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: 'Report Client *',
                                  labelStyle:
                                      TextStyle(color: Color(0xFF0272B1)),
                                  filled: true,
                                  fillColor: Color(0xFFF1F4FF),
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
                                ),
                              ),
                              itemAsString: (Map<String, dynamic> client) =>
                                  "${client['first_name']} ${client['middle_name'] ?? ''} ${client['last_name']}",
                              onChanged: (Map<String, dynamic>? newValue) {
                                setModalState(() {
                                  _selectedReportCategory = newValue != null
                                      ? newValue['user_id'].toString()
                                      : null;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Select a Client' : null,
                            ),
                          ),
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
                                          .pickImages(modalContext);
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
                                if (reportController.imageUploadError !=
                                    null) ...[
                                  SizedBox(height: 5),
                                  Text(
                                    reportController.imageUploadError!,
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 12),
                                  ),
                                ],
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
                            setState(() {
                              _isModalOpen = false;
                              _selectedReportCategory = null; // Reset dropdown
                            });
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
                            int userId = storage
                                .read('user_id'); // Current tasker's user_id
                            int? reportedWhom = _selectedReportCategory != null
                                ? int.tryParse(_selectedReportCategory!)
                                : null; // Selected client's user_id
                            reportController.validateAndSubmit(
                                context, setModalState, userId, reportedWhom);
                            setState(() {
                              _isModalOpen = false;
                            });
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
    ).whenComplete(() {
      setState(() {
        _isModalOpen = false;
      });
    });
  }

  @override
  void dispose() {
    reportController.reasonController.dispose();
    _selectedReportCategory = null;
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
      floatingActionButton: (taskAssignments != null &&
              taskAssignments!.isNotEmpty &&
              !_isModalOpen)
          ? FloatingActionButton(
              onPressed: _showReportModal,
              backgroundColor: Colors.redAccent,
              elevation: 6,
              tooltip: 'Report Client',
              child: Icon(
                Icons.flag,
                color: Colors.white,
                size: 28,
              ),
            )
          : null,
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
                        mainAxisAlignment: MainAxisAlignment.end,
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
                              color: Colors.redAccent,
                              shape: CircleBorder(),
                              child: InkWell(
                                onTap: _showReportModal,
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.flag,
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
                        debugPrint(
                            "Task Id: " + assignment.taskTakenId.toString());
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => IndividualChatScreen(
                                taskId: assignment.task.id,
                                taskTitle: assignment.task.title,
                                taskTakenId: assignment.taskTakenId ?? 0
                              )
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
