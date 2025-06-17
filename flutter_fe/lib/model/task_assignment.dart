import 'package:flutter/cupertino.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/model/client_model.dart';

class TaskAssignment {
  final ClientModel? client;
  final TaskerModel? tasker;
  final TaskModel? task;
  final int taskTakenId;
  final String taskStatus;
  final String? taskStatusReason;
  int unreadCount;
  int messageSentById;
  int rework;

  TaskAssignment({
    this.client,
    this.tasker,
    this.task,
    required this.taskTakenId,
    required this.taskStatus,
    this.taskStatusReason,
    this.unreadCount = 0,
    this.messageSentById = 0,
    this.rework = 0,
  });

  @override
  String toString() {
    return "TaskAssignment(client: $client, tasker: $tasker, task: $task)";
  }

  factory TaskAssignment.fromJson(Map<String, dynamic> json) {
    debugPrint('Tasker JSON Data: ${json['tasker']}');
    return TaskAssignment(
      client: json['clients'] != null
          ? ClientModel.fromJson(json['clients'])
          : null,
      tasker:
          json['tasker'] != null ? TaskerModel.fromJson(json['tasker']) : null,
      task: json['post_task'] != null
          ? TaskModel.fromJson(json['post_task'])
          : null,
      taskStatus: json['task_status'],
      taskTakenId: json['task_taken_id'],
      taskStatusReason: json['reason_for_rejection_or_cancellation'],
      unreadCount: json['unread_count'] ?? 0,
      messageSentById: json['last_message_id'] ?? 0,
      rework: json['rework_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clients': client?.toJson(),
      'tasker': tasker?.toJson(),
      'post_task': task?.toJson(),
      'task_status': taskStatus,
      'task_taken_id': taskTakenId,
      'reason_for_rejection_or_cancellation': taskStatusReason,
      'unread_count': unreadCount,
      'last_message_id': messageSentById,
      'rework_count': rework,
    };
  }
}
