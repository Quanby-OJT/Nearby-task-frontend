import 'package:flutter/material.dart';
import 'package:flutter_fe/model/tasker_scheduler.dart';
import 'package:flutter_fe/service/tasker_service.dart';

import '../view/service_acc/schedule_management_page.dart';


class TaskerSchedulerController {
  Future<String> setTaskerSchedule(Map<DateTime, List<TimeSlot>> scheduleData) async {
    try {
      // Convert the schedule data into a list of TaskerScheduler objects
      List<TaskerScheduler> schedules = [];
      scheduleData.forEach((date, slots) {
        for (var slot in slots) {
          schedules.add(TaskerScheduler(
            dateScheduled: date.toIso8601String(),
            startTime: slot.startTime.toString(),
            endTime: slot.endTime.toString(),
            isAvailable: slot.isAvailable,
          ));
        }
      });

      // Send each schedule entry to the API
      String lastMessage = "";
      for (var schedule in schedules) {
        var response = await TaskerService.setTaskerSchedule(schedule);
        if (response.containsKey('message')) {
          lastMessage = response['message'];
        } else {
          return "An error occurred while setting tasker schedule.";
        }
      }

      return lastMessage.isNotEmpty
          ? lastMessage
          : "Schedule successfully set";
    } catch (e, stackTrace) {
      debugPrint("Error setting tasker schedule: $e");
      debugPrintStack(stackTrace: stackTrace);
      return "An error occurred while setting tasker schedule.";
    }
  }

  Future<Map<DateTime, List<TimeSlot>>> getTaskerSchedule() async {
    try{
      List<TaskerScheduler> schedules = await TaskerService.getTaskerSchedule();
      Map<DateTime, List<TimeSlot>> scheduleData = {};
      for (var schedule in schedules) {
        DateTime date = DateTime.parse(schedule.dateScheduled);
        if (!scheduleData.containsKey(date)) {
          scheduleData[date] = [];
        }
        scheduleData[date]!.add(TimeSlot(
          startTime: TimeOfDay(hour: int.parse(schedule.startTime.split(":")[0]), minute: int.parse(schedule.startTime.split(":")[1])),
          endTime: TimeOfDay(hour: int.parse(schedule.endTime.split(":")[0]), minute: int.parse(schedule.endTime.split(":")[1])),
          isAvailable: schedule.isAvailable,
        ));
      }
      return scheduleData;
    } catch (e, stackTrace) {
      debugPrint("Error getting tasker schedule: $e");
      debugPrintStack(stackTrace: stackTrace);

      return {};
    }
  }
}