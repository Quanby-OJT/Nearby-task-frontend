class TaskModel {
  final int? id;
  final String? title;
  final String? specialization;
  final String? description;
  final String? location;
  final String? period;
  final int? duration;
  final String? urgency;
  final String? status;
  final int? contactPrice;
  final String? remarks;
  final String? taskBeginDate;

   TaskModel({
    this.id,
    this.title,
    this.specialization,
    this.description,
    this.location,
    this.duration,
    this.period,
    this.urgency,
    this.status,
    this.contactPrice,
    this.remarks,
    this.taskBeginDate,
  });

  Map<String, dynamic> toJson() {
    return {
      "task_id": id,
      "task_title": title,
      "specialization": specialization,
      "task_description": description,
      "location": location,
      "duration": period,
      "num_of_days": duration,
      "urgency": urgency,
      "contact_price": contactPrice,
      "remarks": remarks,
      "task_begin_date": taskBeginDate,
      "id": id,
      "status": status,
    };
  }

  // Convert from JSON (kung may fetch feature later)
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['task_id'] as int?,
      title: json['task_title'] as String?,
      specialization: json['specialization'] as String?,
      description: json['task_description'] as String?,
      location: json['location'] as String?,
      duration: json['duration'] as int?,
      period: json['period'] as String?,
      urgency: json['urgency'] as String?,
      contactPrice: json['contact_price'] as int?,
      remarks: json['remarks'] as String?,
      taskBeginDate: json['task_begin_date'] as String?,
      status: json['status'] as String?,
    );
  }
}
