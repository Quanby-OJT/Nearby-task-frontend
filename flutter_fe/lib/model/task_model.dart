class TaskModel {
  final int? id;
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
    this.id,
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
      "duration": duration,
      "num_of_days": period,
       // Convert boolean urgency to string
      "urgent": urgency == "This task is urgent"
        ? true
        : false,
      "urgency": urgency,
      "proposed_price": contactPrice,
      "remarks": remarks,
      "task_begin_date": taskBeginDate,
      "id": id,
      "status": status,
      "work_type": workType, // New field in JSON
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['task_id'] as int?,
      clientId: json['client_id'] as int?,
      title: json['task_title'] as String?,
      specialization: json['specialization'] as String?,
      description: json['task_description'] as String?,
      location: json['location'] as String?,
      duration: json['duration']?.toString(),
      period: json['period']?.toString(),
       // Convert boolean to string for urgency
      urgency: json['urgent'] as bool
        ? "This task is urgent"
        : "This task is not urgent.",
      //urgency: json['urgent'] as String,  // <- Fix key from "urgency" to "urgent"
      contactPrice: json['proposed_price'] as int?,
      remarks: json['remarks'] as String?,
      taskBeginDate: json['task_begin_date'] as String?,
      status: json['status'] as String?,
      workType: json['work_type'] as String?, // New field from JSON
    );
  }
}
