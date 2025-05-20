import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/model/address.dart';

class TaskModel {
  final int id;
  final int? clientId;
  final String title;
  final String description;
  final String specialization;
  final List<int>? relatedSpecializationsIds;
  final int? specializationId;
  final String workType;
  final String scope;
  final bool? isVerifiedDocument;
  final int contactPrice;
  final String urgency;
  final String? remarks;
  final String status;
  final String? addressID;
  final ClientModel? client;
  final AddressModel? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? taskBeginDate;
  final String? period;
  final String? duration;

  TaskModel({
    required this.id,
    this.clientId,
    required this.title,
    required this.specialization,
    this.specializationId,
    this.relatedSpecializationsIds,
    this.addressID,
    required this.description,
    this.period,
    this.duration,
    required this.urgency,
    required this.status,
    required this.contactPrice,
    this.remarks,
    this.taskBeginDate,
    required this.workType,
    required this.scope,
    this.isVerifiedDocument,
    this.client,
    this.createdAt,
    this.updatedAt,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      "task_id": id,
      "client_id": clientId,
      "task_title": title,
      "specialization": specialization,
      "specialization_id": specializationId,
      "related_specializations": relatedSpecializationsIds,
      "task_description": description,
      "duration": duration != null ? int.tryParse(duration!) ?? 0 : null,
      "period": period,
      "urgent": urgency == "Urgent",
      "proposed_price": contactPrice,
      "remarks": remarks,
      "task_begin_date": taskBeginDate,
      "status": status,
      "work_type": workType,
      "address_id": addressID,
      "scope": scope,
      "is_verified_document": isVerifiedDocument,
      "client": client?.toJson(),
      "address": address?.toJson(),
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
    };
  }

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
          ? (json['related_specializations'] as List<dynamic>)
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .toList()
          : null,
      description: json['task_description']?.toString() ?? '',
      duration: json['duration']?.toString(),
      period: json['period']?.toString() ?? '',
      urgency: urgencyValue,
      contactPrice: json['proposed_price'] as int? ?? 0,
      remarks: json['remarks']?.toString(),
      taskBeginDate: json['task_begin_date']?.toString(),
      status: json['status']?.toString() ?? '',
      workType: json['work_type']?.toString() ?? '',
      addressID: json['address_id']?.toString(),
      scope: json['scope']?.toString() ?? '',
      isVerifiedDocument: json['is_verified_document'] as bool?,
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
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, clientId: $clientId, title: $title, description: $description, specialization: $specialization, relatedSpecializationsIds: $relatedSpecializationsIds, specializationId: $specializationId, workType: $workType, scope: $scope, isVerifiedDocument: $isVerifiedDocument, contactPrice: $contactPrice, urgency: $urgency, remarks: $remarks, status: $status, client: $client, address: $address, createdAt: $createdAt, updatedAt: $updatedAt, taskBeginDate: $taskBeginDate, period: $period, duration: $duration, addressID: $addressID)';
  }
}
