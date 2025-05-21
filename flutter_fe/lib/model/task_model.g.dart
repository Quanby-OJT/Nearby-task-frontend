part of 'task_model.dart';

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => TaskModel(
      id: (json['id'] as num).toInt(),
      clientId: (json['clientId'] as num?)?.toInt(),
      title: json['title'] as String,
      specialization: json['specialization'] as String?,
      specializationId: (json['specializationId'] as num?)?.toInt(),
      relatedSpecializationsIds:
          (json['relatedSpecializationsIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      addressID: json['addressID'] as String?,
      description: json['description'] as String,
      urgency: json['urgency'] as String?,
      status: json['status'] as String,
      contactPrice: (json['contactPrice'] as num).toInt(),
      remarks: json['remarks'] as String?,
      workType: json['workType'] as String,
      scope: json['scope'] as String,
      isVerifiedDocument: json['isVerifiedDocument'] as bool?,
      client: json['client'] == null
          ? null
          : ClientModel.fromJson(json['client'] as Map<String, dynamic>),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      address: json['address'] == null
          ? null
          : AddressModel.fromJson(json['address'] as Map<String, dynamic>),
      imageUrl: json['imageUrl'] as String?,
      taskerSpecialization: json['taskerSpecialization'] == null
          ? null
          : TaskerSpecialization.fromJson(
              json['taskerSpecialization'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TaskModelToJson(TaskModel instance) => <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'title': instance.title,
      'description': instance.description,
      'specialization': instance.specialization,
      'relatedSpecializationsIds': instance.relatedSpecializationsIds,
      'specializationId': instance.specializationId,
      'addressID': instance.addressID,
      'workType': instance.workType,
      'scope': instance.scope,
      'isVerifiedDocument': instance.isVerifiedDocument,
      'contactPrice': instance.contactPrice,
      'urgency': instance.urgency,
      'remarks': instance.remarks,
      'status': instance.status,
      'client': instance.client,
      'address': instance.address,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'imageUrl': instance.imageUrl,
      'taskerSpecialization': instance.taskerSpecialization,
    };

TaskerSpecialization _$TaskerSpecializationFromJson(
        Map<String, dynamic> json) =>
    TaskerSpecialization(
      specialization: json['specialization'] as String,
    );

Map<String, dynamic> _$TaskerSpecializationToJson(
        TaskerSpecialization instance) =>
    <String, dynamic>{
      'specialization': instance.specialization,
    };
