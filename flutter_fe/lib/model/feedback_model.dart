import 'package:flutter_fe/model/task_assignment.dart';

class TaskerFeedback{
  final TaskAssignment taskAssignment;
  final double rating;
  final String comment;

  TaskerFeedback({
    required this.taskAssignment,
    required this.rating,
    required this.comment,
  });

  factory TaskerFeedback.fromJson(Map<String, dynamic> json) {
    return TaskerFeedback(
      taskAssignment: TaskAssignment.fromJson(json['taskAssignment']),
      rating: json['rating'].toDouble(),
      comment: json['comment'],
    );
  }
}