import 'package:flutter_fe/model/address.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/tasker_model.dart';

class TaskClientFetch {
  final int taskTakenId;
  final int id;
  final String taskStatus;
  final DateTime? createdAt;
  final int? clientId;
  final int? taskerId;
  final AddressModel? address;
  final int? timeRequest;
  final DateTime? startDate;
  final DateTime? endDate;
  final TaskModel? post_task;
  final TaskerModel? tasker;

  TaskClientFetch({
    required this.taskTakenId,
    required this.id,
    required this.taskStatus,
    this.createdAt,
    this.clientId,
    this.taskerId,
    this.address,
    this.timeRequest,
    this.startDate,
    this.endDate,
    this.post_task,
    this.tasker,
  });

  Map<String, dynamic> toJson() {
    return {
      'task_taken_id': taskTakenId,
      'task_id': id,
      'task_status': taskStatus,
      'created_at': createdAt?.toIso8601String(),
      'client_id': clientId,
      'tasker_id': taskerId,
      'address': address?.toJson(),
      'time_request': timeRequest,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'post_task': post_task?.toJson(),
      'tasker': tasker?.toJson(),
    };
  }

  factory TaskClientFetch.fromJson(Map<String, dynamic> json) {
    return TaskClientFetch(
      taskTakenId: json['task_taken_id'] as int,
      id: json['task_id'] as int,
      taskStatus: json['task_status'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      clientId: json['client_id'] as int?,
      taskerId: json['tasker_id'] as int?,
      address: json['task']?['address'] != null
          ? AddressModel.fromJson(
              json['task']['address'] as Map<String, dynamic>)
          : null,
      timeRequest: json['task']?['time_request'] as int?,
      startDate: json['task']?['start_date'] != null
          ? DateTime.parse(json['task']['start_date'] as String)
          : null,
      endDate: json['task']?['end_date'] != null
          ? DateTime.parse(json['task']['end_date'] as String)
          : null,
      post_task: json['post_task'] != null
          ? TaskModel.fromJson(json['post_task'] as Map<String, dynamic>)
          : null,
      tasker: json['tasker'] != null
          ? TaskerModel.fromJson(json['tasker'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return 'TaskFetch(taskTakenId: $taskTakenId, id: $id, taskStatus: $taskStatus, '
        'createdAt: $createdAt, clientId: $clientId, taskerId: $taskerId, '
        'address: $address, timeRequest: $timeRequest, '
        'startDate: $startDate, endDate: $endDate, post_task: $post_task,tasker: $tasker,)';
  }
}
