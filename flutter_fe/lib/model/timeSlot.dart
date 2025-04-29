import 'package:flutter/material.dart';

class TimeSlot {
  final int id;
  final int tasker_id;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAvailable;

  TimeSlot({
    required this.id,
    required this.tasker_id,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });

  TimeSlot copyWith({
    int? id,
    int? tasker_id,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isAvailable,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      tasker_id: tasker_id ?? this.tasker_id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "time_slot_id": id,
      "tasker_id": tasker_id,
      "start_time": startTime,
      "end_time": endTime,
      "is_available": isAvailable,
    };
  }

  @override
  String toString() {
    return 'TimeSlot(id: $id, tasker_id: $tasker_id, start: ${_formatTime(startTime)}, end: ${_formatTime(endTime)}, available: $isAvailable)';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
