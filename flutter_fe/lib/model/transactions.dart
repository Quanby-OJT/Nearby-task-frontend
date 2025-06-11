import 'package:flutter_fe/model/task_assignment.dart';

class Transactions{
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
      taskAssignment: json['task_taken'] != null ? TaskAssignment.fromJson(json['task_taken']) : TaskAssignment(taskTakenId: 0, taskStatus: ""),
      recordStatus: json['task_status'],
      date: json['created_at'],
    );
  }
}