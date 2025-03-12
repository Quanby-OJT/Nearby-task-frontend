import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final int? taskTakenId;
  const ChatScreen({super.key, this.taskTakenId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<String> messages = [];
  List conversations = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          // automaticallyImplyLeading: false,
          title: Center(
              child: Text("NearByTask Conversation",
                  style: TextStyle(
                      color: Color(0xFF0272B1),
                      fontWeight: FontWeight.bold,
                      fontSize: 24))),
        ),
        body: messages.isEmpty
            ? Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Centers vertically
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // Centers horizontally
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
                    ],
                  ),
                ),
              )
            : Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = conversations[
                        index]; // Use messages instead of conversations
                    return ListTile(
                      title: Text(
                        message.taskTakenId.toString() ?? "Unknown Task",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "📍 ${message.userId} \n • 🛠 ${message.conversationMessage}",
                        style: TextStyle(fontSize: 14),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                      onTap: () {
                        // Open task details (if needed)
                      },
                    );
                  },
                ),
              ));
  }
}
