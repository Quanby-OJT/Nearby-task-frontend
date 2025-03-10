class Conversation {
  final String conversationMessage;
  final int taskTakenId;
  final int userId;

  Conversation(
      {required this.conversationMessage,
      required this.taskTakenId,
      required this.userId});

  Map<String, dynamic> toJson() {
    return {
      "task_taken_id": taskTakenId,
      "conversation": conversationMessage,
      "user_id": userId
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      userId: json['user_id'] as int,
      conversationMessage: json['conversation'] as String,
      taskTakenId: json['task_taken_id'] as int,
    );
  }
}
