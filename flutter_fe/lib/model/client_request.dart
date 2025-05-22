class ClientRequestModel {
  final int? task_taken_id;
  final int? tasker_id;
  final int? client_id;
  final int? task_id;
  final String? task_status;
  final DateTime? created_at;
  final String? reason_for_rejection_or_cancellation;
  final String? remark;
  final String? requested_from;
  final int? time_request;
  final DateTime? start_date;

  ClientRequestModel({
    this.task_taken_id,
    this.tasker_id,
    this.client_id,
    this.task_id,
    this.task_status,
    this.created_at,
    this.reason_for_rejection_or_cancellation,
    this.remark,
    this.requested_from,
    this.time_request,
    this.start_date,
  });

  Map<String, dynamic> toJson() {
    return {
      "task_taken_id": task_taken_id,
      "tasker_id": tasker_id,
      "client_id": client_id,
      "task_id": task_id,
      "task_status": task_status,
      "created_at": created_at,
      "reason_for_rejection_or_cancellation":
          reason_for_rejection_or_cancellation,
      "remark": remark,
      "requested_from": requested_from,
      "time_request": time_request,
      "start_date": start_date,
    };
  }

  @override
  String toString() {
    return "ClientRequestModel(task_taken_id: $task_taken_id, tasker_id: $tasker_id, client_id: $client_id, task_id: $task_id, task_status: $task_status)";
  }

  factory ClientRequestModel.fromJson(Map<String, dynamic> json) {
    return ClientRequestModel(
      task_taken_id: json['task_taken_id'] as int?,
      tasker_id: json['tasker_id'] as int?,
      client_id: json['client_id'] as int?,
      task_id: json['task_id'] as int?,
      task_status: json['task_status'] as String?,
      created_at: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String? ?? '')
          : null,
      reason_for_rejection_or_cancellation:
          json['reason_for_rejection_or_cancellation'] as String?,
      remark: json['remark'] as String?,
      requested_from: json['requested_from'] as String?,
      time_request: json['time_request'] as int?,
      start_date: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String? ?? '')
          : null,
    );
  }
}
