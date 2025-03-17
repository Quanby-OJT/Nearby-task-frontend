import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/conversation.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/controller/conversation_controller.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/chat/complain/complain.dart';
import 'package:get_storage/get_storage.dart';

class IndividualChatScreen extends StatefulWidget {
  final String? taskTitle;
  final int? taskTakenId;
  const IndividualChatScreen({super.key, this.taskTitle, this.taskTakenId});

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
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      loadConversationHistory();
    });
  }

  Future<void> loadInitialData() async {
    task = await jobPostService.fetchTaskInformation(widget.taskTakenId ?? 0);
    await loadConversationHistory();
  }

  Future<void> loadConversationHistory() async {
    debugPrint(widget.taskTitle.toString() + widget.taskTakenId.toString());
    final messages =
        await conversationController.getMessages(context, widget.taskTakenId);
    setState(() {
      _messages.clear();
      _messages.addAll(messages);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskTitle ?? "Please Wait..."),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message,
                          size: 100,
                          color: const Color(0xFF0272B1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            "You Don't Have Messages Yet, You can Start a Conversation By Sending Your First Message to your Client.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(
                            height: 20), // Spacing between text and button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, // Visible background
                            foregroundColor: Colors.white, // Text/icon color
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ComplainScreen(),
                              ),
                            );
                          },
                          child: const Text("Go to Complain"),
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
                              firstName: 'Unknown',
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
    bool isMine = message.userId == GetStorage().read('userId');

    List<Widget> chatContents = [
      if (!isMine)
        CircleAvatar(
          child: Text(profile.firstName.substring(0, 2)),
        ),
      const SizedBox(width: 12),
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isMine ? Theme.of(context).primaryColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(message.conversationMessage ?? ''),
        ),
      ),
      const SizedBox(width: 12),
    ];

    if (isMine) {
      chatContents = chatContents.reversed.toList();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: chatContents,
      ),
    );
  }
}
