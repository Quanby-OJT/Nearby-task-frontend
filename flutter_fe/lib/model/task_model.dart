class TaskModel {
  final int? id;
  final int? clientId;
  final String? title;
  final String? specialization;
  final String? description;
  final String? location;
  final String? period;
  final int? duration;
  final bool? urgency;
  final String? status;
  final double? contactPrice;
  final String? remarks;
  final String? taskBeginDate;
  final String? taskerRole;

  TaskModel(
      {this.id,
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
      this.taskerRole});

  // Convert to JSON
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
      "urgency": urgency,
      "contact_price": contactPrice,
      "remarks": remarks,
      "task_begin_date": taskBeginDate,
      "id": id,
      "status": status,
      "tasker_role": taskerRole,
    };
  }

  // Convert from JSON
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['task_id'] as int?,
      clientId: json['client_id'] as int?,
      title: json['task_title'] as String?,
      specialization: json['specialization'] as String?,
      description: json['task_description'] as String?,
      location: json['location'] as String?,
      duration: json['duration'] as int?,
      period: json['period'] as String?,
      urgency: json['urgent'] as bool,
      contactPrice: (json['contact_price'] as num).toDouble(),
      remarks: json['remarks'] as String?,
      taskBeginDate: json['task_begin_date'] as String?,
      status: json['status'] as String?,
      taskerRole: json['tasker_role'] as String?,
    );
  }
}
