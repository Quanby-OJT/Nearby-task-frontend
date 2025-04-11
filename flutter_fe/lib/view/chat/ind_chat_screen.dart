import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/conversation.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/controller/conversation_controller.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/chat/task_details_screen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_fe/controller/report_controller.dart';

class IndividualChatScreen extends StatefulWidget {
  final String? taskTitle;
  // Selected user Start, it links to the selected user
  final int? taskTakenId;
  // Selected user End
  final int? taskId;
  const IndividualChatScreen({
    super.key,
    this.taskTitle,
    required this.taskTakenId,
    required this.taskId,
  });

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final List<Conversation> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // Logged In UserId Start
  final storage = GetStorage();
  // Logged In UserId End
  final ConversationController conversationController =
      ConversationController();
  final JobPostService jobPostService = JobPostService();
  final ReportController reportController = ReportController();
  TaskModel? task;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    loadInitialData();
    // Poll for new messages every 5 seconds
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      loadConversationHistory();
    });
  }

  Future<void> loadInitialData() async {
    final task =
        await jobPostService.fetchTaskInformation(widget.taskTakenId ?? 0);
    setState(() {
      // Selected User Start
      this.task = task?.task;

      // Selected User End
    });
    await loadConversationHistory();
  }

  Future<void> loadConversationHistory() async {
    debugPrint('Loading messages for taskTakenId: ${widget.taskTakenId}');
    //debugPrint(widget.taskTitle.toString() + " | Task Taken ID: " + widget.taskTakenId.toString());
    final messages = await conversationController.getMessages(
        context, widget.taskTakenId ?? 0);
    setState(() {
      _messages.clear();
      _messages
          .addAll(messages); // No type error: messages is List<Conversation>
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  //Main Screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side with flexible width
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.taskTitle ?? "Please Wait...",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Combined Info and Report Icons aligned to the right
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // (1) Info Icon (unchanged)
                IconButton(
                  icon: Icon(Icons.info_outline, color: Color(0xFF0272B1)),
                  onPressed: () {
                    debugPrint(widget.taskTakenId.toString());
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailsScreen(
                          taskTakenId: widget.taskTakenId ?? 0,
                        ),
                      ),
                    );
                  },
                ),
                // (2) Report Icon (updated)
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    bool _isHovering = false;

                    return ClipOval(
                      child: Material(
                        child: InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () {},
                          onHover: (isHovering) {
                            setState(() {
                              _isHovering = isHovering;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white
                                      .withOpacity(_isHovering ? 0.4 : 0.2),
                                  blurRadius: _isHovering ? 0 : 6,
                                  spreadRadius: _isHovering ? 2 : 0,
                                  offset:
                                      _isHovering ? Offset(0, 0) : Offset(0, 3),
                                ),
                              ],
                            ),
                            child: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'report_user') {
                                  _showReportModal(context);
                                } else if (value == 'report_history') {
                                  _showReportHistoryModal(context);
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
                                      Icon(Icons.history, color: Colors.green),
                                      SizedBox(width: 10),
                                      Text('Report History'),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.flag_outlined,
                                  color: Color(0xFFFF0000),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
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
                            "You Don't Have Messages Yet, You can Start a Conversation By Sending Your First Message to your Client.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: false,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _ChatBubble(
                        message: message,
                        profile: message.user ??
                            UserModel(
                              firstName:
                                  message.user?.firstName ?? "Loading...",
                              middleName: '',
                              lastName: '',
                              email: '',
                              role: '',
                              accStatus: '',
                            ),
                      );
                    },
                  ),
          ),
          _MessageBar(
            controller: conversationController,
            taskTakenId: widget.taskTakenId ?? 0,
            onMessageSent: loadConversationHistory,
            selectedImages: reportController.selectedImages,
            imageUploadError: reportController.imageUploadError,
            onPickImages: () => reportController.pickImages(context),
            onRemoveImage: reportController.removeImage,
          ),
        ],
      ),
    );
  }

  void _showReportModal(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
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
                            child: TextField(
                              controller: reasonController,
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
                                        return FutureBuilder<Uint8List>(
                                          future: reportController
                                              .selectedImages[index]
                                              .readAsBytes(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
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
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 10),
                                              child: Column(
                                                children: [
                                                  Stack(
                                                    children: [
                                                      Image.memory(
                                                        snapshot.data!,
                                                        height: 100,
                                                        width: 100,
                                                        fit: BoxFit.cover,
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
                                                              color:
                                                                  Colors.white,
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
                            // Simulate report submission without backend
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Report submitted: ${reasonController.text}')),
                            );
                            Navigator.pop(context);
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

  void _showReportHistoryModal(BuildContext context) {
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
                child: Center(
                  child: Text(
                    "No report history available yet.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
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
}

class _MessageBar extends StatelessWidget {
  final ConversationController controller;
  final int taskTakenId;
  final VoidCallback onMessageSent;
  final List<XFile> selectedImages;
  final String? imageUploadError;
  final VoidCallback onPickImages;
  final Function(int) onRemoveImage;

  const _MessageBar({
    required this.controller,
    required this.taskTakenId,
    required this.onMessageSent,
    required this.selectedImages,
    required this.imageUploadError,
    required this.onPickImages,
    required this.onRemoveImage,
  });

  void _submitMessage(BuildContext context) {
    if (controller.conversationMessage.text.isEmpty) return;

    controller.sendMessage(context, taskTakenId).then((_) {
      controller.conversationMessage.clear();
      onMessageSent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[200],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file),
                onPressed: onPickImages,
              ),
              Expanded(
                child: TextFormField(
                  controller: controller.conversationMessage,
                  keyboardType: TextInputType.text,
                  maxLines: null,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _submitMessage(context),
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Conversation message;
  final UserModel profile;

  const _ChatBubble({required this.message, required this.profile});

  @override
  Widget build(BuildContext context) {
    // Logged In UserId Start
    // Store the other user id and logged in user id in a variable
    final selectedUserId = message.userId;
    final loggedinUserId = GetStorage().read('user_id');

    debugPrint("----------Start----------");
    debugPrint("Selected User Id: $selectedUserId");
    debugPrint("Logged In User Id: $loggedinUserId");
    debugPrint("-----------End-----------");
    // Determine if the message is from the current user
    bool isMine = selectedUserId == loggedinUserId;
    // Logged In UserId End
    //debugPrint(isMine.toString());
    // debugPrint('Message userId: $selectedUserId, Logged-in userId: $loggedinUserId');
    // Define the message bubble widget (used in both cases)
    Widget messageBubble = Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isMine ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message.conversationMessage ?? '',
          style: TextStyle(
            color: isMine ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );

    // Return different layouts based on whether the message is from the current user
    if (isMine) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            messageBubble,
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Text(profile.firstName.isNotEmpty
                  ? profile.firstName
                      .substring(0, profile.firstName.length > 1 ? 2 : 1)
                  : 'U'),
            ),
            const SizedBox(width: 12),
            messageBubble,
          ],
        ),
      );
    }
  }
}
