class TaskModel {
  final int? id;
  final int? clientId;
  final String? title;
  final String? specialization;
  final String? description;
  final String? location;
  final String? period;  // <- period remains a String
  final String? duration; // <- Change duration from int? to String?
  final String? urgency;
  final String? status;
  final int? contactPrice;
  final String? remarks;
  final String? taskBeginDate;

  TaskModel({
    this.id,
    this.clientId,
    this.title,
    this.specialization,
    this.description,
    this.location,
    this.period,
    this.duration,  // <- Updated from int? to String?
    this.urgency,
    this.status,
    this.contactPrice,
    this.remarks,
    this.taskBeginDate,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      "job_post_id": id,
      "client_id": clientId,
      "task_title": title,
      "specialization": specialization,
      "task_description": description,
      "location": location,
      "duration": duration, // <- Keep as String
      "num_of_days": period,
      "urgency": urgency,
      "contact_price": contactPrice,
      "remarks": remarks,
      "task_begin_date": taskBeginDate,
      "id": id,
      "status": status,
    };
  }

  // Convert from JSON
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['job_post_id'] as int?,
      clientId: json['client_id'] as int?,
      title: json['task_title'] as String?,
      specialization: json['specialization'] as String?,
      description: json['task_description'] as String?,
      location: json['location'] as String?,
      duration: json['duration']?.toString(), // <- Ensure it remains a String
      period: json['period']?.toString(),
      urgency: json['urgent'] as String?,  // <- Fix key from "urgency" to "urgent"
      contactPrice: json['contact_price'] as int?,
      remarks: json['remarks'] as String?,
      taskBeginDate: json['task_begin_date'] as String?,
      status: json['status'] as String?,
    );
  }
}
