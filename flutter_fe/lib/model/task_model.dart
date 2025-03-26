class TaskModel {
  final int id;
  final int? clientId;
  final String? title;
  final String? specialization;
  final String? description;
  final String? location;
  final String? period;
  final String? duration;
  final String? urgency;
  final String? status;
  final int? contactPrice;
  final String? remarks;
  final String? taskBeginDate;
  final String? workType; // New field

  TaskModel({
    required this.id,
    this.clientId,
    this.title,
    this.specialization,
    this.description,
    this.location,
    this.period,
    this.duration,
    this.urgency,
    this.status,
    this.contactPrice,
    this.remarks,
    this.taskBeginDate,
    this.workType,
  });

  Map<String, dynamic> toJson() {
    return {
      "task_id": id,
      "client_id": clientId,
      "task_title": title,
      "specialization": specialization,
      "task_description": description,
      "location": location,
      "duration": duration != null ? int.tryParse(duration!) ?? 0 : 0,
      "num_of_days": period,
      "urgent": urgency == "Urgent", // Convert string to boolean
      "proposed_price": contactPrice != null ? contactPrice : 0,
      "remarks": remarks,
      "task_begin_date": taskBeginDate,
      "id": id,
      "status": status,
      "work_type": workType,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    // Handle the urgent field which can be either boolean or string
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
      title: json['task_title'] as String?,
      specialization: json['specialization'] as String?,
      description: json['task_description'] as String?,
      location: json['location'] as String?,
      duration: json['duration']?.toString(),
      period: json['period']?.toString(),
      urgency: urgencyValue,
      contactPrice: json['proposed_price'] as int?,
      remarks: json['remarks'] as String?,
      taskBeginDate: json['task_begin_date'] as String?,
      status: json['status'] as String?,
      workType: json['work_type'] as String?,
    );
  }
}
