import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/conversation.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/controller/conversation_controller.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/address/user_shared_location.dart';
import 'package:flutter_fe/view/chat/task_details_screen.dart';
import 'package:flutter_fe/view/profile/profile_screen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IndividualChatScreen extends StatefulWidget {
  final String? taskTitle;
  final int? taskTakenId;
  final int? taskId;
  final UserModel? user;

  const IndividualChatScreen({
    super.key,
    this.taskTitle,
    this.taskTakenId,
    this.taskId,
    this.user,
  });

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final List<Conversation> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _moreVertKey = GlobalKey();
  bool _isLocationShared = false;
  final storage = GetStorage();
  final ConversationController conversationController =
      ConversationController();
  final JobPostService jobPostService = JobPostService();
  TaskModel? task;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadInitialData();
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      loadConversationHistory();
    });
    // Scroll to bottom when new messages are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    final task =
        await jobPostService.fetchTaskInformation(widget.taskTakenId ?? 0);
    setState(() {
      this.task = task.task;
    });
    await loadConversationHistory();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> loadConversationHistory() async {
    final messages = await conversationController.getMessages(
        context, widget.taskTakenId ?? 0);
    setState(() {
      _messages.clear();
      _messages.addAll(messages);
    });
    // Scroll to bottom after loading new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _showAnimatedMenu(BuildContext context) {
    final RenderBox renderBox =
        _moreVertKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    final double menuWidth = screenWidth / 1.5;
    final double leftPosition =
        position.dx + renderBox.size.width - menuWidth - 10;
    final double topPosition = position.dy + renderBox.size.height;

    final double adjustedLeft = leftPosition < 0
        ? 0
        : leftPosition + menuWidth > screenWidth
            ? screenWidth - menuWidth
            : leftPosition;

    OverlayState overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                overlayEntry.remove();
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            left: adjustedLeft,
            top: topPosition,
            width: menuWidth,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildListTile(
                      Icons.location_on,
                      "View Location",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UserSharedLocation(
                                    taskTakenId: widget.taskTakenId ?? 0,
                                    user: widget.user ??
                                        UserModel(
                                          firstName: '',
                                          middleName: '',
                                          lastName: '',
                                          email: '',
                                          role: '',
                                          accStatus: '',
                                        ),
                                  )),
                        );
                        overlayEntry.remove();
                      },
                    ),
                    buildListTile(
                      Icons.info_outline,
                      "Task Details",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TaskDetailsScreen(
                                    taskTakenId: widget.taskTakenId ?? 0,
                                  )),
                        );
                        overlayEntry.remove();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlayState.insert(overlayEntry);
  }

  Widget buildListTile(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFFB71A4A),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        ),
        onTap: onTap);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.taskTitle ?? "Please Wait...",
                style: GoogleFonts.poppins(
                  color: Color(0xFFB71A4A),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[100],
        elevation: 1,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFB71A4A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            key: _moreVertKey,
            icon: Icon(
              Icons.more_horiz,
              color: Color(0xFFB71A4A),
            ),
            onPressed: () {
              _showAnimatedMenu(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB71A4A),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 60,
                                color: Color(0xFF0272B1),
                              ),
                              SizedBox(height: 16),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  "Start the conversation with your client!",
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
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                ),
              ],
            ),
    );
  }
}

class _MessageBar extends StatelessWidget {
  final ConversationController controller;
  final int taskTakenId;
  final VoidCallback onMessageSent;

  const _MessageBar({
    required this.controller,
    required this.taskTakenId,
    required this.onMessageSent,
  });

  void _submitMessage(BuildContext context) {
    if (controller.conversationMessage.text.trim().isEmpty) return;
    controller.sendMessage(context, taskTakenId).then((_) {
      controller.conversationMessage.clear();
      onMessageSent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextFormField(
                    controller: controller.conversationMessage,
                    keyboardType: TextInputType.multiline,
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Material(
                color: Color(0xFFB71A4A),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _submitMessage(context),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
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
    bool isMine = message.userId == GetStorage().read('user_id');
    final timestamp = message.createdAt != null
        ? DateFormat('h:mm a').format(message.createdAt!)
        : '';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.75, // Limit bubble width
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine) ...[
              Padding(
                padding: EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  profile.firstName.isNotEmpty
                      ? '${profile.firstName} ${profile.middleName} ${profile.lastName}'
                      : 'User',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            Row(
              mainAxisAlignment:
                  isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMine)
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF0272B1),
                    child: Text(
                      profile.firstName.isNotEmpty ? profile.firstName[0] : 'U',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (!isMine) SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isMine ? Color(0xFFB71A4A) : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft:
                            isMine ? Radius.circular(16) : Radius.circular(4),
                        bottomRight:
                            isMine ? Radius.circular(4) : Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      message.conversationMessage ?? '',
                      style: GoogleFonts.poppins(
                        color: isMine ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                timestamp,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
