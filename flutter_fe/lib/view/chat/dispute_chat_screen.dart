import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/conversation.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/controller/conversation_controller.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/chat/task_details_screen.dart';
import 'package:get_storage/get_storage.dart';

class IndividualChatScreen extends StatefulWidget {
  final String? taskTitle;
  final int? taskTakenId;
  final int? taskId;
  const IndividualChatScreen(
      {super.key,
      this.taskTitle,
      required this.taskTakenId,
      required this.taskId});

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final List<Conversation> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final storage = GetStorage();
  final ConversationController conversationController =
      ConversationController();
  final JobPostService jobPostService = JobPostService();
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
      this.task = task.task;
    });
    await loadConversationHistory();
  }

  Future<void> loadConversationHistory() async {
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
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB71A4A)),
                    overflow: TextOverflow.ellipsis, // Prevents text overflow
                  ),
                ],
              ),
            ),
            // Right side with icons
            Row(
              mainAxisSize: MainAxisSize.min, // Keeps icons tightly packed
              children: [
                IconButton(
                  icon: Icon(Icons.info_outline, color: Color(0xFFB71A4A)),

                  ///
                  /// NOTE: When retrieving task information, task_id must be used to retrieve task information
                  ///
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
                          color: Color(0xFFB71A4A),
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
    if (controller.conversationMessage.text.isEmpty) return;

    controller.sendMessage(context, taskTakenId).then((_) {
      controller.conversationMessage.clear();
      onMessageSent();
    });
  }

  //Text Form Field
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[200],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
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
    // Determine if the message is from the current user
    bool isMine = message.userId == GetStorage().read('user_id');
    //debugPrint(isMine.toString());

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
