import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/model/address.dart';
import 'package:flutter_fe/model/task_model.dart';

class TaskFetch {
  final int taskTakenId;
  final int id;
  final String taskStatus;
  final DateTime? createdAt;
  final int? clientId;
  final int? taskerId;
  final TaskModel taskDetails;
  final AddressModel? address;
  final ClientModel? client;

  TaskFetch({
    required this.taskTakenId,
    required this.id,
    required this.taskStatus,
    this.createdAt,
    this.clientId,
    this.taskerId,
    required this.taskDetails,
    this.client,
    this.address,
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
      'client': client?.toJson(),
      'address': address?.toJson(),
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
      client: json['client'] != null && json['client']['user'] != null
          ? ClientModel.fromJson({
              'preferences': '',
              'client_address': json['client']['client_address'] ?? '',
              'user': json['client']['user'],
            })
          : null,
      address: json['address'] != null
          ? AddressModel.fromJson(json['address'])
          : null,
    );
  }

  @override
  String toString() {
    return 'TaskModel(taskTakenId: $taskTakenId, id: $id, taskStatus: $taskStatus, createdAt: $createdAt, clientId: $clientId, taskerId: $taskerId, taskDetails: $taskDetails, client: $client, address: $address)';
  }
}
