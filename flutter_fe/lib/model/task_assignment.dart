class TaskAssginment{
  final int clientId;
  final int taskerId;
  final int taskId;
  String? taskStatus;
  String? rejectionReason;

  TaskAssginment({
    required this.clientId,
    required this.taskerId,
    required this.taskId,
    this.taskStatus,
    this.rejectionReason
  });

  Map<String, dynamic> toJson() {
    return {
      "task_id": taskId,
      "tasker_id": taskerId,
      "client_id": clientId,
      "task_status": taskStatus,
      "reason_for_rejection": rejectionReason
    };
  }

  factory TaskAssginment.fromJson(Map<String, dynamic> json) {
    return TaskAssginment(
      taskId: json['task_id'] as int,
      clientId: json['client_id'] as int,
      taskerId: json['tasker_id'] as int,
      taskStatus: json['task_status'] as String,
      rejectionReason: json['reason_for_rejection'] as String
    );
  }
}