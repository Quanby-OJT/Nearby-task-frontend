import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/model/address.dart';

class TaskModel {
  final int id;
  final int? clientId;
  final String title;
  final String specialization;
  final int? specializationId;
  final String description;
  final String location;
  final String period;
  final String duration;
  final String urgency;
  final String status;
  final int contactPrice;
  final String? remarks;
  final String taskBeginDate;
  final String workType;
  final ClientModel? client;
  final AddressModel? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TaskModel({
    required this.id,
    this.clientId,
    required this.title,
    required this.specialization,
    this.specializationId,
    required this.description,
    required this.location,
    required this.period,
    required this.duration,
    required this.urgency,
    required this.status,
    required this.contactPrice,
    this.remarks,
    required this.taskBeginDate,
    required this.workType,
    this.client,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      "task_id": id,
      "client_id": clientId,
      "task_title": title,
      "specialization": specialization,
      "specialization_id": specializationId,
      "task_description": description,
      "location": location,
      "duration": duration != null ? int.tryParse(duration) ?? 0 : 0,
      "period": period,
      "urgent": urgency == "Urgent",
      "proposed_price": contactPrice,
      "remarks": remarks,
      "task_begin_date": taskBeginDate,
      "status": status,
      "work_type": workType,
      "client": client?.toJson(),
      "address": address?.toJson(),
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    String? urgencyValue;
    final urgentField = json['urgent'];
    if (urgentField is bool) {
      urgencyValue = urgentField ? "Urgent" : "Non-Urgent";
    } else if (urgentField is String) {
      urgencyValue = urgentField;
    } else {
      urgencyValue = "Unknown";
    }

    return TaskModel(
      id: json['task_id'] as int,
      clientId: json['client_id'] as int?,
      title: json['task_title'] != null ? json['task_title'] as String : '',
      specialization: json['specialization'] != null ? json['specialization'] as String : '',
      specializationId: json['specialization_id'] as int?,
      description: json['task_description'] != null ? json['task_description'] as String : '',
      location: json['location'] != null ? json['location'] as String : '',
      duration: json['duration'] != null ? json['duration'].toString() : '',
      period: json['period'] != null ? json['period'] as String : '',
      urgency: urgencyValue,
      contactPrice: json['proposed_price'] != null ? json['proposed_price'] as int : 0,
      remarks: json['remarks'] as String?,
      taskBeginDate: json['task_begin_date'] != null ? json['task_begin_date'] as String : '',
      status: json['status'] != null ? json['status'] as String : '',
      workType: json['work_type'] != null ? json['work_type'] as String : '',
      client: json['clients'] != null && json['clients']['user'] != null
          ? ClientModel.fromJson({
              'preferences': '',
              'client_address': '',
              'user': json['clients']['user'],
            })
          : null,
      address: json['address'] != null
          ? AddressModel.fromJson(json['address'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, specialization: $specialization, specializationId: $specializationId, description: $description, location: $location, period: $period, duration: $duration, urgency: $urgency, status: $status, contactPrice: $contactPrice, remarks: $remarks, taskBeginDate: $taskBeginDate, workType: $workType, client: $client, address: $address, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
