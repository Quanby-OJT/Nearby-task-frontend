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
import 'package:get_storage/get_storage.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
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

    socket = IO.io('http://192.168.43.15:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket?.on('new_message', (data) {
      if (data['user_id'] != storage.read('user_id')) {
        _fetchTaskAssignments();
      }
    });

    socket?.on('message_read', (data) {
      _fetchTaskAssignments();
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
    socket?.disconnect();
    super.dispose();
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

      final taskAndConversationResult =
          await _taskController.fetchTasksAndConversations();
      final tasks = taskAndConversationResult.taskAssignments;
      final convs = taskAndConversationResult.conversations;

      debugPrint("Raw Conversations: $convs");
      debugPrint("Task Assignments: $tasks");

      setState(() {
        taskAssignments = tasks;
        conversation = convs;
        filteredTaskAssignments = tasks;
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

  Future<void> _fetchUserIDImage() async {
    try {
      int userId = int.parse(storage.read('user_id').toString());
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
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
                  bottom: MediaQuery.of(context).viewInsets.bottom),
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
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB71A4A),
                                    fontSize: 24,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Please fill in the details below",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.normal,
                                    color: Colors.grey[600],
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
                                    borderSide:
                                        BorderSide(color: Colors.transparent),
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
                                  value == null ? 'Select a User' : null,
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
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.transparent),
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
                                  'Upload Proof (Max 5 images)',
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFF0272B1),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await reportController
                                        .pickImages(modalContext);
                                    setModalState(() {});
                                  },
                                  icon: Icon(Icons.upload_file,
                                      color: Colors.white),
                                  label: Text(
                                    'Upload Images',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF0272B1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
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
                                    height: 120,
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
                                                          height: 80,
                                                          width: 80,
                                                          child: Center(
                                                              child:
                                                                  CircularProgressIndicator()),
                                                        );
                                                      }
                                                      if (snapshot.hasError) {
                                                        return SizedBox(
                                                          height: 80,
                                                          width: 80,
                                                          child: Center(
                                                              child: Text(
                                                                  'Error')),
                                                        );
                                                      }
                                                      return Image.memory(
                                                        snapshot.data!,
                                                        height: 80,
                                                        width: 80,
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
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Text(
                                                'Image ${index + 1}',
                                                style: GoogleFonts.poppins(
                                                    color: Colors.grey[600],
                                                    fontSize: 12),
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
                                borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
                              return;
                            }
                            reportController.validateAndSubmit(
                                context, setModalState, userId, reportedWhom);
                            setState(() {
                              _isModalOpen = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0272B1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: Text(
                            'Submit',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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

  void _showWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          "Account Verification",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "Upload your Profile and ID images to complete your account. Verification will follow.",
          style: GoogleFonts.poppins(fontSize: 14),
        ),
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
                });
                await _fetchUserIDImage();
              } else {
                setState(() {
                  _isUploadDialogShown = false;
                });
              }
            },
            child: Text(
              "Verify Account",
              style: GoogleFonts.poppins(color: Color(0xFF0272B1)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isUploadDialogShown = false;
              });
            },
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
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
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB71A4A),
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: reportController.reportHistory.isEmpty
                    ? Center(
                        child: Text(
                          "No report history available yet.",
                          style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: reportController.reportHistory.length,
                        itemBuilder: (context, index) {
                          final report = reportController.reportHistory[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(12),
                              title: Text(
                                "Report #${report.reportId ?? 'N/A'}",
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0272B1),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Reason: ${report.reason ?? 'No reason provided'}",
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  Text(
                                    "Reported By: ${report.reportedByName ?? 'Unknown'}",
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  Text(
                                    "Reported Whom: ${report.reportedWhomName ?? 'Unknown'}",
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  Text(
                                    "Created At: ${report.createdAt ?? 'N/A'}",
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  Text(
                                    "Status: ${report.status != null ? (report.status! ? 'Resolved' : 'Pending') : 'N/A'}",
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
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
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text(
          "Messages",
          style: GoogleFonts.montserrat(
            color: Color(0xFFB71A4A),
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
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
                    Icon(Icons.report, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Report User', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'report_history',
                child: Row(
                  children: [
                    Icon(Icons.history, color: Color(0xFF0272B1)),
                    SizedBox(width: 8),
                    Text('Report History', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
            icon: Icon(Icons.more_vert, color: Color(0xFFB71A4A)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: conversationController.searchConversation,
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  suffixIcon: Icon(
                    FontAwesomeIcons.magnifyingGlass,
                    color: Color(0xFF0272B1),
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Color(0xFF0272B1)),
                  )
                : taskAssignments.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _fetchTaskAssignments,
                        color: Color(0xFFB71A4A),
                        child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height - 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.commentSlash,
                                    size: 80,
                                    color: Color(0xFF0272B1),
                                  ),
                                  SizedBox(height: 16),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 32),
                                    child: Text(
                                      "No messages yet. Accept a tasker or wait for your task to be accepted.",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchTaskAssignments,
                        color: Color(0xFFB71A4A),
                        child: ListView.builder(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: filteredTaskAssignments.length,
                          itemBuilder: (context, index) {
                            final taskAssignment =
                                filteredTaskAssignments[index];
                            if (taskAssignment == null) {
                              return SizedBox.shrink();
                            }
                            final conversation =
                                this.conversation.firstWhereOrNull(
                                      (conv) =>
                                          conv.taskTakenId ==
                                          taskAssignment.taskTakenId,
                                    );
                            return conversationCard(
                                taskAssignment, conversation);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void showMessageOptions(BuildContext context, int taskTakenId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Conversation',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to delete this conversation? This cannot be undone.',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
              onPressed: () {
                conversationController.deleteMessage(context, taskTakenId);
                Navigator.of(context).pop();
                _fetchTaskAssignments();
              },
            ),
          ],
        );
      },
    );
  }

  Widget conversationCard(
      TaskAssignment taskTaken, Conversation? conversation) {
    final currentUserId = storage.read('user_id');
    final role = storage.read('role');
    final senderId = conversation?.userId ??
        (role == 'Tasker'
            ? taskTaken.client?.user?.id
            : taskTaken.tasker?.user?.id) ??
        0;
    final bool isReceiver = senderId != currentUserId;
    final bool isUnread = taskTaken.unreadCount > 0;
    final user =
        role == 'Tasker' ? taskTaken.client?.user : taskTaken.tasker?.user;
    final timestamp = conversation?.createdAt != null
        ? DateFormat('h:mm a').format(conversation!.createdAt!)
        : '';

    debugPrint("Role: $role");
    debugPrint("Current User ID: $currentUserId");
    debugPrint("Sender ID: $senderId");
    debugPrint("Is Receiver: $isReceiver");
    debugPrint("Is Unread: $isUnread");

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IndividualChatScreen(
                  taskTakenId: taskTaken.taskTakenId,
                  taskId: taskTaken.task?.id ?? 0,
                  taskTitle: taskTaken.task?.title ?? '',
                ),
              ),
            ).then((_) => _fetchTaskAssignments());
          },
          onLongPress: () => showMessageOptions(context, taskTaken.taskTakenId),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFF0272B1),
                      backgroundImage: user?.imageName != null
                          ? CachedNetworkImageProvider(user!.imageName!)
                          : null,
                      child: user?.imageName == null
                          ? Text(
                              user?.firstName.isNotEmpty == true
                                  ? user!.firstName[0]
                                  : 'U',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                    if (isUnread && isReceiver)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Color(0xFFB71A4A),
                          child: Text(
                            taskTaken.unreadCount.toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              taskTaken.task?.title ?? 'No Title',
                              style: GoogleFonts.montserrat(
                                color: Color(0xFF0272B1),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timestamp,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          readIconMarker(
                            isUnread
                                ? FontAwesomeIcons.check
                                : FontAwesomeIcons.checkDouble,
                            isUnread ? Colors.grey : Color(0xFF0272B1),
                          ),
                          Flexible(
                            child: Text(
                              "${user?.firstName ?? ''} ${user?.middleName ?? ''} ${user?.lastName ?? ''}",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isUnread && isReceiver
                                    ? Colors.black87
                                    : Colors.grey[600],
                                fontWeight: isUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (conversation?.conversationMessage != null)
                        Text(
                          conversation!.conversationMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isUnread ? Colors.black54 : Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget readIconMarker(IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: Icon(
        icon,
        color: color,
        size: 14,
      ),
    );
  }
}
