import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/model/user_model.dart';

class Conversation {
  final UserModel? user;
  final TaskAssignment? taskTaken;
  final String? conversationMessage;
  final int? userId;
  final int? taskTakenId;

  Conversation({
    this.user,
    this.conversationMessage,
    this.taskTaken,
    this.userId,
    this.taskTakenId
  });

  Map<String, dynamic> toJson() {
    return {
      "conversation": conversationMessage,
      "user_id": userId,
      "task_taken_id": taskTakenId
    };
  }

  @override
  String toString() {
    return "Conversation(user: $user, taskTaken: $taskTaken, conversationMessage: $conversationMessage, taskTakenId: $taskTakenId, userId: $userId)";
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
        user: json['user'],
        userId: json['user_id'],
        taskTaken: json['task_taken'],
        conversationMessage: json['conversation'],
    );
  }
}