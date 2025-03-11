import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/model/client_model.dart';

class TaskAssignment{
  final ClientModel client;
  final TaskerModel tasker;
  final TaskModel task;

  TaskAssignment({
    required this.client,
    required this.tasker,
    required this.task,
  });

  @override
  String toString() {
    return "TaskAssignment(client: $client, tasker: $tasker, task: $task)";
  }
}