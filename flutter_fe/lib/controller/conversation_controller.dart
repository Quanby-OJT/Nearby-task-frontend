import 'package:flutter/material.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:get_storage/get_storage.dart';
import '../model/conversation.dart';

class ConversationController {
  final TextEditingController conversationMessage = TextEditingController();
  final storage = GetStorage();

  Future<void> sendMessage(BuildContext context, int taskTaken) async {
    int userId = storage.read('user_id');

    final conversation = Conversation(
        conversationMessage: conversationMessage.text,
        userId: userId,
        taskTakenId: taskTaken);
    Map<String, dynamic> messageSent =
        await ApiService.sendMessage(conversation);

    if (messageSent.containsKey('message')) {
    } else if (messageSent.containsKey('error')) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(messageSent['error'])));
    }
  }

  Future<List<Conversation>?> getMessages(
      BuildContext context, int taskTakenId) async {
    final messages = await ApiService.getMessages(taskTakenId);
    debugPrint(messages.toString());

    if (messages.containsKey("messages")) {
      List<dynamic> message = messages['messages'];
      List<Conversation> conversation = message
          .map((conversation) => Conversation.fromJson(conversation))
          .toList();
      return conversation;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(messages['error'] ??
            "Something Went Wrong while Retrieving Your Tasks.")));

    return null;
  }
}
