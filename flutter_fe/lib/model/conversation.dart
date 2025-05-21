import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:intl/intl.dart';

class Conversation {
  final UserModel? user;
  final TaskAssignment? taskTaken;
  final String? conversationMessage;
  final int? userId;
  final int? taskTakenId;
  final DateTime? createdAt;

  Conversation({
    this.user,
    this.conversationMessage,
    this.taskTaken,
    this.userId,
    this.taskTakenId,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      "conversation": conversationMessage,
      "user_id": userId,
      "task_taken_id": taskTakenId,
      "created_at": createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return "Conversation(user: $user, taskTaken: $taskTaken, conversationMessage: $conversationMessage, taskTakenId: $taskTakenId, userId: $userId, createdAt: $createdAt)";
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      try {
        final today = DateTime.now();
        final parsedTime = DateFormat('h:mm a').parse(json['created_at']);
        parsedCreatedAt = DateTime(
          today.year,
          today.month,
          today.day,
          parsedTime.hour,
          parsedTime.minute,
        );
      } catch (e) {
        try {
          parsedCreatedAt = DateTime.parse(json['created_at']);
        } catch (_) {
          parsedCreatedAt = null;
        }
      }
    }

    return Conversation(
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      userId: json['user_id'],
      taskTaken: json['task_taken'] != null
          ? TaskAssignment.fromJson(json['task_taken'])
          : null,
      taskTakenId: json['task_taken_id'],
      conversationMessage: json['conversation'],
      createdAt: parsedCreatedAt,
    );
  }
}
