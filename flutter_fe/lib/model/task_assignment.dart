import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/model/client_model.dart';

class TaskAssignment{
  final ClientModel client;
  final TaskerModel tasker;
  final TaskModel task;
  final int? taskTakenId;
  final String taskStatus;

  TaskAssignment({
    required this.client,
    required this.tasker,
    required this.task,
    this.taskTakenId,
    required this.taskStatus
  });

  @override
  String toString() {
    return "TaskAssignment(client: $client, tasker: $tasker, task: $task)";
  }

  factory TaskAssignment.fromJson(Map<String, dynamic> json){
    return TaskAssignment(
      client: ClientModel.fromJson(json['client']),
      tasker: TaskerModel.fromJson(json['tasker']),
      task: TaskModel.fromJson(json['post_task']),
      taskStatus: json['task_status'],
      taskTakenId: json['task_taken_id']
    );
  }
}