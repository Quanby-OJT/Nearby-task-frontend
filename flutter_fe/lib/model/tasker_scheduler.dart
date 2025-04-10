class TaskerScheduler{
  final String dateScheduled;
  final String startTime;
  final String endTime;
  final bool isAvailable;

  TaskerScheduler({
    required this.dateScheduled,
    required this.startTime,
    required this.endTime,
    required this.isAvailable
  });

  Map<String, dynamic> toJson(){
    return {
      "scheduled_date": dateScheduled,
      "start_time": startTime,
      "end_time": endTime,
    };
  }

  factory TaskerScheduler.fromJson(Map<String, dynamic> json){
    return TaskerScheduler(
      dateScheduled: json['scheduled_date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isAvailable: json['is_available'] as bool,
    );
  }
}