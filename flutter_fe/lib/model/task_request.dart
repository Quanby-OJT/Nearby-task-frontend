import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/user_model.dart';

class TaskRequest {
  final int? requestId;
  final TaskModel task;
  final UserModel client;
  final UserModel tasker;
  final String status; // 'pending', 'accepted', 'declined'
  final String? createdAt;

  TaskRequest({
    this.requestId,
    required this.task,
    required this.client,
    required this.tasker,
    required this.status,
    this.createdAt,
  });

  factory TaskRequest.fromJson(Map<String, dynamic> json) {
    return TaskRequest(
      requestId: json['request_id'] as int?,
      task: TaskModel.fromJson(json['task']),
      client: UserModel.fromJson(json['client']),
      tasker: UserModel.fromJson(json['tasker']),
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'task_id': task.id,
      'client_id': client.id,
      'tasker_id': tasker.id,
      'status': status,
      'created_at': createdAt,
    };
  }

  TaskRequest copyWith({
    int? requestId,
    TaskModel? task,
    UserModel? client,
    UserModel? tasker,
    String? status,
    String? createdAt,
  }) {
    return TaskRequest(
      requestId: requestId ?? this.requestId,
      task: task ?? this.task,
      client: client ?? this.client,
      tasker: tasker ?? this.tasker,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
