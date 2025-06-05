import 'package:flutter_fe/model/address.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/tasker_model.dart';

class TaskFetch {
  final int taskTakenId;
  final int id;
  final String taskStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? clientId;
  final int? taskerId;
  final TaskModel? taskDetails;
  final AddressModel? address;
  final int? timeRequest;
  final DateTime? startDate;
  final DateTime? endDate;
  final TaskerModel? tasker;
  final TaskModel? post_task;

  TaskFetch({
    required this.taskTakenId,
    required this.id,
    required this.taskStatus,
    this.createdAt,
    this.updatedAt,
    this.clientId,
    this.taskerId,
    this.taskDetails,
    this.address,
    this.timeRequest,
    this.startDate,
    this.endDate,
    this.tasker,
    this.post_task,
  });

  Map<String, dynamic> toJson() {
    return {
      'task_taken_id': taskTakenId,
      'task_id': id,
      'task_status': taskStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'client_id': clientId,
      'tasker_id': taskerId,
      'task': taskDetails?.toJson(),
      'address': address?.toJson(),
      'time_request': timeRequest,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'tasker': tasker?.toJson(),
      'post_task': post_task?.toJson(),
    };
  }

  factory TaskFetch.fromJson(Map<String, dynamic> json) {
    return TaskFetch(
      taskTakenId: json['task_taken_id'] as int,
      id: json['task_id'] as int,
      taskStatus: json['task_status'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      clientId: json['client_id'] as int?,
      taskerId: json['tasker_id'] as int?,
      taskDetails: json['task'] != null
          ? TaskModel.fromJson(json['task'] as Map<String, dynamic>)
          : null,
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
      tasker: json['tasker'] != null
          ? TaskerModel.fromJson(json['tasker'] as Map<String, dynamic>)
          : null,
      post_task: json['post_task'] != null
          ? TaskModel.fromJson(json['post_task'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return 'TaskFetch(taskTakenId: $taskTakenId, id: $id, taskStatus: $taskStatus, '
        'createdAt: $createdAt, updatedAt: $updatedAt, clientId: $clientId, taskerId: $taskerId, '
        'taskDetails: $taskDetails, address: $address, timeRequest: $timeRequest, '
        'startDate: $startDate, endDate: $endDate, tasker: $tasker, post_task: $post_task)';
  }
}
