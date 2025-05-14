import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/model/address.dart';

class TaskFetch {
  final int id;
  final String taskStatus;
  final DateTime? createdAt;
  final int? clientId;
  final int? taskerId;
  final TaskDetails taskDetails;
  final ClientModel? client;
  final AddressModel? address;

  TaskFetch({
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
      id: json['task_id'] as int,
      taskStatus: json['task_status'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      clientId: json['client_id'] as int?,
      taskerId: json['tasker_id'] as int?,
      taskDetails: TaskDetails.fromJson(json['task'] as Map<String, dynamic>),
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
    return 'TaskModel(id: $id, taskStatus: $taskStatus, createdAt: $createdAt, clientId: $clientId, taskerId: $taskerId, taskDetails: $taskDetails, client: $client, address: $address)';
  }
}

class TaskDetails {
  final String status;
  final String urgency;
  final int taskId;
  final String duration;
  final String location;
  final String title;
  final int proposedPrice;
  final String specialization;
  final String description;
  final String? period;
  final String? taskBeginDate;
  final String? workType;
  final String? remarks;

  TaskDetails({
    required this.status,
    required this.urgency,
    required this.taskId,
    required this.duration,
    required this.location,
    required this.title,
    required this.proposedPrice,
    required this.specialization,
    required this.description,
    this.period,
    this.taskBeginDate,
    this.workType,
    this.remarks,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'urgent': urgency == 'Urgent',
      'task_id': taskId,
      'duration': int.tryParse(duration) ?? 0,
      'location': location,
      'task_title': title,
      'proposed_price': proposedPrice,
      'specialization': specialization,
      'task_description': description,
      'period': period,
      'task_begin_date': taskBeginDate,
      'work_type': workType,
      'remarks': remarks,
    };
  }

  factory TaskDetails.fromJson(Map<String, dynamic> json) {
    String urgencyValue;
    final urgentField = json['urgent'];
    if (urgentField is bool) {
      urgencyValue = urgentField ? 'Urgent' : 'Non-Urgent';
    } else if (urgentField is String) {
      urgencyValue = urgentField;
    } else {
      urgencyValue = 'Unknown';
    }

    return TaskDetails(
      status: json['status'] as String,
      urgency: urgencyValue,
      taskId: json['task_id'] as int,
      duration: json['duration'].toString(),
      location: json['location'] as String,
      title: json['task_title'] as String,
      proposedPrice: json['proposed_price'] as int,
      specialization: json['specialization'] as String,
      description: json['task_description'] as String,
      period: json['period'] as String?,
      taskBeginDate: json['task_begin_date'] as String?,
      workType: json['work_type'] as String?,
      remarks: json['remarks'] as String?,
    );
  }

  @override
  String toString() {
    return 'TaskDetails(status: $status, urgency: $urgency, taskId: $taskId, duration: $duration, location: $location, title: $title, proposedPrice: $proposedPrice, specialization: $specialization, description: $description, period: $period, taskBeginDate: $taskBeginDate, workType: $workType, remarks: $remarks)';
  }
}
