import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/model/address.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task_model.g.dart';

@JsonSerializable()
class TaskModel {
  final int id;
  final int? clientId;
  final String title;
  final String description;
  final String? specialization;
  final List<String>? relatedSpecializationsIds;
  final int? specializationId;
  final String? addressID;
  final String workType;
  final String scope;
  final bool? isVerifiedDocument;
  final int contactPrice;
  final String? urgency;
  final String? remarks;
  final String status;
  final ClientModel? client;
  final TaskerModel? tasker;
  final AddressModel? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? imageUrl;
  final TaskerSpecialization? taskerSpecialization;
  final List<TaskFetch>? taskTaken;

  TaskModel({
    required this.id,
    this.clientId,
    required this.title,
    required this.specialization,
    this.specializationId,
    this.relatedSpecializationsIds,
    this.addressID,
    required this.description,
    required this.urgency,
    required this.status,
    required this.contactPrice,
    this.remarks,
    required this.workType,
    required this.scope,
    this.isVerifiedDocument,
    this.client,
    this.tasker,
    this.createdAt,
    this.updatedAt,
    this.address,
    this.imageUrl,
    this.taskerSpecialization,
    this.taskTaken,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    String urgencyValue;
    final urgentField = json['urgent'];
    if (urgentField is bool) {
      urgencyValue = urgentField ? "Urgent" : "Non-Urgent";
    } else if (urgentField is String) {
      urgencyValue = urgentField;
    } else {
      urgencyValue = "Non-Urgent";
    }

    return TaskModel(
      id: json['task_id'] as int? ?? 0,
      clientId: json['client_id'] as int?,
      title: json['task_title']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      specializationId: json['specialization_id'] as int?,
      relatedSpecializationsIds: json['related_specializations'] != null
          ? (json['related_specializations'] as List)
              .map((e) => e.toString())
              .toList()
          : null,
      description: json['task_description']?.toString() ?? '',
      urgency: urgencyValue,
      contactPrice: json['proposed_price'] as int? ?? 0,
      remarks: json['remarks']?.toString(),
      status: json['status']?.toString() ?? 'Available',
      workType: json['work_type']?.toString() ?? '',
      addressID: json['address_id']?.toString(),
      scope: json['scope']?.toString() ?? '',
      isVerifiedDocument: json['is_verified'] as bool?,
      client: json['client'] != null && json['client']['user'] != null
          ? ClientModel.fromJson({
              'preferences': '',
              'client_address': '',
              'user': json['client']['user'],
            })
          : null,
      tasker: json['tasker'] != null && json['tasker']['user'] != null
          ? TaskerModel.fromJson({
              'preferences': '',
              'client_address': '',
              'user': json['tasker']['user'],
            })
          : null,
      address: json['address'] != null
          ? AddressModel.fromJson(json['address'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      imageUrl: json['image_url']?.toString(),
      taskerSpecialization: json['tasker_specialization'] != null
          ? TaskerSpecialization.fromJson(json['tasker_specialization'])
          : null,
      taskTaken: json['taskTaken'] != null
          ? (json['taskTaken'] as List)
              .map((task) => TaskFetch.fromJson(task as Map<String, dynamic>))
              .where((taskFetch) =>
                  taskFetch.id == json['task_id']) // Filter by task_id
              .toList()
          : null,
    );
  }

  // Get the effective status for display
  String getEffectiveStatus() {
    if (taskTaken != null && taskTaken!.isNotEmpty) {
      // Return the latest taskTaken status based on created_at
      final latestTaskTaken = taskTaken!
          .reduce((a, b) => a.createdAt!.isAfter(b.createdAt!) ? a : b);
      return latestTaskTaken.taskStatus;
    }
    return status; // Fallback to post_task status
  }

  Map<String, dynamic> toJson() {
    return {
      "task_id": id,
      "client_id": clientId,
      "task_title": title,
      "specialization": specialization,
      "specialization_id": specializationId,
      "related_specializations": relatedSpecializationsIds,
      "task_description": description,
      "urgent": urgency == "Urgent",
      "proposed_price": contactPrice,
      "remarks": remarks,
      "status": status,
      "work_type": workType,
      "address_id": addressID,
      "scope": scope,
      "is_verified_document": isVerifiedDocument,
      "client": client?.toJson(),
      "tasker": tasker?.toJson(),
      "address": address?.toJson(),
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
      "image_url": imageUrl,
      "tasker_specialization": taskerSpecialization?.toJson(),
      "taskTaken": taskTaken?.map((task) => task.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, clientId: $clientId, title: $title, description: $description, specialization: $specialization, relatedSpecializationsIds: $relatedSpecializationsIds, specializationId: $specializationId, workType: $workType, scope: $scope, isVerifiedDocument: $isVerifiedDocument, contactPrice: $contactPrice, urgency: $urgency, remarks: $remarks, status: $status, client: $client, tasker: $tasker, address: $address, createdAt: $createdAt, updatedAt: $updatedAt, addressID: $addressID, imageUrl: $imageUrl, taskerSpecialization: $taskerSpecialization, taskTaken: $taskTaken)';
  }
}

@JsonSerializable()
class TaskerSpecialization {
  final String specialization;

  TaskerSpecialization({required this.specialization});

  factory TaskerSpecialization.fromJson(Map<String, dynamic> json) =>
      _$TaskerSpecializationFromJson(json);

  Map<String, dynamic> toJson() => _$TaskerSpecializationToJson(this);

  @override
  String toString() => 'TaskerSpecialization(specialization: $specialization)';
}
