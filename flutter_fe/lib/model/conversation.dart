class Conversation {
  final int userId;
  final int taskTakenId;
  final String conversationMessage;

  Conversation({
    required this.userId,
    required this.conversationMessage,
    required this.taskTakenId
  });

  Map<String, dynamic> toJson() {
    return {
      "conversation": conversationMessage,
      "user_id": userId,
      "task_taken_id": taskTakenId
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
        userId: json['user_id'],
        taskTakenId: json['task_taken_id'],
        conversationMessage: json['conversation'],
    );
  }
}