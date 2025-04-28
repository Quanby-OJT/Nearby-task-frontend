class TaskerScheduler {
  final int id;
  final int tasker_id;
  final String dateScheduled;
  final String startTime;
  final String endTime;
  final bool isAvailable;

  TaskerScheduler({
    required this.id,
    required this.tasker_id,
    required this.dateScheduled,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  Map<String, dynamic> toJson() {
    return {
      "schedule_id": id,
      "tasker_id": tasker_id,
      "scheduled_date": dateScheduled,
      "start_time": startTime,
      "end_time": endTime,
      "is_available": isAvailable,
    };
  }

  factory TaskerScheduler.fromJson(Map<String, dynamic> json) {
    return TaskerScheduler(
      id: json['schedule_id'] as int,
      tasker_id: json['tasker_id'] as int,
      dateScheduled: json['scheduled_date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isAvailable: json['is_available'] as bool,
    );
  }
}
