import 'package:flutter_fe/model/address.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/tasker_model.dart';

class TaskFetch {
  final int taskTakenId;
  final int id;
  final String taskStatus;
  final DateTime? createdAt;
  final int? clientId;
  final int? taskerId;
  final TaskModel taskDetails;
  final AddressModel? address;
  final int? time_request;
  final DateTime? start_date;
  final DateTime? end_date;
  final TaskerModel? tasker;

  TaskFetch({
    required this.taskTakenId,
    required this.id,
    required this.taskStatus,
    this.createdAt,
    this.clientId,
    this.taskerId,
    required this.taskDetails,
    this.address,
    this.time_request,
    this.start_date,
    this.end_date,
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
      'task': taskDetails.toJson(),
      'address': address?.toJson(),
      'time_request': time_request,
      'start_date': start_date?.toIso8601String(),
      'end_date': end_date?.toIso8601String(),
      'tasker': tasker?.toJson(),
    };
  }

  factory TaskFetch.fromJson(Map<String, dynamic> json) {
    return TaskFetch(
      taskTakenId: json['task_taken_id'] as int,
      id: json['task_id'] as int,
      taskStatus: json['task_status'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      clientId: json['client_id'] as int?,
      taskerId: json['tasker_id'] as int?,
      taskDetails: TaskModel.fromJson(json['task'] as Map<String, dynamic>),
      address: json['address'] != null
          ? AddressModel.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      time_request: json['time_request'] as int?,
      start_date: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      end_date:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      tasker: json['tasker'] != null
          ? TaskerModel.fromJson(json['tasker'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return 'TaskFetch(taskTakenId: $taskTakenId, id: $id, taskStatus: $taskStatus, createdAt: $createdAt, clientId: $clientId, taskerId: $taskerId, taskDetails: $taskDetails, address: $address, time_request: $time_request, start_date: $start_date, end_date: $end_date, tasker: $tasker)';
  }
}
