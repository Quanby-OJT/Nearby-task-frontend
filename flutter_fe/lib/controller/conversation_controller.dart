import 'package:flutter/material.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:flutter_fe/service/task_information.dart';
import 'package:get_storage/get_storage.dart';
import '../model/conversation.dart';

class ConversationController {
  final TextEditingController conversationMessage = TextEditingController();
  final TextEditingController searchConversation = TextEditingController();
  final storage = GetStorage();

  Future<void> sendMessage(BuildContext context, int taskTaken) async {
    int userId = await storage.read('user_id');
    debugPrint("Sending a Message with the Following Data: \n User ID: $userId \n Task Taken ID: $taskTaken");

    final conversation = Conversation(
      conversationMessage: conversationMessage.text,
      userId: userId,
      taskTakenId: taskTaken,
    );

    debugPrint("Sending Message for Task Taken ID of: $taskTaken");
    debugPrint("User ID: $userId");
    debugPrint("Conversation Message: ${conversationMessage.text}");
    Map<String, dynamic> messageSent =
        await ApiService.sendMessage(conversation);
//     Map<String, dynamic> messageSent = await TaskDetailsService.sendMessage(conversation);

    if (messageSent.containsKey('message')) {
      // Optionally notify success if needed
    } else if (messageSent.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageSent['error'])),
      );
    }
  }

  Future<List<Conversation>> getMessages(
      BuildContext context, int taskTakenId) async {
    debugPrint(taskTakenId.toString());
    final messages = await TaskDetailsService.getMessages(taskTakenId);
    //debugPrint(messages.toString());

    if (messages.containsKey("data")) {
      // Expecting a list of conversations from the API
      List<dynamic> messageList = messages['data'];
      List<Conversation> conversations = messageList
          .map((conversation) => Conversation.fromJson(conversation))
          .toList();
      return conversations;
    } else if (messages.isEmpty) {
      return []; // Return empty list if no messages
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messages['error'] ??
              "Something went wrong while retrieving your messages."),
        ),
      );
      return []; // Return empty list on error
    }
  }

  Future<void> deleteMessage(BuildContext context, int messageId) async {
    final messageDeleted = await TaskDetailsService.deleteMessage(messageId);
    if (messageDeleted.containsKey('message')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageDeleted['message'])),
      );
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageDeleted['error'])),
      );
    }
  }

  void dispose() {
    conversationMessage.dispose();
  }
}
