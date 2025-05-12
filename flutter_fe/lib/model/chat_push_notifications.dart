import 'package:flutter_fe/model/task_assignment.dart';

import 'conversation.dart';

class TaskAndConversationResult {
  final List<TaskAssignment> taskAssignments;
  final List<Conversation> conversations;

  TaskAndConversationResult({
    required this.taskAssignments,
    required this.conversations,
  });
}