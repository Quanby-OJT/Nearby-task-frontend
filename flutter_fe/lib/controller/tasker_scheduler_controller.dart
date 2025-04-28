import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_fe/model/tasker_scheduler.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:flutter_fe/service/tasker_service.dart';
import 'package:flutter_fe/view/service_acc/schedule_management_page.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

import '../config/url_strategy.dart';

class TaskerSchedulerController {
  static final String url = apiUrl ?? "http://localhost:5000/connect";
  static final storage = GetStorage();

  Future<String> setTaskerSchedule(List<Map<String, dynamic>> schedule) async {
    try {
      final taskerId = await storage.read("user_id");
      if (taskerId == null) {
        return "Error: Tasker ID not found";
      }

      final response = await http.post(
        Uri.parse('$url/set-tasker-schedule'),
        headers: {
          "Authorization": "Bearer ${await AuthService.getSessionToken()}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"tasker_id": taskerId, "schedule": schedule}),
      );

      if (response.statusCode == 200) {
        return "Schedule set successfully";
      } else {
        final error =
            jsonDecode(response.body)['error'] ?? "Failed to set schedule";
        return "Error: $error";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<Map<DateTime, List<TimeSlot>>> getTaskerSchedule() async {
    try {
      final taskerId = await storage.read("user_id");
      if (taskerId == null) {
        debugPrint("Tasker ID not found");
        return {};
      }

      final response = await http.get(
        Uri.parse('$url/get-tasker-schedule/$taskerId'),
        headers: {
          "Authorization": "Bearer ${await AuthService.getSessionToken()}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("Response data: $data");
        if (data.containsKey("data")) {
          final List<dynamic> scheduleData = data["data"];
          final Map<DateTime, List<TimeSlot>> schedule = {};

          for (var item in scheduleData) {
            final taskerScheduler = TaskerScheduler.fromJson(item);
            final date = DateTime.parse(taskerScheduler.dateScheduled);
            final timeSlot = TimeSlot(
              startTime: _parseTime(taskerScheduler.startTime),
              endTime: _parseTime(taskerScheduler.endTime),
              isAvailable: taskerScheduler.isAvailable,
            );

            final dateKey = DateTime(date.year, date.month, date.day);
            schedule[dateKey] = schedule[dateKey] ?? [];
            schedule[dateKey]!.add(timeSlot);
          }

          debugPrint("Loaded schedules: $schedule");
          return schedule;
        }
        debugPrint("No schedules found in response: $data");
        return {};
      } else {
        debugPrint("Error fetching schedule: ${response.body}");
        return {};
      }
    } catch (e) {
      debugPrint("Error getting tasker schedule: $e");
      return {};
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}
