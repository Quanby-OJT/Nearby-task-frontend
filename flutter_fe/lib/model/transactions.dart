import 'package:flutter_fe/model/task_assignment.dart';

class Transactions {
  final TaskAssignment taskAssignment;
  final String recordStatus;
  final String date;

  Transactions({
    required this.taskAssignment,
    required this.recordStatus,
    required this.date,
  });

  factory Transactions.fromJson(Map<String, dynamic> json) {
    return Transactions(
      taskAssignment: TaskAssignment.fromJson(json['task_taken']),
      recordStatus: json['task_status'],
      date: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_taken': taskAssignment.toJson(),
      'task_status': recordStatus,
      'created_at': date,
    };
  }
}
