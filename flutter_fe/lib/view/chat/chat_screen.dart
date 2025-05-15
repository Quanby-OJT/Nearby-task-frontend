import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/report_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/conversation.dart';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/view/chat/ind_chat_screen.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/sockets/src/socket_notifier.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../controller/conversation_controller.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<TaskAssignment> taskAssignments = [];
  List<Conversation> conversation = [];
  List<TaskAssignment?> filteredTaskAssignments = [];
  final GetStorage storage = GetStorage();
  final TaskController _taskController = TaskController();
  final ReportController reportController = ReportController();
  final ConversationController conversationController =
      ConversationController();

  final ProfileController _profileController = ProfileController();
  final ClientServices _clientServices = ClientServices();
  List<UserModel> tasker = [];
  int? cardNumber = 0;
  bool _isUploadDialogShown = false;
  bool _isLoading = true;
  final bool _isRead = false;
  IO.Socket? socket;

  AuthenticatedUser? _user;
  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;
  bool _documentValid = false;
  bool _isModalOpen = false;
  String? _selectedReportCategory;

  @override
  void initState() {
    super.initState();

    loadAll();

    conversationController.searchConversation.addListener(filterMessages);

    socket = IO.io('http://localhost:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket?.on('new_message', (data) {
      if (data['user_id'] != storage.read('user_id')) {
        setState(() {
          _fetchTaskAssignments();
        });
      }
    });

    socket?.on('message_read', (data) {
      _fetchTaskAssignments();
      setState(() {});
    });
  }

  void loadAll() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _fetchTaskAssignments(),
      _fetchTaskers(),
      _fetchUserIDImage(),
      _fetchReportHistory(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    reportController.reasonController.dispose();
    conversationController.searchConversation.dispose();
    _selectedReportCategory = null;
    super.dispose();
    socket?.disconnect();
  }

  void filterMessages() {
    String query = conversationController.searchConversation.text.toLowerCase();
    setState(() {
      filteredTaskAssignments = taskAssignments.where((taskTaken) {
        return (taskTaken.task?.title.toLowerCase().contains(query) ?? false) ||
            (taskTaken.tasker?.user?.firstName.toLowerCase().contains(query) ??
                false) ||
            (taskTaken.tasker?.user?.middleName
                    ?.toLowerCase()
                    .contains(query) ??
                false) ||
            (taskTaken.tasker?.user?.lastName.toLowerCase().contains(query) ??
                false);
      }).toList();
    });
  }

  Future<void> _fetchTaskAssignments() async {
    try {
      setState(() {
        taskAssignments = [];
        filteredTaskAssignments = [];
        conversation = [];
        _isLoading = true;
      });

      final taskAndConversationResult = await _taskController.fetchTasksAndConversations();

      //debugPrint("TaskAndConversationResult: ${taskAndConversationResult.conversations}");

      // Extract tasks and conversations from result
      final tasks = taskAndConversationResult.taskAssignments;
      final convos = taskAndConversationResult.conversations;

      debugPrint("Raw Conversations: $convos");
      debugPrint("Task Assignments: $tasks");

      setState(() {
        taskAssignments = tasks;
        conversation = convos;
        filteredTaskAssignments = tasks; // Maintain same filtering logic
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint("Error fetching task assignments: $e");
      debugPrint(st.toString());
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load messages")),
        );
      }
    }
  }

  Future<void> _fetchTaskers() async {
    await reportController.fetchTaskers();
    debugPrint("Taskers loaded in ChatScreen: ${reportController.taskers}");
    setState(() {});
  }

  Future<void> _fetchReportHistory() async {
    int userId = storage.read('user_id');
    await reportController.fetchReportHistory(userId);
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
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 40, right: 40, top: 20),
                            child: DropdownSearch<Map<String, dynamic>>(
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: 'Search users...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              items: reportController.taskers,
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: 'Report User *',
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
                              itemAsString: (Map<String, dynamic> tasker) =>
                                  "${tasker['first_name']} ${tasker['middle_name'] ?? ''} ${tasker['last_name']}",
                              onChanged: (Map<String, dynamic>? newValue) {
                                setModalState(() {
                                  _selectedReportCategory = newValue != null
                                      ? newValue['user_id'].toString()
                                      : null;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Select a Category' : null,
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
                            int userId = storage.read('user_id');
                            int? reportedWhom = _selectedReportCategory != null
                                ? int.tryParse(_selectedReportCategory!)
                                : null;
                            if (_existingProfileImageUrl == null ||
                                _existingIDImageUrl == null ||
                                _existingProfileImageUrl!.isEmpty ||
                                _existingIDImageUrl!.isEmpty ||
                                !_documentValid) {
                              _showWarningDialog();
                              debugPrint("Image validation failed");
                              return;
                            }
                            // Selected tasker's user_id
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

  Future<void> _fetchUserIDImage() async {
    try {
      int userId = int.parse(storage.read('user_id').toString());

      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      debugPrint(user.toString());

      final response = await _clientServices.fetchUserIDImage(userId);

      if (response['success']) {
        setState(() {
          _user = user;
          _existingProfileImageUrl = user?.user.image;
          _existingIDImageUrl = response['url'];
          _documentValid = response['status'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching ID image: $e");
    }
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        title: const Text("Account Verification"),
        content: const Text(
            "Upload your Profile and ID images to complete your account. Verification will follow."),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FillUpClient()),
              );
              if (result == true) {
                setState(() {
                  _isLoading = true;
                  // Keep the flag true since we're refreshing data
                });

                await _fetchUserIDImage(); // Refresh user profile and ID image data
              } else {
                setState(() {
                  _isUploadDialogShown = false;
                });
              }
            },
            child: const Text("Verify Account"),
          ),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Reset the flag when user cancels
                setState(() {
                  _isUploadDialogShown = false;
                });
              },
              child: Text('Cancel')),
        ],
      ),
    );
  }

  void _showReportHistoryModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Report History",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                  fontSize: 24,
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: reportController.reportHistory.isEmpty
                    ? Center(
                        child: Text(
                          "No report history available yet.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: reportController.reportHistory.length,
                        itemBuilder: (context, index) {
                          final report = reportController.reportHistory[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              title: Text(
                                "Report #${report.reportId ?? 'N/A'}",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Reason: ${report.reason ?? 'No reason provided'}"),
                                  Text(
                                      "Reported By: ${report.reportedByName ?? 'Unknown'}"),
                                  Text(
                                      "Reported Whom: ${report.reportedWhomName ?? 'Unknown'}"),
                                  Text(
                                      "Created At: ${report.createdAt ?? 'N/A'}"),
                                  Text(
                                      "Status: ${report.status != null ? (report.status! ? 'Resolved' : 'Pending') : 'N/A'}"),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          title: Column(
            children: [
              Text(
                "Chat Messages",
                style: GoogleFonts.montserrat(
                  color: Color(0xFF2A1999),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 5),
            ],
          ),
        ),
        floatingActionButton: (taskAssignments.isNotEmpty && !_isModalOpen)
            ? FloatingActionButton(
                onPressed: () {
                  _showReportModal();
                },
                backgroundColor: Colors.redAccent,
                elevation: 6,
                tooltip: 'Report User',
                child: Icon(
                  Icons.flag,
                  color: Colors.white,
                  size: 28,
                ),
              )
            : null,
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : taskAssignments.isEmpty
                ? RefreshIndicator(
                    onRefresh: _fetchTaskAssignments,
                    color: Color(0xFF0272B1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.signalMessenger,
                            size: 100,
                            color: Color(0xFF0272B1),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              "You don't have messages yet. Check your task requests to accept a tasker, or wait for them to accept your task.",
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
                                  child: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'report_user') {
                                        _showReportModal();
                                      } else if (value == 'report_history') {
                                        _showReportHistoryModal();
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      PopupMenuItem<String>(
                                        value: 'report_user',
                                        child: Row(
                                          children: [
                                            Icon(Icons.report,
                                                color: Colors.redAccent),
                                            SizedBox(width: 10),
                                            Text('Report User'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'report_history',
                                        child: Row(
                                          children: [
                                            Icon(Icons.history,
                                                color: Colors.green),
                                            SizedBox(width: 10),
                                            Text('Report History'),
                                          ],
                                        ),
                                      ),
                                    ],
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
                    ))
                : Column(children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: conversationController.searchConversation,
                        decoration: InputDecoration(
                          hintText: 'Search Messages...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20),
                          suffixIcon: Icon(FontAwesomeIcons.magnifyingGlass),
                          focusColor: Color(0xFF20127F),
                        ),
                      ),
                    ),
                    Expanded(
                        child: _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0272B1),
                                ),
                              )
                            : filteredTaskAssignments.isEmpty
                                ? Center(
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              FontAwesomeIcons.signalMessenger,
                                              size: 100,
                                              color: Color(0xFF0272B1),
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              "Message Not Found.",
                                              style: GoogleFonts.montserrat(
                                                color: Color(0xFF0272B1),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 18,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              " Maybe You haven't accept a tasker that applied for your task.",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        )))
                                : RefreshIndicator(
                                    onRefresh: _fetchTaskAssignments,
                                    color: Color(0xFF0272B1),
                                    child: ListView.builder(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      itemCount: filteredTaskAssignments.length,
                                      itemBuilder: (context, index) {
                                        final taskAssignment = filteredTaskAssignments[index];
                                        if (taskAssignment == null) {
                                          return SizedBox.shrink();
                                        }

                                        // Find the conversation for this taskAssignment, or pass null if not found
                                        final conversations = conversation.firstWhereOrNull(
                                              (conv) => conv.taskTakenId == taskAssignment.taskTakenId,
                                        );

                                        debugPrint("Conversations for TaskTakenId ${taskAssignment.taskTakenId}: $conversations");
                                        return conversationCard(taskAssignment, conversations);
                                      },
                                    )
                        )
                    )
                  ]));
  }

  void showMessageOptions(BuildContext context, int taskTakenId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Conversation',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          content: Text(
              'Are you sure you want to delete this conversation? This cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                conversationController.deleteMessage(context, taskTakenId);
                Navigator.of(context).pop();
                setState(() {
                  _fetchTaskAssignments();
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget conversationCard(TaskAssignment taskTaken, Conversation? conversation) {
    final currentUserId = storage.read('user_id');
    final role = storage.read('role');

    final senderId = conversation?.userId;
    debugPrint("Current User ID: $currentUserId, Sender Id: $senderId, and Role: $role");
    final bool isSender = senderId != currentUserId;
    final bool isUnread = taskTaken.unreadCount > 0;
    debugPrint("Is Receiver: $isSender, Unread Messages for Task: ${taskTaken.taskTakenId} - ${taskTaken.unreadCount}");
    final user = role == 'Tasker' ? taskTaken.client?.user : taskTaken.tasker?.user;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndividualChatScreen(
                taskTakenId: taskTaken.taskTakenId,
                taskId: taskTaken.task?.id ?? 0,
                taskTitle: taskTaken.task?.title ?? '',
                taskTakenStatus: taskTaken.taskStatus,
              ),
            ),
          ).then((_) => _fetchTaskAssignments());
        },
        onLongPress: () => showMessageOptions(context, taskTaken.taskTakenId),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: user?.imageName != null
                    ? NetworkImage(user!.imageName!)
                    : null,
                child: user?.imageName == null
                    ? Icon(FontAwesomeIcons.user, size: 30)
                    : null,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        taskTaken.task?.title ?? 'No Title',
                        style: GoogleFonts.montserrat(
                          color: Color(0xFF0272B1),
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        readIconMarker(
                          isUnread
                              ? FontAwesomeIcons.check
                              : FontAwesomeIcons.checkDouble,
                          Colors.green,
                        ),
                      SizedBox(width: 4),
                      Text(
                        "${user?.firstName ?? ''} ${user?.middleName ?? ''} ${user?.lastName ?? ''}",
                        style: GoogleFonts.poppins(
                          fontWeight: isSender && isUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                          ),
                        ),
                      ]
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget readIconMarker(IconData icon, Color color) {
    return Padding(
        padding: EdgeInsets.only(right: 10),
        child: Icon(
          icon,
          color: color, // Single check for sent but not necessarily read
          size: 16,
        ));
  }
}
