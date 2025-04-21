import 'package:flutter_fe/model/tasker_model.dart';

class TaskerFeedback{
  final TaskerModel tasker;
  final double rating;
  final String comment;
  final DateTime timestamp;

  TaskerFeedback({
    required this.tasker,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  factory TaskerFeedback.fromJson(Map<String, dynamic> json) {
    return TaskerFeedback(
      tasker: TaskerModel.fromJson(json['tasker']),
      rating: json['rating'],
      comment: json['feedback'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}