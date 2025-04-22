import 'package:flutter_fe/model/client_model.dart';

class TaskerFeedback{
  final ClientModel client;
  final double rating;
  final String comment;

  TaskerFeedback({
    required this.client,
    required this.rating,
    required this.comment,
  });

  factory TaskerFeedback.fromJson(Map<String, dynamic> json) {
    return TaskerFeedback(
      client: ClientModel.fromJson(json['task_taken']['clients']),
      rating: json['rating'].toDouble(),
      comment: json['feedback'],
    );
  }
}