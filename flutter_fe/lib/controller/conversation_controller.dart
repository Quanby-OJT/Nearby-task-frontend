import 'package:flutter/cupertino.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:get_storage/get_storage.dart';
import '../model/conversation.dart';

class ConversationController{
  final TextEditingController conversationMessage = TextEditingController();
  final storage = GetStorage();

  Future<void> sendMessage(BuildContext context, int taskTaken) async{
    int userId = storage.read('user_id');

    final conversation = Conversation(
        conversationMessage: conversationMessage.text,
        userId: userId,
        taskTakenId: taskTaken
    );
    Map<String, dynamic> messageSent = await ApiService.sendMessage(conversation);

    if(messageSent.containsKey('message')){

    }else if(messageSent.containsKey('error')){

    }
  }
}